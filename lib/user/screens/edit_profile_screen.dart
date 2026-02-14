import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../shared/services/firebase_service.dart';
import '../../shared/services/cloudinary_service.dart';
import '../../shared/widgets/auth_button.dart';
import '../../shared/widgets/auth_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phoneNumber);
    _profileImageUrl = user?.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
      if (file == null) return;

      setState(() => _isLoading = true);
      final url = await CloudinaryService.uploadImage(file);
      if (url == null) throw Exception('Could not upload image to Cloudinary');

      setState(() => _profileImageUrl = url);
    } catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          e,
          fallbackMessage: 'Photo upload failed.',
          nextStep: 'Try a different image.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseService.instance.updateCurrentUserDocument({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImageUrl': _profileImageUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        AppFeedback.success(context, 'Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          e,
          fallbackMessage: 'Could not update profile.',
          nextStep: 'Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickProfilePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProfilePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Stack(
                    children: [
                      ClipOval(
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.gray200,
                          child: _profileImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: _profileImageUrl!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                )
                              : const Icon(Icons.person, size: 42, color: AppColors.gray600),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Material(
                          color: AppColors.primaryIndigo,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: _isLoading ? null : _showPhotoOptions,
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  AuthTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  AuthTextField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  AuthButton(
                    text: 'Save Changes',
                    onPressed: _saveProfile,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
