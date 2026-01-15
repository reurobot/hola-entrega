import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Helper/Color.dart';
import '../../../Provider/CartProvider.dart';

class DynamicDiscountTable extends StatefulWidget {
  const DynamicDiscountTable({super.key});

  @override
  State<DynamicDiscountTable> createState() => _DynamicDiscountTableState();
}

class _DynamicDiscountTableState extends State<DynamicDiscountTable> {
  List<Map<String, dynamic>> discountRanges = [];
  bool isLoading = false;

  // Rangos base fijos (se pueden configurar desde settings)
  final List<Map<String, double>> baseRanges = [
    {'min': 0.0, 'max': 1000.0},
    {'min': 1000.0, 'max': 5000.0},
    {'min': 5000.0, 'max': 10000.0},
    {'min': 10000.0, 'max': 25000.0},
    {'min': 25000.0, 'max': 50000.0},
    {'min': 50000.0, 'max': double.infinity},
  ];

  @override
  void initState() {
    super.initState();
    _loadDiscountTable();
  }

  Future<void> _loadDiscountTable() async {
    setState(() {
      isLoading = true;
    });

    try {
      final cartProvider = context.read<CartProvider>();
      final dynamicDiscounts =
          await cartProvider.obtenerTablaDescuentosDinamica();

      if (dynamicDiscounts.isNotEmpty) {
        // Mapear porcentajes dinámicos a rangos base
        discountRanges = baseRanges.asMap().entries.map((entry) {
          final index = entry.key;
          final range = entry.value;
          final discount = dynamicDiscounts.length > index
              ? dynamicDiscounts[index]['porcentaje'] ?? 0.0
              : 0.0;

          return {
            'min': range['min']!,
            'max': range['max'] == double.infinity
                ? '∞'
                : range['max']!.toString(),
            'discount': discount,
          };
        }).toList();
      } else {
        // Valores por defecto si falla la API
        discountRanges = [
          {'min': 0.0, 'max': '1000.0', 'discount': 0.0},
          {'min': 1000.0, 'max': '5000.0', 'discount': 5.0},
          {'min': 5000.0, 'max': '10000.0', 'discount': 8.0},
          {'min': 10000.0, 'max': '25000.0', 'discount': 12.0},
          {'min': 25000.0, 'max': '50000.0', 'discount': 15.0},
          {'min': 50000.0, 'max': '∞', 'discount': 20.0},
        ];
      }
    } catch (e) {
      print('Error cargando tabla de descuentos: $e');
      // Valores por defecto en caso de error
      discountRanges = [
        {'min': 0.0, 'max': '1000.0', 'discount': 0.0},
        {'min': 1000.0, 'max': '5000.0', 'discount': 5.0},
        {'min': 5000.0, 'max': '10000.0', 'discount': 8.0},
        {'min': 10000.0, 'max': '25000.0', 'discount': 12.0},
        {'min': 25000.0, 'max': '50000.0', 'discount': 15.0},
        {'min': 50000.0, 'max': '∞', 'discount': 20.0},
      ];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double getCurrentDiscount(double totalAmount) {
    for (final range in discountRanges) {
      final min = range['min'] as double;
      final max = range['max'] == '∞'
          ? double.infinity
          : double.parse(range['max'].toString());

      if (totalAmount >= min && totalAmount < max) {
        return range['discount'] as double;
      }
    }
    return 0.0;
  }

  double getNextLevelAmount(double currentAmount) {
    for (final range in discountRanges) {
      final min = range['min'] as double;
      final max = range['max'] == '∞'
          ? double.infinity
          : double.parse(range['max'].toString());

      if (currentAmount >= min && currentAmount < max) {
        return max == double.infinity ? 0.0 : max;
      }
    }
    return 0.0;
  }

  double getNextLevelDiscount(double currentAmount) {
    for (int i = 0; i < discountRanges.length; i++) {
      final range = discountRanges[i];
      final min = range['min'] as double;
      final max = range['max'] == '∞'
          ? double.infinity
          : double.parse(range['max'].toString());

      if (currentAmount >= min && currentAmount < max) {
        if (i < discountRanges.length - 1) {
          return discountRanges[i + 1]['discount'] as double;
        }
        return 0.0;
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final totalAmount = cartProvider.oriPrice;
        final currentDiscount = getCurrentDiscount(totalAmount);
        final nextLevelAmount = getNextLevelAmount(totalAmount);
        final nextLevelDiscount = getNextLevelDiscount(totalAmount);
        final amountNeeded =
            nextLevelAmount > 0 ? nextLevelAmount - totalAmount : 0.0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Descuentos por monto de compra',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    if (!isLoading)
                      IconButton(
                        onPressed: _loadDiscountTable,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualizar tabla',
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Tabla de descuentos
                  _buildDiscountTable(currentDiscount, cartProvider),

                  const SizedBox(height: 15),

                  // Alerta de proximidad
                  if (amountNeeded > 0 && nextLevelDiscount > currentDiscount)
                    _buildProximityAlert(
                      context,
                      currentDiscount,
                      nextLevelDiscount,
                      amountNeeded,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscountTable(
      double currentDiscount, CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Text('Monto de compra',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(
                    child: Text('Descuento',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
                const Expanded(
                    child: Text('Estado',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),

          // Filas
          ...discountRanges.asMap().entries.map((entry) {
            final index = entry.key;
            final range = entry.value;
            final discount = range['discount'] as double;
            final isCurrentRange =
                discount == currentDiscount && currentDiscount > 0;
            final isAchieved =
                cartProvider.oriPrice >= (range['min'] as double);

            Color rowColor = Colors.transparent;
            if (isCurrentRange) {
              rowColor = colors.primary.withValues(alpha: 0.2);
            } else if (isAchieved && discount > 0) {
              rowColor = Colors.green.withValues(alpha: 0.1);
            }

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: rowColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade300,
                    width: index < discountRanges.length - 1 ? 1 : 0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      range['max'] == '∞'
                          ? 'Más de ${formatPrice(range['min'] as double)}'
                          : '${formatPrice(range['min'] as double)} - ${formatPrice(double.parse(range['max'].toString()))}',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${discount.toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: discount > 0 ? colors.primary : Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                        _buildStatusIcon(isCurrentRange, isAchieved, discount),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(
      bool isCurrentRange, bool isAchieved, double discount) {
    if (isCurrentRange && discount > 0) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    } else if (isAchieved && discount > 0) {
      return const Icon(Icons.done, color: Colors.blue, size: 20);
    } else if (discount > 0) {
      return const Icon(Icons.lock_open, color: Colors.orange, size: 20);
    } else {
      return const Icon(Icons.lock, color: Colors.grey, size: 20);
    }
  }

  Widget _buildProximityAlert(
    BuildContext context,
    double currentDiscount,
    double nextLevelDiscount,
    double amountNeeded,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Estás cerca del siguiente nivel!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega ${formatPrice(amountNeeded)} más para obtener ${nextLevelDiscount.toStringAsFixed(1)}% de descuento',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension para formatear precios
// Helper function for price formatting
String formatPrice(double amount) {
  return '\$${amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}
