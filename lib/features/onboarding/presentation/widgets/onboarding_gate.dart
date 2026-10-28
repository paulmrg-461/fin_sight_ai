import 'package:material_ui/material_ui.dart';

import '../../../../core/services/onboarding_service.dart';
import 'onboarding_screen.dart';

/// Shows the first-run tour until it is completed.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.service, required this.child});

  final OnboardingService service;
  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _completed;

  @override
  void initState() {
    super.initState();
    widget.service.isCompleted().then((value) {
      if (mounted) {
        setState(() => _completed = value);
      }
    });
  }

  Future<void> _finish() async {
    await widget.service.complete();
    if (mounted) {
      setState(() => _completed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_completed) {
      null => const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      ),
      false => OnboardingScreen(onFinish: _finish),
      true => widget.child,
    };
  }
}
