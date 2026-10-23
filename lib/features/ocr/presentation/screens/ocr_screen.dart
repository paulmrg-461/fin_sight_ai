import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/services/receipt_image_picker.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/receipt_entity.dart';
import '../bloc/ocr_bloc.dart';
import '../bloc/ocr_event.dart';
import '../bloc/ocr_state.dart';
import 'receipt_preview_screen.dart';

/// Receipt scanning entry point with camera/gallery actions.
class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key, required this.imagePicker});

  final ReceiptImagePicker imagePicker;

  Future<void> _pickAndScan(
    BuildContext context,
    ReceiptImageSource source,
  ) async {
    final bloc = context.read<OcrBloc>();
    final path = await imagePicker.pick(source);
    if (path != null && path.trim().isNotEmpty) {
      bloc.add(ScanReceipt(path));
    }
  }

  Future<void> _openPreview(
    BuildContext context,
    ReceiptEntity receipt, {
    required bool createTransaction,
  }) async {
    final bloc = context.read<OcrBloc>();
    final navigator = Navigator.of(context);

    await navigator.push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ReceiptPreviewScreen(
            receipt: receipt,
            createTransaction: createTransaction,
          ),
        ),
      ),
    );

    bloc.add(const LoadReceipts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan receipts')),
      body: BlocConsumer<OcrBloc, OcrState>(
        listener: (context, state) {
          if (state is OcrScanSuccess) {
            _openPreview(context, state.receipt, createTransaction: true);
          }
        },
        builder: (context, state) {
          final isBusy = state is OcrScanning || state is OcrSaving;

          return Column(
            children: [
              Expanded(child: _buildContent(context, state)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isBusy
                              ? null
                              : () => _pickAndScan(
                                  context,
                                  ReceiptImageSource.camera,
                                ),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isBusy
                              ? null
                              : () => _pickAndScan(
                                  context,
                                  ReceiptImageSource.gallery,
                                ),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, OcrState state) {
    return switch (state) {
      OcrInitial() || OcrEmpty() => _EmptyState(
        onScan: () => _pickAndScan(context, ReceiptImageSource.gallery),
      ),
      OcrLoading() => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading receipts'),
      ),
      OcrScanning() => const _BusyState(message: 'Extracting receipt data…'),
      OcrSaving() => const _BusyState(message: 'Saving receipt…'),
      OcrScanSuccess() ||
      OcrSaved() => const _BusyState(message: 'Finishing up…'),
      OcrFailure(:final message) => _ErrorState(
        message: message,
        onRetry: () => context.read<OcrBloc>().add(const LoadReceipts()),
      ),
      OcrReceiptsLoaded(:final receipts) => ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: receipts.length,
        itemBuilder: (context, index) {
          final receipt = receipts[index];
          return _ReceiptTile(
            receipt: receipt,
            onTap: () =>
                _openPreview(context, receipt, createTransaction: false),
          );
        },
      ),
    };
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt, required this.onTap});

  final ReceiptEntity receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.receipt_long_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          receipt.merchantName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${formatDisplayDate(receipt.date)} • '
          '${receipt.items.length} items',
        ),
        trailing: Text(
          '${receipt.currency} ${receipt.totalAmount.toStringAsFixed(2)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('No receipts yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Scan a receipt to extract the merchant, total, and line items.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan a receipt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusyState extends StatelessWidget {
  const _BusyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
