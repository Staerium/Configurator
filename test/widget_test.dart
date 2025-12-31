import 'package:configurator/legal_screen.dart';
import 'package:configurator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the home actions and disabled server button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Konfigurator');
    expect(materialApp.locale, const Locale('de'));

    expect(find.text('Projekt öffnen'), findsOneWidget);
    expect(find.text('Projekt erstellen'), findsOneWidget);

    final disabledServerButton = find.widgetWithText(
      ElevatedButton,
      'mit Staerium-Server verbinden (demnächst)',
    );
    expect(disabledServerButton, findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(disabledServerButton).onPressed,
      isNull,
    );
  });

  testWidgets('navigates to ConfigScreen when creating a project',
      (WidgetTester tester) async {
    final binding =
        TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
    binding.window.physicalSizeTestValue = const Size(1400, 2000);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(binding.window.clearPhysicalSizeTestValue);
    addTearDown(binding.window.clearDevicePixelRatioTestValue);

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Projekt erstellen'));
    await tester.pumpAndSettle();

    expect(find.byType(ConfigScreen), findsOneWidget);
  });

  testWidgets('opens the legal screen from the app bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.policy));
    await tester.pumpAndSettle();

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Rechtliches'), findsOneWidget);
  });
}
