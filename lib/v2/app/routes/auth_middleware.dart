import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/auth/controllers/auth_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      // Safe check if AuthController exists
      if (!Get.isRegistered<AuthController>()) {
        return const RouteSettings(name: '/login');
      }

      final authController = Get.find<AuthController>();

      // If user is not logged in, redirect to login
      if (!authController.isLoggedIn.value) {
        return const RouteSettings(name: '/login');
      }

      // Check if user exists before accessing properties
      final user = authController.user.value;
      if (user == null) {
        return const RouteSettings(name: '/login');
      }

      // If user is teacher trying to access parent routes
      if (route?.startsWith('/parent') == true && !user.isParent) {
        return const RouteSettings(name: '/teacher/dashboard');
      }

      // If user is parent trying to access teacher routes
      if (route?.startsWith('/teacher') == true && !user.isTeacher) {
        return const RouteSettings(name: '/parent/dashboard');
      }

      return null; // Continue to requested route
    } catch (e) {
      // If any error occurs, redirect to login
      print('AuthMiddleware error: $e');
      return const RouteSettings(name: '/login');
    }
  }
}
