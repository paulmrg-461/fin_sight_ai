import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/receipt_image_picker.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_states.dart';
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
      appBar: AppBar(title: Text(context.l10n.scanReceipts)),
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
                          label: Text(context.l10n.camera),
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
                          label: Text(context.l10n.gallery),
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
      OcrLoading() => Center(
        child: CircularProgressIndicator(
          semanticsLabel: context.l10n.loadingReceipts,
        ),
      ),
      OcrScanning() => _BusyState(message: context.l10n.extractingData),
      OcrSaving() => _BusyState(message: context.l10n.savingReceipt),
      OcrScanSuccess() ||
      OcrSaved() ||
      OcrTransactionFailure() => _BusyState(message: context.l10n.finishingUp),
      OcrFailure(:final message) => AppErrorState(
        message: context.failureText(message),
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
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
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
          '${context.l10n.itemsCount(receipt.items.length)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyText(
              receipt.totalAmount,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AppEmptyState(
          icon: Icons.document_scanner_outlined,
          title: context.l10n.noReceiptsYet,
          message: context.l10n.noReceiptsBody,
          actionLabel: context.l10n.scanAReceipt,
          actionIcon: Icons.document_scanner_outlined,
          onAction: onScan,
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
    final theme = Theme.of(context);
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  semanticsLabel: message,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.failureText(message),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
