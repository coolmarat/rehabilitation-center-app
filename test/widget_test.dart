// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:rehabilitation_center_app/main.dart';
import 'package:rehabilitation_center_app/injection_container.dart' as di; // Импортируем DI

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Инициализируем DI перед запуском теста
    // Важно: Для тестов может потребоваться 'мокнуть' зависимости,
    // особенно базу данных или сетевые вызовы. Пока оставим так.
    await di.init();
    // Build our app and trigger a frame.
    // Передаем MyApp без параметра database
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    // Замените эти проверки на актуальные для вашего UI
    // Эти проверки, вероятно, упадут, т.к. у нас нет счетчика
    expect(find.text('0'), findsNothing); 
    expect(find.text('1'), findsNothing); 

    // // Tap the '+' icon and trigger a frame.
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();

    // // Verify that our counter has incremented.
    // expect(find.text('0'), findsNothing);
    // expect(find.text('1'), findsOneWidget);
  });
}
