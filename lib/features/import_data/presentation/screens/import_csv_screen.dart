import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../bloc/import_csv_cubit.dart';
import '../bloc/import_csv_state.dart';

class ImportCsvScreen extends StatefulWidget {
  const ImportCsvScreen({super.key});

  @override
  State<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends State<ImportCsvScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final csv = _controller.text.trim();
    if (csv.isEmpty) {
      return;
    }
    await context.read<ImportCsvCubit>().import(csv);
    if (!mounted) {
      return;
    }
    if (context.read<ImportCsvCubit>().state is ImportCsvSuccess) {
      context.read<TransactionBloc>().add(const LoadTransactions());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importCsvTitle)),
      body: BlocBuilder<ImportCsvCubit, ImportCsvState>(
        builder: (context, state) {
          final running = state is ImportCsvRunning;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.importCsvDescription, style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    l10n.importCsvFormat,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 8,
                maxLines: 16,
                enabled: !running,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: l10n.importCsvField,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: running ? null : _import,
                icon: running
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: Text(l10n.importCsvAction),
              ),
              const SizedBox(height: 16),
              switch (state) {
                ImportCsvSuccess(:final summary) => _ResultCard(
                  imported: summary.imported,
                  skipped: summary.skipped,
                  failed: summary.failed,
                  errors: summary.errors.length,
                ),
                ImportCsvFailure(:final message) => Text(
                  context.failureText(message),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                _ => const SizedBox.shrink(),
              },
            ],
          );
        },
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.imported,
    required this.skipped,
    required this.failed,
    required this.errors,
  });

  final int imported;
  final int skipped;
  final int failed;
  final int errors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          '${l10n.importCsvImported(imported)} · '
          '${l10n.importCsvSkipped(skipped)} · '
          '${l10n.importCsvFailed(failed + errors)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
