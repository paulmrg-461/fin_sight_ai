import 'package:fin_sight_ai/app/startup_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Bootstrap extends StatefulWidget {
  const _Bootstrap({required this.tasks});

  final List<Future<void> Function()> tasks;

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  @override
  void initState() {
    super.initState();
    const StartupLoader().afterFirstFrame(widget.tasks);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('defers tasks until after the first frame', (tester) async {
    var runs = 0;
    final order = <int>[];

    await tester.pumpWidget(
      _Bootstrap(
        tasks: [
          () async {
            runs++;
            order.add(1);
          },
          () async {
            runs++;
            order.add(2);
          },
        ],
      ),
    );
    await tester.pump();

    expect(runs, 2);
    expect(order, [1, 2]);
  });

  testWidgets('awaits each task before starting the next', (tester) async {
    final events = <String>[];

    await tester.pumpWidget(
      _Bootstrap(
        tasks: [
          () async {
            events.add('first-start');
            await Future<void>.delayed(const Duration(milliseconds: 10));
            events.add('first-end');
          },
          () async {
            events.add('second-start');
          },
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(events, ['first-start', 'first-end', 'second-start']);
  });
}
