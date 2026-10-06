import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skull_kings/app.dart';
import 'package:skull_kings/ui/strings.dart';

void main() {
  testWidgets('the home screen starts a game with the chosen number of '
      'opponents', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SkullKingsApp());

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(find.byKey(const Key('opponents')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.text(Strings.newGame));
    await tester.pumpAndSettle();

    expect(find.text(Strings.roundTitle(1, 1)), findsOneWidget);
    // The human and four opponents sit at the table.
    for (final name in [Strings.you, 'Mako', 'Corail', 'Bosco', 'Sloop']) {
      expect(find.text(name), findsOneWidget);
    }
  });
}
