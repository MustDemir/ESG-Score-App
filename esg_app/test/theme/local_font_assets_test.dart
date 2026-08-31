import 'package:esg_app/main.dart';
import 'package:esg_app/services/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('brand fonts render without runtime fetching', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(ScanFairApp(repository: DemoProductRepository()));
    await GoogleFonts.pendingFonts();
    await tester.pumpAndSettle();

    expect(find.text('ScanFair'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
