import 'package:test/test.dart';
import 'package:models/models.dart';

void main() {
  group('Promo.apply', () {
    // Test percent discount calculation
    test('applies percentage discount correctly', () {
      final promo = Promo(
        id: 'test-percent',
        code: 'PERCENT20',
        type: 'percent',
        value: 20, // 20% discount
        minOrder: 0,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Apply to 100 EGP order
      final discountedTotal = promo.apply(100.0);
      
      // Should be 80 EGP (100 - 20%)
      expect(discountedTotal, 80.0);
    });
    
    // Test amount discount not going below zero
    test('applies fixed amount discount without going below zero', () {
      final promo = Promo(
        id: 'test-amount',
        code: 'AMOUNT50',
        type: 'amount',
        value: 50, // 50 EGP off
        minOrder: 0,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Case 1: Apply to 100 EGP order
      var discountedTotal = promo.apply(100.0);
      // Should be 50 EGP (100 - 50)
      expect(discountedTotal, 50.0);
      
      // Case 2: Apply to 30 EGP order
      discountedTotal = promo.apply(30.0);
      // Should be 0 EGP (not negative)
      expect(discountedTotal, 0.0);
    });
    
    // Test minimum order enforcement
    test('does not apply when order is below minimum', () {
      final promo = Promo(
        id: 'test-min-order',
        code: 'MIN100',
        type: 'percent',
        value: 10, // 10% discount
        minOrder: 100, // Minimum order 100 EGP
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Case 1: Apply to 150 EGP order (above minimum)
      var discountedTotal = promo.apply(150.0);
      // Should be 135 EGP (150 - 10%)
      expect(discountedTotal, 135.0);
      
      // Case 2: Apply to 80 EGP order (below minimum)
      discountedTotal = promo.apply(80.0);
      // Should remain 80 EGP (no discount applied)
      expect(discountedTotal, 80.0);
    });
    
    // Test inactive promo
    test('does not apply when promo is inactive', () {
      final promo = Promo(
        id: 'test-inactive',
        code: 'INACTIVE20',
        type: 'percent',
        value: 20,
        minOrder: 0,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        active: false, // Inactive promo
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Apply to 100 EGP order
      final discountedTotal = promo.apply(100.0);
      
      // Should remain 100 EGP (no discount applied)
      expect(discountedTotal, 100.0);
    });
    
    // Test expired promo
    test('does not apply when promo is expired', () {
      final promo = Promo(
        id: 'test-expired',
        code: 'EXPIRED20',
        type: 'percent',
        value: 20,
        minOrder: 0,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)), // Expired yesterday
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Apply to 100 EGP order
      final discountedTotal = promo.apply(100.0);
      
      // Should remain 100 EGP (no discount applied)
      expect(discountedTotal, 100.0);
    });
  });
}
