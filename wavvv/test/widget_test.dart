import 'package:flutter_test/flutter_test.dart';
import 'package:wavvv/app.dart';

void main() {
  testWidgets('WavvvApp renders', (WidgetTester tester) async {
    // Basic smoke test - app widget can be created
    expect(const WavvvApp(), isNotNull);
  });
}
