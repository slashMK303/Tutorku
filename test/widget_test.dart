import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tutorku/main.dart';
import 'package:tutorku/providers/app_state_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(),
        child: const TutorKuApp(),
      ),
    );

    // Verify that the title TutorKu appears.
    expect(find.text('TutorKu'), findsWidgets);
  });
}
