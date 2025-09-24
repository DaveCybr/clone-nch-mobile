import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/auth/controllers/auth_controller.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      // Safe check if AuthController exists
      if (!Get.isRegistered<AuthController>()) {
        return RouteSettings(name: '/login');
      }
      
      final authController = Get.find<AuthController>();

      // If user is not logged in, redirect to login
      if (!authController.isLoggedIn.value) {
        return RouteSettings(name: '/login');
      }

      // Check if user exists before accessing properties
      final user = authController.user.value;
      if (user == null) {
        return RouteSettings(name: '/login');
      }

      // If user is teacher trying to access parent routes
      if (route?.startsWith('/parent') == true && !user.isParent) {
        return RouteSettings(name: '/teacher/dashboard');
      }

      // If user is parent trying to access teacher routes
      if (route?.startsWith('/teacher') == true && !user.isTeacher) {
        return RouteSettings(name: '/parent/dashboard');
      }

      return null; // Continue to requested route
    } catch (e) {
      // If any error occurs, redirect to login
      print('AuthMiddleware error: $e');
      return RouteSettings(name: '/login');
    }
  }
}