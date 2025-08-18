import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:models/models.dart';
import '../../providers.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/background_gradient.dart';
import '../../ui/widgets/glass_card.dart';
import '../../ui/widgets/gradient_button.dart';

/// Categories screen showing category selection and products grid
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  // Selected category ID
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    // Watch categories stream
    final categoriesAsyncValue = ref.watch(categoriesProvider);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Categories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppPalette.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BackgroundGradient(
        child: Column(
          children: [
            // Categories horizontal list
            _buildCategoriesList(categoriesAsyncValue),
            
            // Products grid for selected category
            Expanded(
              child: _selectedCategoryId == null
                  ? _buildSelectCategoryMessage()
                  : _buildProductsGrid(_selectedCategoryId!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(AsyncValue<List<Category>> categoriesAsyncValue) {
    return categoriesAsyncValue.when(
      data: (categories) {
        // Auto-select first category if none selected and categories exist
        if (_selectedCategoryId == null && categories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedCategoryId = categories.first.id;
            });
          });
        }
        
        return Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == _selectedCategoryId;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: GlassCard(
                    overlayColor: isSelected 
                        ? AppPalette.primaryStart.withOpacity(0.15)
                        : null,
                    padding: const EdgeInsets.all(8),
                    borderRadius: 16,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: category.imageUrl,
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.category, color: Colors.grey),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.error, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppPalette.primaryStart : AppPalette.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
          ),
        ),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Error loading categories',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(String categoryId) {
    final productsAsyncValue = ref.watch(productsByCategoryProvider(categoryId));
    
    return productsAsyncValue.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Text(
              'No products found in this category',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppPalette.textSecondary,
              ),
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductCard(product);
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading products',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GlassCard(
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image and title - clickable to go to details
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/product_details',
                arguments: product,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Expanded(
                    child: Hero(
                      tag: 'product-${product.id}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppPalette.accentLilac.withOpacity(0.3),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppPalette.primaryStart),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppPalette.accentLilac.withOpacity(0.3),
                            child: Icon(Icons.bakery_dining, color: AppPalette.primaryStart, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Product name and price
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EGP ${product.priceEgp.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppPalette.primaryEnd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Add to cart button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GradientButton(
              label: 'Add to Cart',
              height: 40,
              onPressed: () => _addToCart(product),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCategoryMessage() {
    return Center(
      child: Text(
        'Select a category to view products',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppPalette.textSecondary,
        ),
      ),
    );
  }

  Future<void> _addToCart(Product product) async {
    final auth = ref.read(firebaseAuthProvider);

    // Prompt sign-in if the user is not authenticated
    if (auth.currentUser == null) {
      final goSignIn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign in required'),
          content: const Text('Please sign in to add items to your cart.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );

      if (goSignIn == true && context.mounted) {
        Navigator.pushNamed(context, '/signin');
      }
      return;
    }

    try {
      await ref.read(cartRepositoryProvider).addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product.name} added to cart',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
