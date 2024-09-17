import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:party_radar/screens/user_profile/widgets/profile_widget.dart';
import 'package:party_radar/services/image_service.dart';
import 'package:party_radar/services/user_service.dart';
import 'package:party_radar/util/validators.dart';
import 'package:party_radar/widgets/error_snack_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.image});

  final Image image;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with ErrorSnackBar {
  User? user = FirebaseAuth.instance.currentUser;
  String? imagePath;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: user?.displayName);
    _emailController = TextEditingController(text: user?.email);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [],
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              physics: const BouncingScrollPhysics(),
              children: [
                ProfileWidget(
                  isEdit: true,
                  onClicked: () => _selectImage(),
                  image: imagePath != null
                      ? Image.file(
                          File(imagePath!),
                          fit: BoxFit.cover,
                          width: 128,
                          height: 128,
                        )
                      : widget.image,
                ),
                const SizedBox(height: 24),
                _getTextFormField(
                    'Username',
                    _usernameController,
                    (value) => UsernameValidator.isValid(value)
                        ? null
                        : 'Allowed characters: a-z, 0-9, ._-'),
                const SizedBox(height: 24),
                _getTextFormField(
                    'Email address',
                    _emailController,
                    (value) => EmailValidator.isValid(value)
                        ? null
                        : 'Email address is invalid'),
                const SizedBox(height: 24),
                _getUpdateButton(),
              ],
            ),
          ),
        ),
      );

  Widget _getUpdateButton() => ElevatedButton(
        onPressed: _isLoading ? null : () => _updateUserData(),
        child: _isLoading
            ? const SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(),
              )
            : const Text('Update account'),
      );

  Widget _getTextFormField(String label, TextEditingController controller,
          Function(String?) validate) =>
      TextFormField(
        enabled: false,
        decoration: InputDecoration(
          label: Text(label),
          border: const OutlineInputBorder(),
        ),
        controller: controller,
        validator: (value) => validate(value),
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    var imageFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() => imagePath = imageFile?.path);
  }

  void _updateUserData() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      if (imagePath != null) {
        bool isImageUpdated = await _uploadImage();
        if (!isImageUpdated) {
          _showErrorSnackBar('Could not update profile picture');
          setState(() => _isLoading = false);
          return;
        }
      }
      if (_updatedUsername()) {
        bool isUserUpdated =
            await UserService.updateUsername(_usernameController.text);
        if (!isUserUpdated) {
          _showErrorSnackBar('Could not update user data');
          setState(() => _isLoading = false);
          return;
        }
      }
      if (_updatedEmail()) {
        bool isUserEmailUpdated =
            await UserService.updateEmail(_emailController.text);
        if (!isUserEmailUpdated) {
          _showErrorSnackBar('Could not update user data');
          setState(() => _isLoading = false);
          return;
        }
      }
      _returnToUserPage();
    }
  }

  void _showErrorSnackBar(String message) =>
      showErrorSnackBar(message, context);

  Future<bool> _uploadImage() async {
    var user = await UserService.getCurrentUser();
    if (user?.imageId != null) {
      return await ImageService.update(user!.imageId!, File(imagePath!));
    }
    return await ImageService.addForUser(File(imagePath!), user?.id);
  }

  void _returnToUserPage() {
    _isLoading = false;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes have been saved')),
    );
  }

  bool _updatedEmail() {
    return _emailController.text.isNotEmpty &&
        _emailController.text != FirebaseAuth.instance.currentUser?.email;
  }

  bool _updatedUsername() {
    return _usernameController.text.isNotEmpty &&
        _usernameController.text !=
            FirebaseAuth.instance.currentUser?.displayName;
  }
}
