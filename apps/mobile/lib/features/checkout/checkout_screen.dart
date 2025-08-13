import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:models/models.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../providers.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/address_repository.dart';

/// Checkout screen for finalizing orders with address selection and payment
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // App brand colors
  static const Color cream = Color(0xFFFFF8E7);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color gold = Color(0xFFD4AF37);

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
          backgroundColor: cream,
          appBar: AppBar(
            title: Text(
              'Checkout',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brown,
              ),
            ),
            backgroundColor: cream,
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedAddress == null
                        ? null
                        : () => _placeOrder(subtotal, deliveryFee, discount, total, promoCode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: Text(
                      'Place Order',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(gold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: brown,
      ),
    );
  }

  Widget _buildAddressSection(Stream<List<Address>> addressesStream) {
    return StreamBuilder<List<Address>>(
      stream: addressesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(brown),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              Text(
                'Error loading addresses: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.red),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.location_off,
                size: 48,
                color: brown,
              ),
              const SizedBox(height: 12),
              Text(
                'No delivery addresses found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: brown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please add a delivery address to continue',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brown : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
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
              activeColor: brown,
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
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: brown,
                          ),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: gold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.phone,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.building}, ${address.street}, ${address.area}, ${address.city}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (address.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${address.notes}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/address_form');
        },
        icon: const Icon(Icons.add, color: brown),
        label: Text(
          'Add New Address',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: brown,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: brown),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brown : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? brown : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? brown : Colors.grey.shade700,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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
            style: GoogleFonts.poppins(),
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
              style: GoogleFonts.poppins(),
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
                style: GoogleFonts.poppins(),
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
              style: GoogleFonts.poppins(),
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
            style: GoogleFonts.poppins(),
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
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5E3C)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
