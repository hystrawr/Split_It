import 'package:flutter_test/flutter_test.dart';

import 'package:split_it/main.dart';

void main() {
  testWidgets('App starts on the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitItApp());

    expect(find.text('Split It'), findsOneWidget);
    expect(find.text('No groups yet'), findsOneWidget);
  });
}
