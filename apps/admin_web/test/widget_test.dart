import 'package:flutter_test/flutter_test.dart';
import 'package:nory_shop_admin/main.dart';

void main() {
  testWidgets('Nory Shop Admin app smoke test', (tester) async {
    await tester.pumpWidget(const NoryShopAdminApp());
    await tester.pumpAndSettle();
    expect(find.text('Nory Shop Admin'), findsWidgets);
  });
}
