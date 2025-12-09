import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_page.dart';
import 'pet_listing_page.dart';
import 'add_pet_page.dart';
import 'main_navigation_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Adoption',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      // Set initial route
      initialRoute: '/login',
      // Define routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegistrationPage(),
        '/pet-listing': (context) => const PetListingPage(),
        '/add-pet': (context) => AddPetPage(),
      },
    );
  }
}
