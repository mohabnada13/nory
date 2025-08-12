import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding screen with 3 pages introducing the app features
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Controller for the page view
  final PageController _pageController = PageController();
  
  // Current page index
  int _currentPage = 0;

  // Onboarding data for each page
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Fresh Bakery',
      'description': 'Discover freshly baked goods delivered straight to your door',
      'icon': Icons.bakery_dining,
      'color': const Color(0xFF8B5E3C),
    },
    {
      'title': 'Sweet Selection',
      'description': 'Explore our wide variety of pastries, cakes, and desserts',
      'icon': Icons.cake,
      'color': const Color(0xFFD4AF37),
    },
    {
      'title': 'Fast Delivery',
      'description': 'Order easily and enjoy quick delivery throughout Cairo',
      'icon': Icons.delivery_dining,
      'color': const Color(0xFF8B5E3C),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7), // Cream background
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (not shown on last page)
            Align(
              alignment: Alignment.topRight,
              child: _currentPage < _onboardingData.length - 1
                  ? TextButton(
                      onPressed: () => context.go('/signin'),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8B5E3C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : const SizedBox(height: 48),
            ),
            
            // PageView for onboarding content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(
                    _onboardingData[index]['title'],
                    _onboardingData[index]['description'],
                    _onboardingData[index]['icon'],
                    _onboardingData[index]['color'],
                  );
                },
              ),
            ),
            
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => _buildDotIndicator(index == _currentPage),
              ),
            ),
            
            // Get Started button (only on last page)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _currentPage == _onboardingData.length - 1
                  ? _buildGetStartedButton()
                  : _buildNextButton(),
            ),
          ],
        ),
      ),
    );
  }

  // Individual onboarding page content
  Widget _buildOnboardingPage(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for image - colored container with icon
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 120,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Title
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B5E3C),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Dot indicator for current page
  Widget _buildDotIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: isActive ? 12 : 8,
      width: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFD4AF37) : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  // Get Started button for last page
  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => context.go('/signin'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5E3C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Get Started',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Next button for non-last pages
  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5E3C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Next',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
