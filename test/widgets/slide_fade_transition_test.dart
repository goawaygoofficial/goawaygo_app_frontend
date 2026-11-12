import 'package:app_frontend/global_widgets/slide_fade_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen with an outer panel that can open an inner panel, like Profile → Sign in → Register.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool outer = false;
  bool inner = false;

  void open({bool nested = false}) =>
      setState(() => nested ? inner = true : outer = true);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Text('base'),
        SlideFadeTransition(
          visible: outer,
          onClose: () => setState(() => outer = false),
          child: Stack(
            children: [
              const Text('outer'),
              SlideFadeTransition(
                visible: inner,
                onClose: () => setState(() => inner = false),
                child: const Text('inner'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void main() {
  Future<_HostState> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Host())));
    return tester.state<_HostState>(find.byType(_Host));
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('Back closes the open panel instead of leaving the app', (
    tester,
  ) async {
    final host = await pumpHost(tester);
    host.open();
    await tester.pumpAndSettle();
    expect(SlideFadeTransition.anyOpen, isTrue);

    await pressBack(tester);

    expect(host.outer, isFalse);
    expect(find.text('outer'), findsNothing);
    expect(SlideFadeTransition.anyOpen, isFalse);
  });

  testWidgets('Back closes only the top-most of nested panels', (tester) async {
    final host = await pumpHost(tester);
    host.open();
    await tester.pumpAndSettle();
    host.open(nested: true);
    await tester.pumpAndSettle();

    await pressBack(tester);
    expect(host.inner, isFalse);
    expect(host.outer, isTrue);
    expect(find.text('outer'), findsOneWidget);

    await pressBack(tester);
    expect(host.outer, isFalse);
  });
}
