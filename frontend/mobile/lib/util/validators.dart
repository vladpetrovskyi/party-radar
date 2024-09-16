class UsernameValidator {
  static bool isValid(String? username) {
    return username != null && RegExp(r'^[a-z0-9._]+$').hasMatch(username);
  }
}

class EmailValidator {
  static bool isValid(String? email) {
    return email != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

  }
}