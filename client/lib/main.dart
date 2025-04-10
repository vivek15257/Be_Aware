import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/event_service.dart';

void main() {
  runApp(const BeAwareApp());
}

class BeAwareApp extends StatelessWidget {
  const BeAwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventService()),
      ],
      child: MaterialApp(
        title: 'Be Aware',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
} 