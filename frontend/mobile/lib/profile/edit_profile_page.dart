import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:party_radar/profile/widgets/profile_widget.dart';
import 'package:party_radar/common/services/image_service.dart';
import 'package:party_radar/common/services/user_service.dart';
import 'package:party_radar/common/util/validators.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.image});

  final Image image;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String? _usernameValidationMsg;
  String? _emailValidationMsg;
  User? user = FirebaseAuth.instance.currentUser;
  String? imagePath;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

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
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              physics: const BouncingScrollPhysics(),
              children: [
                ProfileWidget(
                  isEdit: true,
                  onClicked: () async {
                    final ImagePicker picker = ImagePicker();
                    var imageFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    setState(() {
                      imagePath = imageFile?.path;
                    });
                  },
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
                TextFormField(
                  decoration: const InputDecoration(
                    label: Text('Username'),
                    border: OutlineInputBorder(),
                  ),
                  controller: _usernameController,
                  validator: (value) => UsernameValidator.isValid(value)
                      ? null
                      : 'Allowed characters: a-z, 0-9, ._-',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  enabled: false,
                  decoration: const InputDecoration(
                    label: Text('Email address'),
                    border: OutlineInputBorder(),
                  ),
                  controller: _emailController,
                  validator: (value) => EmailValidator.isValid(value)
                      ? null
                      : 'Email address is invalid',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      if (imagePath != null) {
                        bool isImageUpdated = await _uploadImage();
                        if (!isImageUpdated) {
                          showErrorSnackBar('Could not update profile picture');
                          return;
                        }
                      }
                      if (_updatedEmail() || _updatedUsername()) {
                        bool isUserUpdated = await UserService.updateUser(
                            username: _usernameController.text,
                            email: _emailController.text);
                        if (!isUserUpdated) {
                          showErrorSnackBar(null);
                          return;
                        }
                      }
                      _returnToUserPage();
                    }
                  },
                  child: const Text('Update Profile'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );

  Future<bool> _uploadImage() async {
    var user = await UserService.getUser();
    if (user?.imageId != null) {
      return await ImageService.updateImage(user!.imageId!, File(imagePath!));
    }
    return await ImageService.addImage(File(imagePath!), user?.id);
  }

  void showErrorSnackBar(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Could not update user data')),
    );
  }

  void _returnToUserPage() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes have been saved')),
    );
  }

  Future<void> _validateUserName(String username) async {
    setState(() {
      _usernameValidationMsg = null;
    });

    if (username.isNotEmpty &&
        username != FirebaseAuth.instance.currentUser?.displayName) {
      _usernameValidationMsg = UsernameValidator.isValid(username)
          ? null
          : 'Allowed characters: a-z, 0-9, ._-';
      if (_usernameValidationMsg != null) {
        return;
      }

      bool isExist = await UserService.userExists(username);

      if (isExist) {
        setState(() {
          _usernameValidationMsg = '$username is unavailable';
        });
      }
    }
  }

  Future<void> _validateEmail(String email) async {
    setState(() {
      _emailValidationMsg = null;
    });

    if (email.isNotEmpty && email != FirebaseAuth.instance.currentUser?.email) {
      _emailValidationMsg =
          EmailValidator.isValid(email) ? null : 'Email address is invalid';

      if (_emailValidationMsg != null) {
        return;
      }

      try {
        List<String> list =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

        if (list.isNotEmpty) {
          setState(() {
            _emailValidationMsg = '$email is unavailable';
          });
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'invalid-email') {
          setState(() {
            _emailValidationMsg = '$email is invalid';
          });
        }
      }
    }
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
