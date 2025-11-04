import 'package:flutter_test/flutter_test.dart';

import 'package:wp_rest_demo/main.dart';

void main() {
  testWidgets('MyApp builds', (WidgetTester tester) async {
    // Строим приложение
    await tester.pumpWidget(MyApp());

    // Проверяем, что виджет MyApp существует
    expect(find.byType(MyApp), findsOneWidget);

    // Дополнительно проверяем, что есть AppBar с заголовком
    expect(find.text('Список постов'), findsOneWidget);
  });
}
