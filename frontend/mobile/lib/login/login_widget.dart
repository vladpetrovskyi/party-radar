import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:party_radar/app.dart';
import 'package:party_radar/common/services/auth_service.dart';
import 'package:party_radar/common/util/validators.dart';

class LoginWidget extends StatelessWidget {
  const LoginWidget({super.key});

  Duration get loginTime => const Duration(milliseconds: 2250);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.robotoTextTheme(),
        useMaterial3: false,
      ),
      child: FlutterLogin(
        userValidator: (value) {
          if (value == null ||
              value.isEmpty ||
              !EmailValidator.isValid(value)) {
            return 'Wrong email address';
          }
          return null;
        },
        passwordValidator: (value) {
          if (value == null || value.isEmpty || value.length < 2) {
            return 'Password should be at least 8 characters long';
          }
          return null;
        },
        logo: const AssetImage('assets/logo_login.png'),
        logoTag: 'logo_hero',
        title: 'Party Radar',
        theme: LoginTheme(
          titleStyle: const TextStyle(
            // fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyStyle: const TextStyle(color: Colors.white),
          textFieldStyle: const TextStyle(color: Colors.white),
          primaryColor: const Color.fromRGBO(51, 216, 216, 1),
          pageColorLight: const Color.fromRGBO(24, 26, 26, 1),
          pageColorDark: const Color.fromRGBO(24, 26, 26, 1),
          inputTheme: const InputDecorationTheme(
            filled: true,
            labelStyle: TextStyle(color: Colors.white),
          ),
          cardTheme: const CardTheme(color: Color.fromRGBO(26, 38, 38, 1)),
        ),
        onLogin: (data) => AuthService.login(data.name, data.password),
        onSignup: (data) => AuthService.register(data.name!, data.password!),
        loginAfterSignUp: false,
        onSubmitAnimationCompleted: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ),
          );
        },
        termsOfService: [
          TermOfService(
              id: "1",
              mandatory: true,
              text: "Accept privacy policy",
              linkUrl: "https://www.party-radar.app/privacy-policy"),
          TermOfService(
              id: "2",
              mandatory: true,
              text: "Accept terms and conditions",
              linkUrl: "https://www.party-radar.app/terms-and-conditions")
        ],
        onRecoverPassword: AuthService.recoverPassword,
        messages: LoginMessages(
            recoverPasswordIntro: 'Reset password',
            recoverPasswordDescription:
                'A link to reset your password will be sent to the provided email address',
            recoverPasswordButton: 'SEND LINK'),
      ),
    );
  }
}
