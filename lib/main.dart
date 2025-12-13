import 'package:flutter/material.dart';
import 'services/api_service.dart'; // ✅ ADD THIS
import 'login_screen.dart';
import 'registration_page.dart';
import 'pet_listing_page.dart';
import 'add_pet_page.dart';

void main() async {
  // ✅ ADD THESE 3 LINES
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
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

      // ✅ REPLACE initialRoute with home
      home: FutureBuilder<bool>(
        future: ApiService.isAuthenticated(),
        builder: (context, snapshot) {
          // Show loading while checking authentication
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFE6F7F5),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4FD1C7)),
              ),
            );
          }

          // If token exists → Go to Pet Listing
          // If no token → Go to Login
          if (snapshot.data == true) {
            return const PetListingPage();
          } else {
            return const LoginScreen();
          }
        },
      ),

      // ✅ KEEP YOUR ROUTES
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegistrationPage(),
        '/pet-listing': (context) => const PetListingPage(),
        '/add-pet': (context) => AddPetPage(),
      },
    );
  }
}
