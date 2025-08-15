import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import '../../providers.dart';
import '../../data/repositories/promo_repository.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/background_gradient.dart';
import '../../ui/widgets/glass_card.dart';
import '../../ui/widgets/gradient_button.dart';

/// Cart screen showing items in the user's cart and checkout options
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppPalette.textPrimary,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Clear cart button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppPalette.primaryStart),
            onPressed: _clearCart,
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: BackgroundGradient(
        child: cartItemsAsyncValue.when(
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
            valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading cart: ${error.toString()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
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
            color: AppPalette.primaryStart,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppPalette.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some delicious items to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Browse Products',
            onPressed: () => Navigator.pop(context),
            width: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(OrderItem item) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
                child: Icon(Icons.bakery_dining, color: AppPalette.primaryStart, size: 40),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'EGP ${item.unitPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppPalette.primaryEnd,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: EGP ${item.lineTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.textSecondary,
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
                  border: Border.all(color: AppPalette.primaryStart.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Decrease quantity
                    InkWell(
                      onTap: () => _updateQuantity(item.productId, item.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.remove, size: 16, color: AppPalette.primaryStart),
                      ),
                    ),
                    // Quantity
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        '${item.quantity}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    // Increase quantity
                    InkWell(
                      onTap: () => _updateQuantity(item.productId, item.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.add, size: 16, color: AppPalette.primaryStart),
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
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Promo code input
          Text(
            'Promo Code',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimary,
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
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.textSecondary,
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
              GradientButton(
                label: 'Apply',
                height: 44,
                width: 90,
                onPressed: _applyPromoCode,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Order summary
          Text(
            'Order Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimary,
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
                  GradientButton(
                    label: 'Proceed to Checkout',
                    onPressed: items.isEmpty ? null : () => _proceedToCheckout(subtotal, total),
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
              ),
            ),
            error: (error, stackTrace) => Text(
              'Error calculating total: ${error.toString()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isTotal ? AppPalette.primaryStart : AppPalette.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isDiscount ? Colors.green : (isTotal ? AppPalette.primaryStart : AppPalette.textSecondary),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppPalette.primaryStart,
          ),
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to apply promo code: ${e.toString()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
