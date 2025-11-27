import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:byaj_khata_book/core/theme/AppColors.dart';
import 'package:byaj_khata_book/core/utils/MediaQueryExtention.dart';

// Update import to point to your provider location if different
import '../providers/UserProvider.dart'; // ensure this path matches your project

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});


  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers for fields (new UI uses static values; we replace them with controllers)
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;

  File? _profileImageFile;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mobileController = TextEditingController();
    _addressController = TextEditingController();

    // Load provider data into controllers after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      if (user != null) {
        _nameController.text = user.name;
        _mobileController.text = user.mobile ?? '';
        _addressController.text = user.address ?? '';
        if (user.profileImagePath != null && user.profileImagePath!.isNotEmpty) {
          setState(() {
            _profileImageFile = File(user.profileImagePath!);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _profileImageFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Camera pick error: $e');
      _showSnack('Failed to pick image from camera');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _profileImageFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      _showSnack('Failed to pick image from gallery');
    }
  }

  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickFromGallery();
              },
            ),
            if (_profileImageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _profileImageFile = null;
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _saveImageLocally(File file) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final savedPath = path.join(appDir.path, fileName);
      final savedFile = await file.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      String? savedImagePath;
      if (_profileImageFile != null) {
        // If current image path already inside app directory and unchanged, we could reuse.
        // For simplicity, copy the chosen file to app dir every time (old behavior).
        savedImagePath = await _saveImageLocally(_profileImageFile!);
      }

      await userProvider.updateUserProfile(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        profileImagePath: savedImagePath ?? userProvider.user?.profileImagePath,
      );

      _showSnack('Profile updated successfully');

      // Optionally pop or stay on screen
      // Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Save profile error: $e');
      _showSnack('Failed to update profile');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // The UI below follows your NEW screen layout exactly, but with controllers and actions wired.
  @override
  Widget build(BuildContext context) {
    final sw = context.screenWidth;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.blue.shade50.withOpacity(0.5),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: context.screenWidth * 0.05,
            right: context.screenWidth * 0.05,
            bottom: 20,               // fixed padding
            top: 10,
          ),
          color: Colors.transparent,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientMid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: context.screenWidth * 0.045,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.05,
                vertical: sw * 0.05,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: sw * 0.02),

                    // PROFILE PIC SECTION (exact layout preserved)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: sw * 0.15,
                          backgroundColor: Colors.blue.shade700,
                          backgroundImage:
                          _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                          child: _profileImageFile == null
                              ? Text(
                            // If provider has name initial, show it. fallback "EM"
                            _initialsFromName(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: sw * 0.08,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                              : null,
                        ),

                        // Floating edit icon (tap to open bottom sheet)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _showProfileImageOptions,
                            child: CircleAvatar(
                              radius: sw * 0.03,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: sw * 0.04,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: sw * 0.05),

                    // NAME (dynamic)
                    Text(
                      _nameController.text.isNotEmpty ? _nameController.text : " Your name ",
                      style: GoogleFonts.poppins(
                        fontSize: sw * 0.05,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),

                    // PHONE (dynamic)
                    Text(
                      _mobileController.text.isNotEmpty ? _mobileController.text : " XXX-XXX-XXXX ",
                      style: GoogleFonts.poppins(
                        fontSize: sw * 0.04,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    SizedBox(height: sw * 0.10),

                    // PERSONAL INFORMATION TITLE (same icons/colors)
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            color: AppColors.gradientMid, size: sw * 0.05),
                        SizedBox(width: 8),
                        Text(
                          "Personal Information",
                          style: GoogleFonts.poppins(
                            fontSize: sw * 0.04,
                            fontWeight: FontWeight.w400,
                            color: AppColors.gradientMid,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: sw * 0.05),

                    // FULL NAME FIELD (label + input)
                    _buildLabel(context, "Full Name"),
                    _buildTextField(
                      controller: _nameController,
                      hint: " Your full name ",
                      keyboardType: TextInputType.name,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: sw * 0.05),

                    // PHONE NUMBER FIELD
                    _buildLabel(context, "Phone Number"),
                    _buildTextField(
                      controller: _mobileController,
                      hint: " (123) 456-7890 ",
                      keyboardType: TextInputType.phone,
                      // mobile optional: no validator
                    ),

                    SizedBox(height: sw * 0.05),

                    // ADDRESS FIELD
                    _buildLabel(context, "Address"),
                    _buildTextField(
                      controller: _addressController,
                      hint: " Your address ",
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                    ),

                    SizedBox(height: sw * 0.08),

                    // (The new UI had commented out Account Settings — we preserve that by leaving it as-is)
                    SizedBox(height: sw * 0.08),
                    // Spacer to give room for Save button overlay
                    SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Save Button fixed near bottom — full width but visually consistent with your UI.
            if (_isLoading)
              const Center(child: CircularProgressIndicator())

          ],
        ),
      ),
    );
  }

  // Returns initials for avatar fallback (from provider or controllers)
  String _initialsFromName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'EM';
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final a = parts.first.substring(0, 1).toUpperCase();
    final b = parts.last.substring(0, 1).toUpperCase();
    return '$a$b';
  }

  Widget _buildLabel(BuildContext context, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: context.screenWidth * 0.03,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: context.screenWidth * 0.013),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: context.screenWidth * 0.035,
        ),
        validator: validator,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.grey,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primaryColor,
              width: 1.8,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.8,
            ),
          ),
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey,
          ),
          floatingLabelStyle: GoogleFonts.poppins(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: AppColors.primaryColor),
          contentPadding: EdgeInsets.all(context.screenWidth * 0.03),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
