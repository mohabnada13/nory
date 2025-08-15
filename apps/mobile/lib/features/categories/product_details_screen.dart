import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:models/models.dart';
import '../../providers.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/background_gradient.dart';
import '../../ui/widgets/glass_card.dart';
import '../../ui/widgets/gradient_button.dart';

/// Product details screen showing full product information and add to cart option
class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get product from route arguments
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppPalette.white),
        title: Text(
          product.name.length > 15 ? product.name.substring(0, 15) + '...' : product.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppPalette.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BackgroundGradient(
        addTopSafeArea: false,
        child: Stack(
          children: [
            // Product image at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Hero(
                tag: 'product-${product.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppPalette.accentLilac.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppPalette.accentLilac.withOpacity(0.3),
                      child: Icon(
                        Icons.bakery_dining,
                        size: 80,
                        color: AppPalette.primaryStart,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Details card
            Positioned(
              top: 270,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Promoted chip (if featured)
                        if (product.isFeatured ?? false)
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppPalette.primaryEnd.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Promoted',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppPalette.primaryEnd,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        
                        // Product title
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Rating row
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFD700),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.8',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Liked by 12.9k customers',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          'Crafted with care and baked to perfection, this delectable treat features a moist and rich ${product.name.toLowerCase()} that will satisfy your sweet cravings.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.textSecondary,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Ingredients
                        if (product.ingredients != null && product.ingredients!.isNotEmpty)
                          Text(
                            'Ingredients: ${product.ingredients}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPalette.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Nutrition info row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNutritionItem(context, 'Calories', '220 kcal'),
                            _buildNutritionItem(context, 'Total Fat', '12g'),
                            _buildNutritionItem(context, 'Cholesterol', '25mg'),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Price and Add to Cart button
                        Row(
                          children: [
                            Text(
                              'EGP ${product.priceEgp.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppPalette.primaryStart,
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              flex: 2,
                              child: GradientButton(
                                label: 'Add to Cart',
                                onPressed: () => _addToCart(context, ref, product),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutritionItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppPalette.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimary,
          ),
        ),
      ],
    );
  }
  
  void _addToCart(BuildContext context, WidgetRef ref, Product product) {
    try {
      final cartRepository = ref.read(cartRepositoryProvider);
      cartRepository.addToCart(product);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} added to cart',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppPalette.primaryStart,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add to cart: ${e.toString()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
