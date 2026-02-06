import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/payment_bloc.dart';
import 'bloc/payment_event.dart';
import 'repository/payment_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => PaymentRepository(),
      child: BlocProvider(
        create: (context) => PaymentBloc(
          repository: context.read<PaymentRepository>(),
        )..add(InitializeEvent()),
        child: MaterialApp(
          title: 'Kiosk Payment Example',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
