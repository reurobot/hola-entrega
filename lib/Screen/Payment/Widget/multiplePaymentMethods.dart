import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Helper/Color.dart';
import '../../../Helper/String.dart';
import '../../../Provider/CartProvider.dart';
import '../../../widgets/desing.dart';

class MultiplePaymentMethods extends StatefulWidget {
  final Function update;
  final VoidCallback onPaymentComplete;

  const MultiplePaymentMethods({
    super.key,
    required this.update,
    required this.onPaymentComplete,
  });

  @override
  State<MultiplePaymentMethods> createState() => _MultiplePaymentMethodsState();
}

class _MultiplePaymentMethodsState extends State<MultiplePaymentMethods> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedMethod;
  bool _showAddPayment = false;

  final List<Map<String, String>> availableMethods = [
    {'id': 'efectivo', 'name': 'Efectivo', 'icon': ''},
    {'id': 'tarjeta', 'name': 'Tarjeta', 'icon': ''},
    {'id': 'transferencia', 'name': 'Transferencia', 'icon': ''},
    {'id': 'credito', 'name': 'Crédito', 'icon': ''},
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final totalAmount = cartProvider.totalPrice + cartProvider.deliveryCharge;
        final totalPagado = cartProvider.paymentMethods.fold(
          0.0,
          (sum, method) => sum + (method['amount'] as double),
        );

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Métodos de pago',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Lista de métodos de pago agregados
                if (cartProvider.paymentMethods.isNotEmpty) ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartProvider.paymentMethods.length,
                    itemBuilder: (context, index) {
                      final payment = cartProvider.paymentMethods[index];
                      return _buildPaymentItem(cartProvider, payment, index);
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                // Resumen de pagos
                _buildPaymentSummary(totalAmount, totalPagado),

                const SizedBox(height: 15),

                // Botón para agregar nuevo método de pago
                if (cartProvider.totalPendiente > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddPayment = !_showAddPayment;
                        if (!_showAddPayment) {
                          _amountController.clear();
                          _selectedMethod = null;
                        }
                      });
                    },
                    icon: Icon(_showAddPayment ? Icons.remove : Icons.add),
                    label: Text(_showAddPayment ? 'Cancelar' : 'Agregar método de pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),

                // Formulario para agregar nuevo pago
                if (_showAddPayment) ...[
                  const SizedBox(height: 15),
                  _buildAddPaymentForm(cartProvider),
                ],

                const SizedBox(height: 15),

                // Botón de confirmación
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cartProvider.totalPendiente <= 0
                        ? () {
                            if (cartProvider.validarPagosMultiples(context)) {
                              widget.onPaymentComplete();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Confirmar pagos'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentItem(CartProvider cartProvider, Map<String, dynamic> payment, int index) {
    final method = availableMethods.firstWhere(
      (m) => m['id'] == payment['method'],
      orElse: () => {'id': payment['method'], 'name': payment['method'], 'icon': '💰'},
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            method['icon']!,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DesignConfiguration.getPriceFormat(context, payment['amount'])!,
 
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => cartProvider.removePaymentMethod(index),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(double totalAmount, double totalPagado) {
    final pendiente = totalAmount - totalPagado;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Total a pagar:', totalAmount),
          _buildSummaryRow('Pagado:', totalPagado),
          if (pendiente > 0) ...[
            const Divider(),
            _buildSummaryRow(
              'Pendiente:',
              pendiente,
              isBold: true,
              color: pendiente > 0 ? Colors.red : Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            DesignConfiguration.getPriceFormat(context, amount)!,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPaymentForm(CartProvider cartProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de método de pago
        DropdownButtonFormField<String>(
          value: _selectedMethod,
          decoration: const InputDecoration(
            labelText: 'Método de pago',
            border: OutlineInputBorder(),
          ),
          items: availableMethods.map((method) {
            // Validar límite de crédito
            bool isDisabled = false;
            if (method['id'] == 'credito') {
              final creditoDisponible = cartProvider.creditoDisponible;
              isDisabled = creditoDisponible <= 0;
            }

            return DropdownMenuItem<String>(
              value: method['id'],
              enabled: !isDisabled,
              child: Row(
                children: [
                  Text(method['icon']!),
                  const SizedBox(width: 10),
                  Text(method['name']!),
                  if (method['id'] == 'credito')
                    Expanded(
                      child: Text(
                        ' (Disponible: ${DesignConfiguration.getPriceFormat(context, cartProvider.creditoDisponible)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDisabled ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMethod = value;
            });
          },
        ),

        const SizedBox(height: 10),

        // Campo de monto
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Monto',
            border: const OutlineInputBorder(),
            hintText: cartProvider.totalPendiente > 0
                ? 'Máximo: ${DesignConfiguration.getPriceFormat(context, cartProvider.totalPendiente)}'
                : '0.00',
          ),
        ),

        const SizedBox(height: 10),

        // Validaciones específicas
        if (_selectedMethod == 'credito') ...[
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              return Text(
                'Crédito disponible: ${DesignConfiguration.getPriceFormat(context, cartProvider.creditoDisponible)}',
                style: TextStyle(
                  color: cartProvider.creditoDisponible > 0 ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              );
            },
          ),
        ],

        const SizedBox(height: 10),

        // Botón para agregar el pago
        ElevatedButton(
          onPressed: () => _addPayment(cartProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Agregar pago'),
        ),
      ],
    );
  }

  void _addPayment(CartProvider cartProvider) {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un método de pago')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un monto válido')),
      );
      return;
    }

    // Validaciones específicas
    if (_selectedMethod == 'credito') {
      if (amount > cartProvider.creditoDisponible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monto excede el crédito disponible (${DesignConfiguration.getPriceFormat(context, cartProvider.creditoDisponible)})'),
          ),
        );
        return;
      }
    }

    // Validar que no exceda el total pendiente
    if (amount > cartProvider.totalPendiente) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monto excede el total pendiente (${DesignConfiguration.getPriceFormat(context, cartProvider.totalPendiente)})'),
        ),
      );
      return;
    }

    cartProvider.addPaymentMethod(_selectedMethod!, amount);
    
    setState(() {
      _showAddPayment = false;
      _amountController.clear();
      _selectedMethod = null;
    });

    widget.update();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}