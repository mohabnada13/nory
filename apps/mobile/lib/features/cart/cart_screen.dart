import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:models/models.dart';
import '../../providers.dart';
import '../../data/repositories/promo_repository.dart';

/// Cart screen showing items in the user's cart and checkout options
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // App brand colors
  static const Color cream = Color(0xFFFFF8E7);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color gold = Color(0xFFD4AF37);
  
  // Fixed delivery fee
  static const double deliveryFee = 50.0;
  
  // Controller for promo code text field
  final TextEditingController _promoController = TextEditingController();
  
  // Current applied promo
  Promo? _appliedPromo;
  
  // Current discount amount
  double _discount = 0.0;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch cart items stream
    final cartItemsAsyncValue = ref.watch(cartProvider);
    
    // Watch cart subtotal
    final subtotalAsyncValue = ref.watch(cartSubtotalProvider);
    
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: brown,
          ),
        ),
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Clear cart button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: brown),
            onPressed: _clearCart,
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: cartItemsAsyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyCart();
          }
          
          return Column(
            children: [
              // Cart items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _buildCartItem(items[index]),
                ),
              ),
              
              // Order summary
              _buildOrderSummary(items, subtotalAsyncValue),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(brown),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading cart: ${error.toString()}',
            style: GoogleFonts.poppins(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: brown,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: brown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious items to get started',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate back to home or categories
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Browse Products',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade200,
                child: const Icon(Icons.bakery_dining, color: brown, size: 40),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: brown,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'EGP ${item.unitPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: EGP ${item.lineTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity controls
          Column(
            children: [
              // Remove item button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeItem(item.productId),
                tooltip: 'Remove item',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Decrease quantity
                    InkWell(
                      onTap: () => _updateQuantity(item.productId, item.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.remove, size: 16, color: brown),
                      ),
                    ),
                    // Quantity
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Increase quantity
                    InkWell(
                      onTap: () => _updateQuantity(item.productId, item.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.add, size: 16, color: brown),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(List<OrderItem> items, AsyncValue<double> subtotalAsyncValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promo code input
          Text(
            'Promo Code',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: brown,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyPromoCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Apply',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Order summary
          Text(
            'Order Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: brown,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtotal
          subtotalAsyncValue.when(
            data: (subtotal) {
              // Calculate total
              final total = subtotal + deliveryFee - _discount;
              
              return Column(
                children: [
                  _buildSummaryRow('Subtotal', 'EGP ${subtotal.toStringAsFixed(2)}'),
                  _buildSummaryRow('Delivery Fee', 'EGP ${deliveryFee.toStringAsFixed(2)}'),
                  if (_discount > 0)
                    _buildSummaryRow('Discount', '- EGP ${_discount.toStringAsFixed(2)}', isDiscount: true),
                  const Divider(),
                  _buildSummaryRow(
                    'Total',
                    'EGP ${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Checkout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: items.isEmpty ? null : () => _proceedToCheckout(subtotal, total),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: Text(
                        'Proceed to Checkout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(brown),
              ),
            ),
            error: (error, stackTrace) => Text(
              'Error calculating total: ${error.toString()}',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isTotal ? brown : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isDiscount ? Colors.green : (isTotal ? brown : Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(String productId, int quantity) {
    if (quantity < 1) {
      _removeItem(productId);
      return;
    }
    
    try {
      final cartRepository = ref.read(cartRepositoryProvider);
      cartRepository.updateQuantity(productId, quantity);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update quantity: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeItem(String productId) {
    try {
      final cartRepository = ref.read(cartRepositoryProvider);
      cartRepository.removeFromCart(productId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove item: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Cart',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: brown,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              try {
                final cartRepository = ref.read(cartRepositoryProvider);
                cartRepository.clearCart();
                
                // Reset promo and discount
                setState(() {
                  _appliedPromo = null;
                  _discount = 0.0;
                  _promoController.clear();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to clear cart: ${e.toString()}',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a promo code',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }
    
    try {
      final promoRepository = ref.read(promoRepositoryProvider);
      final subtotal = await ref.read(cartSubtotalProvider.future);
      
      if (subtotal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Add items to your cart first',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.grey,
          ),
        );
        return;
      }
      
      final promo = await promoRepository.getByCode(code);
      
      if (promo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid or expired promo code',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check if promo is valid for this order
      if (!promo.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This promo code has expired',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check minimum order value
      if (subtotal < promo.minOrder) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Minimum order of EGP ${promo.minOrder.toStringAsFixed(2)} required for this promo',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Calculate discount
      final discount = promoRepository.calculateDiscount(promo, subtotal);
      
      setState(() {
        _appliedPromo = promo;
        _discount = discount;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Promo code applied: EGP ${discount.toStringAsFixed(2)} discount',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to apply promo code: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _proceedToCheckout(double subtotal, double total) {
    // Navigate to checkout screen with order details
    Navigator.pushNamed(
      context,
      '/checkout',
      arguments: {
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': _discount,
        'total': total,
        'promoCode': _appliedPromo?.code,
      },
    );
  }
}
