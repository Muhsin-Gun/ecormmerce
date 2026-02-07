import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/constants/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/providers/wishlist_provider.dart';
import '../../shared/widgets/section_header.dart';
import 'order_history_screen.dart';
import 'wishlist_screen.dart';
import 'address_screen.dart';
import 'payment_history_screen.dart';
import 'edit_profile_screen.dart';
import '../../shared/services/firebase_service.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger data refresh when profile is viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        context.read<OrderProvider>().loadUserOrders(user.userId);
        // Wishlist is already loaded by main.dart proxy provider, but safe to refresh
        context.read<WishlistProvider>().loadWishlist(); 
      }
    });

    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().userModel;
    
    if (user == null) return const SizedBox();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryIndigo, AppColors.electricPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.white,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.white,
                                    child: Center(
                                      child: Text(
                                        (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryIndigo,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.white,
                                  child: Center(
                                    child: Text(
                                      (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryIndigo,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppTheme.spacingM),
              
              const SectionHeader(title: 'My Account'),
              _buildSettingsTile(
                context,
                icon: Icons.person_outline,
                title: 'Personal Details',
                subtitle: 'Edit name, phone, address',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
               Consumer<OrderProvider>(
                 builder: (context, orderProvider, _) {
                   return _buildSettingsTile(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    subtitle: '${orderProvider.orders.length} orders',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    },
                  );
                 }
               ),
               Consumer<WishlistProvider>(
                 builder: (context, wishlistProvider, _) {
                   return _buildSettingsTile(
                    context,
                    icon: Icons.favorite_border,
                    title: 'Wishlist',
                    subtitle: '${wishlistProvider.wishlistItems.length} items saved',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WishlistScreen()),
                      );
                    },
                  );
                 }
               ),
               _buildSettingsTile(
                context,
                icon: Icons.location_on_outlined,
                title: 'Addresses',
                subtitle: 'Manage delivery addresses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressScreen()),
                  );
                },
              ),
               _buildSettingsTile(
                context,
                icon: Icons.payment_outlined,
                title: 'Payment History',
                subtitle: 'View your previous transactions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                  );
                },
              ),
              
              const SizedBox(height: AppTheme.spacingL),
              const SectionHeader(title: 'App Settings'),
              
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return SwitchListTile(
                    secondary: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.electricPurple,
                    ),
                    title: const Text('Dark Mode'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                  );
                },
              ),
              
              _buildSettingsTile(
                context,
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () => _toggleNotifications(context, user.notificationsEnabled),
                trailing: Switch(
                  value: user.notificationsEnabled, 
                  onChanged: (val) => _toggleNotifications(context, user.notificationsEnabled),
                  activeColor: AppColors.electricPurple,
                ),
              ),

              const SizedBox(height: AppTheme.spacingL),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthProvider>().signOut();
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Logout', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.electricPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.electricPurple),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _toggleNotifications(BuildContext context, bool current) async {
    try {
      await FirebaseService.instance.updateCurrentUserDocument({
        'notificationsEnabled': !current,
      });
    } catch (e) {
      debugPrint('Error toggling notifications: $e');
    }
  }
}
