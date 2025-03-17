import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:recipeappfix_task5/controller/recipe_controller.dart';
import 'package:recipeappfix_task5/pages/homepage.dart';
// Import lain yang diperlukan

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecipeProvider(),
      child: MaterialApp(
        title: 'Recipe App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // Konfigurasi tema lainnya
        ),
        // Tambahkan localizationsDelegates untuk Flutter Quill
        localizationsDelegates: [
          FlutterQuillLocalizations.delegate,
        ],
        home: const Homepage(), // Halaman awal aplikasi Anda
      ),
    );
  }
}