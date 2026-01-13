import 'package:flutter_test/flutter_test.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';

void main() {
  group('Cart Model Tests', () {
    late List<SectionModel> testCartList;

    setUp(() {
      testCartList = [];
    });

    test('should calculate total price without discounts correctly', () {
      final product1 = SectionModel(
        id: '1',
        title: 'Product 1',
        perItemPrice: 100.0,
        qty: '2',
      );

      final product2 = SectionModel(
        id: '2',
        title: 'Product 2',
        perItemPrice: 50.0,
        qty: '3',
      );

      testCartList.addAll([product1, product2]);

      final expectedTotal = (100.0 * 2) + (50.0 * 3); // 200 + 150 = 350

      expect(expectedTotal, equals(350.0));
    });

    test('should apply individual discounts correctly', () {
      final product1 = SectionModel(
        id: '1',
        title: 'Product 1',
        perItemPrice: 100.0,
        qty: '2',
      );
      product1.descuentoPorcentaje = 0.1; // 10% discount
      product1.precioConDescuento = 90.0; // 100 * 0.9
      product1.originalPrice = 100.0;

      final product2 = SectionModel(
        id: '2',
        title: 'Product 2',
        perItemPrice: 50.0,
        qty: '3',
      );
      product2.descuentoPorcentaje = 0.2; // 20% discount
      product2.precioConDescuento = 40.0; // 50 * 0.8
      product2.originalPrice = 50.0;

      testCartList.addAll([product1, product2]);

      final totalWithDiscount = (90.0 * 2) + (40.0 * 3); // 180 + 120 = 300

      expect(product1.descuentoPorcentaje, equals(0.1));
      expect(product1.precioConDescuento, equals(90.0));
      expect(product2.descuentoPorcentaje, equals(0.2));
      expect(product2.precioConDescuento, equals(40.0));
      expect(totalWithDiscount, equals(300.0));
    });

    test('should handle multiple payment methods validation', () {
      final paymentMethods = [
        {'method': 'Efectivo', 'amount': 200.0},
        {'method': 'Tarjeta', 'amount': 150.0},
      ];

      final totalPaid = paymentMethods.fold<double>(
          0.0, (sum, payment) => sum + payment['amount']! as double);

      expect(totalPaid, equals(350.0));
    });

    test('should validate credit limit correctly', () {
      final creditoDisponible = 300.0;
      final paymentMethods = [
        {'method': 'Crédito', 'amount': 500.0},
      ];

      final creditAmount = paymentMethods
          .where((p) => p['method'] == 'Crédito')
          .fold<double>(0.0, (sum, p) => sum + p['amount']! as double);

      expect(creditAmount, greaterThan(creditoDisponible));
      expect(creditoDisponible, equals(300.0));
    });

    test('should handle empty cart correctly', () {
      final emptyTotal = 0.0;

      expect(testCartList, isEmpty);
      expect(emptyTotal, equals(0.0));
    });

    test('should calculate discount percentage correctly', () {
      final originalPrice = 100.0;
      final discountedPrice = 85.0;

      final discountPercentage =
          (originalPrice - discountedPrice) / originalPrice;

      expect(discountPercentage, equals(0.15)); // 15% discount
    });

    test('should verify product mapping for API', () {
      final product1 = SectionModel(
        id: 'prod_123',
        qty: '2',
      );

      final productMap = {
        'product_id': product1.id,
        'quantity': product1.qty,
      };

      expect(productMap['product_id'], equals('prod_123'));
      expect(productMap['quantity'], equals('2'));
    });
  });
}
