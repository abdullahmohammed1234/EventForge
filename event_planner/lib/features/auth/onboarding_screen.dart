import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/utils/storage_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  final Set<String> _selectedInterests = {};
  
  // Animation controllers
  late AnimationController _fadeSlideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  late AnimationController _cardFloatController;
  late Animation<double> _cardFloatAnimation;
  
  late AnimationController _tagPopController;

  // Color palette
  static const Color beige = Color(0xFFFFE4C1);
  static const Color peach = Color(0xFFFFC1C2);
  static const Color pink = Color(0xFFFF6BBA);
  static const Color primaryPink = Color(0xFFFF6BBA);
  static const Color blue = Color(0xFF1E60EB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color yellowGreen = Color(0xFFCBFF00);
  static const Color grey = Color(0xFF636363);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Setup entrance animation
    _fadeSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeSlideController, curve: Curves.easeOut));
    
    _fadeSlideController.forward();
    
    // Setup card floating animation
    _cardFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _cardFloatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _cardFloatController, curve: Curves.easeInOut),
    );
    
    // Setup tag pop animation
    _tagPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeSlideController.dispose();
    _cardFloatController.dispose();
    _tagPopController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }
  
  void _goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _skipToRegister() async {
    // Save onboarding completion state even if user skips
    final storage = FlutterSecureStorage();
    final storageHelper = StorageHelper(storage);
    await storageHelper.setOnboardingComplete(true);
    
    // Navigate to register
    context.go('/register');
  }
  
  Future<void> _completeOnboarding() async {
    // Save onboarding completion state
    final storage = FlutterSecureStorage();
    final storageHelper = StorageHelper(storage);
    await storageHelper.setOnboardingComplete(true);
    
    // Navigate to register
    if (mounted) {
      context.go('/register');
    }
  }
  
  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
    
    // Trigger pop animation
    _tagPopController.forward().then((_) {
      _tagPopController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              beige,
              peach,
              pink,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button at top right
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _skipToRegister,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildScreen1(),
                    _buildScreen2(),
                    _buildScreen3(),
                  ],
                ),
              ),
              _buildPageIndicator(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? primaryPink
                : primaryPink.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
  
  // Screen 1 - Discover Events with local assets
  Widget _buildScreen1() {
    // Local asset images and their labels
    final cardData = [
      {'image': 'assets/image_42.png', 'label': 'Discover Events'},
      {'image': 'assets/image_49.png', 'label': 'Creative Events'},
      {'image': 'assets/image_50.png', 'label': 'Concerts'},
    ];
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Title
              const Text(
                'eventforge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'discover events near you',
                style: TextStyle(
                  fontSize: 16,
                  color: grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              // Three photo cards side by side
              Expanded(
                child: AnimatedBuilder(
                  animation: _cardFloatAnimation,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back card (left) - Discover Events
                        Transform.translate(
                          offset: Offset(0, _cardFloatAnimation.value * 0.3),
                          child: Transform.rotate(
                            angle: -0.08,
                            child: Container(
                              width: 90,
                              height: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: black.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      cardData[0]['image']!,
                                      fit: BoxFit.cover,
                                      width: 90,
                                      height: 130,
                                      errorBuilder: (context, error, stack) => _buildPlaceholderCard(0),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    left: 4,
                                    right: 4,
                                    child: _buildFloatingLabelSmall(cardData[0]['label']!),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Middle card (center) - Creative Events
                        Transform.translate(
                          offset: Offset(0, _cardFloatAnimation.value * 0.5),
                          child: Transform.rotate(
                            angle: 0.02,
                            child: Container(
                              width: 100,
                              height: 145,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      cardData[1]['image']!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 145,
                                      errorBuilder: (context, error, stack) => _buildPlaceholderCard(1),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    left: 4,
                                    right: 4,
                                    child: _buildFloatingLabelSmall(cardData[1]['label']!),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Front card (right) - Concerts
                        Transform.translate(
                          offset: Offset(0, _cardFloatAnimation.value * 0.7),
                          child: Container(
                            width: 110,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPink.withValues(alpha: 0.3),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    cardData[2]['image']!,
                                    fit: BoxFit.cover,
                                    width: 110,
                                    height: 160,
                                    errorBuilder: (context, error, stack) => _buildPlaceholderCard(2),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 4,
                                  right: 4,
                                  child: _buildFloatingLabelSmall(cardData[2]['label']!),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: black,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFloatingLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: black,
        ),
      ),
    );
  }
  
  Widget _buildFloatingLabelSmall(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: primaryPink,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderCard(int index) {
    final colors = [peach, pink, primaryPink];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[index % colors.length],
            colors[(index + 1) % colors.length],
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 50,
          color: white,
        ),
      ),
    );
  }
  
  // Screen 2 - Pick Your Interests
  Widget _buildScreen2() {
    final interests = [
      'Art',
      'Outdoor Activity',
      'Sports',
      'Films',
      'Cooking',
      'Music',
    ];
    
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
      const Color(0xFFF38181),
      const Color(0xFFAA96DA),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Title
          const Text(
            'pick your interests',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          const Text(
            'personalize your feed',
            style: TextStyle(
              fontSize: 16,
              color: grey,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 40),
          // Interests grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemCount: interests.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final isSelected = _selectedInterests.contains(interests[index]);
                return AnimatedBuilder(
                  animation: _tagPopController,
                  builder: (context, child) {
                    final scale = isSelected
                        ? 1.0 + (_tagPopController.value * 0.1)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: () => _toggleInterest(interests[index]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryPink
                                : white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? primaryPink
                                  : primaryPink.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryPink.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              interests[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? white
                                    : primaryPink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToNextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: black,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // Screen 3 - Get Started
  Widget _buildScreen3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          // Title
          const Text(
            'eventforge',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'become a member to discover, host, and attend events all in one place',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: grey,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(),
          // Get Started button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: black,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
