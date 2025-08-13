import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:models/models.dart';
import '../../providers.dart';

/// Orders screen showing the user's order history
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  // App brand colors
  static const Color cream = Color(0xFFFFF8E7);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch orders stream
    final ordersAsyncValue = ref.watch(myOrdersProvider);
    
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          'My Orders',
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
      body: ordersAsyncValue.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyOrdersMessage();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildOrderCard(context, orders[index]),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(brown),
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading orders: ${error.toString()}',
              style: GoogleFonts.poppins(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: brown,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: brown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return GestureDetector(
      onTap: () => _showOrderDetails(context, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header with ID and date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: brown,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dateFormat.format(order.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Order summary
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items count and total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'EGP ${order.total.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Status chips
                  Row(
                    children: [
                      _buildStatusChip(order.status),
                      const SizedBox(width: 8),
                      _buildPaymentStatusChip(order.paymentStatus),
                    ],
                  ),
                ],
              ),
            ),
            
            // View details button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: TextButton(
                onPressed: () => _showOrderDetails(context, order),
                style: TextButton.styleFrom(
                  foregroundColor: brown,
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    IconData iconData;
    
    switch (status) {
      case OrderStatus.processing:
        chipColor = Colors.blue;
        iconData = Icons.hourglass_top;
        break;
      case OrderStatus.baking:
        chipColor = Colors.orange;
        iconData = Icons.bakery_dining;
        break;
      case OrderStatus.out_for_delivery:
        chipColor = Colors.purple;
        iconData = Icons.delivery_dining;
        break;
      case OrderStatus.delivered:
        chipColor = Colors.green;
        iconData = Icons.check_circle;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            _formatStatus(status.name),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    Color chipColor;
    IconData iconData;
    
    switch (status) {
      case PaymentStatus.pending:
        chipColor = Colors.orange;
        iconData = Icons.pending;
        break;
      case PaymentStatus.paid:
        chipColor = Colors.green;
        iconData = Icons.payments;
        break;
      case PaymentStatus.failed:
        chipColor = Colors.red;
        iconData = Icons.error_outline;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            _formatStatus(status.name),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    // Convert snake_case to Title Case
    return status.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsSheet(order: order),
    );
  }
}

/// Bottom sheet showing detailed order information
class OrderDetailsSheet extends StatelessWidget {
  final Order order;
  
  const OrderDetailsSheet({
    super.key,
    required this.order,
  });

  // App brand colors
  static const Color cream = Color(0xFFFFF8E7);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle and title
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: brown,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Order info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: brown,
                  ),
                ),
                Text(
                  dateFormat.format(order.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Status tracker
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatusTracker(order.status),
          ),
          
          // Order content (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order items
                  _buildSectionTitle('Items'),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => _buildOrderItem(item)),
                  const SizedBox(height: 24),
                  
                  // Delivery address
                  _buildSectionTitle('Delivery Address'),
                  const SizedBox(height: 8),
                  _buildAddressCard(order.address),
                  const SizedBox(height: 24),
                  
                  // Payment information
                  _buildSectionTitle('Payment Information'),
                  const SizedBox(height: 8),
                  _buildPaymentInfo(order),
                  const SizedBox(height: 24),
                  
                  // Order summary
                  _buildSectionTitle('Order Summary'),
                  const SizedBox(height: 8),
                  _buildOrderSummary(order),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildStatusTracker(OrderStatus currentStatus) {
    final List<Map<String, dynamic>> statuses = [
      {
        'status': OrderStatus.processing,
        'label': 'Processing',
        'icon': Icons.receipt_long,
      },
      {
        'status': OrderStatus.baking,
        'label': 'Baking',
        'icon': Icons.bakery_dining,
      },
      {
        'status': OrderStatus.out_for_delivery,
        'label': 'Out for Delivery',
        'icon': Icons.delivery_dining,
      },
      {
        'status': OrderStatus.delivered,
        'label': 'Delivered',
        'icon': Icons.check_circle,
      },
    ];
    
    final currentIndex = OrderStatus.values.indexOf(currentStatus);
    
    return Row(
      children: List.generate(statuses.length, (index) {
        final isActive = index <= currentIndex;
        final isLast = index == statuses.length - 1;
        
        return Expanded(
          child: Row(
            children: [
              // Status circle
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive ? brown : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statuses[index]['icon'] as IconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statuses[index]['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? brown : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              
              // Connector line
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 3,
                    color: isActive && index < currentIndex
                        ? brown
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: const Icon(Icons.bakery_dining, color: brown, size: 30),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: brown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'EGP ${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Line total
          Text(
            'EGP ${item.lineTotal.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: brown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address.phone,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address.building}, ${address.street}, ${address.area}, ${address.city}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          if (address.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${address.notes}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInfo(Order order) {
    String paymentMethodText;
    IconData paymentIcon;
    
    switch (order.paymentMethod) {
      case PaymentMethod.paymob_card:
        paymentMethodText = 'Credit Card';
        paymentIcon = Icons.credit_card;
        break;
      case PaymentMethod.paymob_wallet:
        paymentMethodText = 'Mobile Wallet';
        paymentIcon = Icons.account_balance_wallet;
        break;
    }
    
    Color statusColor;
    String statusText;
    
    switch (order.paymentStatus) {
      case PaymentStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Payment Pending';
        break;
      case PaymentStatus.paid:
        statusColor = Colors.green;
        statusText = 'Paid';
        break;
      case PaymentStatus.failed:
        statusColor = Colors.red;
        statusText = 'Payment Failed';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Payment method
          Expanded(
            child: Row(
              children: [
                Icon(
                  paymentIcon,
                  color: brown,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  paymentMethodText,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: brown,
                  ),
                ),
              ],
            ),
          ),
          
          // Payment status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', 'EGP ${order.subtotal.toStringAsFixed(2)}'),
          _buildSummaryRow('Delivery Fee', 'EGP ${order.deliveryFee.toStringAsFixed(2)}'),
          if (order.discount > 0) ...[
            _buildSummaryRow(
              order.promoCode != null ? 'Discount (${order.promoCode})' : 'Discount',
              '- EGP ${order.discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            'EGP ${order.total.toStringAsFixed(2)}',
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
}
