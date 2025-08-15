import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../providers.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/address_repository.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/background_gradient.dart';
import '../../ui/widgets/gradient_button.dart';
import '../../ui/widgets/glass_card.dart';

/// Checkout screen for finalizing orders with address selection and payment
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // Selected address and payment method
  Address? _selectedAddress;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.paymob_card;
  
  // Loading state
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Get route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      // Navigate back if no arguments provided
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }
    
    // Extract order details from arguments
    final subtotal = args['subtotal'] as double;
    final deliveryFee = args['deliveryFee'] as double;
    final discount = args['discount'] as double;
    final total = args['total'] as double;
    final promoCode = args['promoCode'] as String?;
    
    // Watch addresses stream
    final addressesAsyncValue = ref.watch(addressRepositoryProvider).watchMyAddresses();
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'Checkout',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppPalette.textPrimary,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            foregroundColor: AppPalette.textPrimary,
          ),
          body: BackgroundGradient(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Address Section
                  _buildSectionTitle('Delivery Address'),
                  const SizedBox(height: 12),
                  _buildAddressSection(addressesAsyncValue),
                  const SizedBox(height: 24),
                  
                  // Payment Method Section
                  _buildSectionTitle('Payment Method'),
                  const SizedBox(height: 12),
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 24),
                  
                  // Order Summary Section
                  _buildSectionTitle('Order Summary'),
                  const SizedBox(height: 12),
                  _buildOrderSummary(subtotal, deliveryFee, discount, total, promoCode),
                  const SizedBox(height: 24),
                  
                  // Place Order Button
                  GradientButton(
                    label: 'Place Order',
                    onPressed: _selectedAddress == null
                        ? null
                        : () => _placeOrder(subtotal, deliveryFee, discount, total, promoCode),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppPalette.textPrimary,
      ),
    );
  }

  Widget _buildAddressSection(Stream<List<Address>> addressesStream) {
    return StreamBuilder<List<Address>>(
      stream: addressesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              Text(
                'Error loading addresses: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
              const SizedBox(height: 12),
              _buildAddAddressButton(),
            ],
          );
        }

        final addresses = snapshot.data ?? [];
        if (addresses.isEmpty) {
          return _buildNoAddressesMessage();
        }
        
        // Auto-select first address if none selected
        if (_selectedAddress == null && addresses.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedAddress = addresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => addresses.first,
              );
            });
          });
        }
        
        return Column(
          children: [
            // Address list
            ...addresses.map((address) => _buildAddressCard(address)),
            const SizedBox(height: 12),
            
            // Add new address button
            _buildAddAddressButton(),
          ],
        );
      },
    );
  }

  Widget _buildNoAddressesMessage() {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: AppPalette.primaryStart,
              ),
              const SizedBox(height: 12),
              Text(
                'No delivery addresses found',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please add a delivery address to continue',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildAddAddressButton(),
      ],
    );
  }

  Widget _buildAddressCard(Address address) {
    final isSelected = _selectedAddress?.id == address.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddress = address;
        });
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        overlayColor: isSelected ? AppPalette.accentLilac.withOpacity(0.1) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio button
            Radio<String>(
              value: address.id,
              groupValue: _selectedAddress?.id,
              onChanged: (_) {
                setState(() {
                  _selectedAddress = address;
                });
              },
              activeColor: AppPalette.primaryStart,
            ),
            const SizedBox(width: 8),
            
            // Address details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.fullName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppPalette.primaryEnd.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppPalette.primaryEnd,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.building}, ${address.street}, ${address.area}, ${address.city}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPalette.textSecondary,
                    ),
                  ),
                  if (address.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${address.notes}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppPalette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAddressButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/address_form');
      },
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppPalette.primaryStart),
            const SizedBox(width: 8),
            Text(
              'Add New Address',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppPalette.primaryStart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Row(
      children: [
        // Card payment option
        Expanded(
          child: _buildPaymentMethodCard(
            title: 'Credit Card',
            icon: Icons.credit_card,
            method: PaymentMethod.paymob_card,
          ),
        ),
        const SizedBox(width: 16),
        
        // Wallet payment option
        Expanded(
          child: _buildPaymentMethodCard(
            title: 'Mobile Wallet',
            icon: Icons.account_balance_wallet,
            method: PaymentMethod.paymob_wallet,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required IconData icon,
    required PaymentMethod method,
  }) {
    final isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        overlayColor: isSelected ? AppPalette.accentLilac.withOpacity(0.1) : null,
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? AppPalette.primaryStart : AppPalette.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isSelected ? AppPalette.primaryStart : AppPalette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    double subtotal,
    double deliveryFee,
    double discount,
    double total,
    String? promoCode,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', 'EGP ${subtotal.toStringAsFixed(2)}'),
          _buildSummaryRow('Delivery Fee', 'EGP ${deliveryFee.toStringAsFixed(2)}'),
          if (discount > 0) ...[
            _buildSummaryRow(
              promoCode != null ? 'Discount ($promoCode)' : 'Discount',
              '- EGP ${discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            'EGP ${total.toStringAsFixed(2)}',
            isTotal: true,
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

  Future<void> _placeOrder(
    double subtotal,
    double deliveryFee,
    double discount,
    double total,
    String? promoCode,
  ) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a delivery address',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Get cart items
      final cartRepository = ref.read(cartRepositoryProvider);
      final cartItems = await ref.read(cartProvider.future);
      
      if (cartItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create order
      final orderRepository = ref.read(orderRepositoryProvider);
      final order = await orderRepository.createOrder(
        items: cartItems,
        address: _selectedAddress!,
        deliveryFee: deliveryFee,
        discount: discount,
        promoCode: promoCode,
        method: _selectedPaymentMethod,
      );

      // Create payment intent
      final paymentResult = await orderRepository.createPaymobPayment(
        orderId: order.id,
        amount: total,
        method: _selectedPaymentMethod == PaymentMethod.paymob_card ? 'card' : 'wallet',
      );

      // Process payment based on method
      if (_selectedPaymentMethod == PaymentMethod.paymob_card) {
        final checkoutUrl = paymentResult['checkoutUrl'];
        
        if (checkoutUrl != null) {
          // Navigate to WebView for card payment
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebView(url: checkoutUrl),
            ),
          );
          
          // Handle payment result
          if (result == true) {
            // Payment successful, clear cart and navigate to orders
            await cartRepository.clearCart();
            
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/orders',
                (route) => route.settings.name == '/home',
              );
            }
          }
        } else {
          // Mock mode or error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment simulation: ${paymentResult['success'] ? 'Success' : 'Failed'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: paymentResult['success'] ? Colors.green : Colors.red,
            ),
          );
          
          if (paymentResult['success'] == true) {
            // Mock success, clear cart and navigate to orders
            await cartRepository.clearCart();
            
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/orders',
                (route) => route.settings.name == '/home',
              );
            }
          }
        }
      } else {
        // Wallet payment
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Wallet payment: Please check your phone for payment request',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blue,
          ),
        );
        
        // In a real app, we would listen for webhook callback
        // For now, just simulate success after delay
        await Future.delayed(const Duration(seconds: 3));
        await cartRepository.clearCart();
        
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/orders',
            (route) => route.settings.name == '/home',
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to place order: ${e.toString()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// WebView screen for handling card payment checkout
class PaymentWebView extends StatefulWidget {
  final String url;
  
  const PaymentWebView({super.key, required this.url});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  bool _isLoading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // Check for success or failure URLs
            if (url.contains('success') || url.contains('callback')) {
              Navigator.pop(context, true);
            } else if (url.contains('cancel') || url.contains('error')) {
              Navigator.pop(context, false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppPalette.textPrimary,
        elevation: 0,
      ),
      body: BackgroundGradient(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
