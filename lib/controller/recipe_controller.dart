import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipeappfix_task5/models/category_model.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/services/recipe_service.dart';
import 'package:recipeappfix_task5/main.dart';

class RecipeProvider with ChangeNotifier {
  final RecipeService _recipeService = RecipeService();
  List<RecipeModel> _recipes = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  bool _isUploadingImage = false;

  List<RecipeModel> get recipes => _recipes;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  bool get isUploadingImage => _isUploadingImage;

  /// **🔹 Fetch Categories**
  Future<void> fetchCategories() async {
    if (_isCategoriesLoading) return;
    _isCategoriesLoading = true;
    notifyListeners();

    try {
      final fetchedCategories = await _recipeService.getAllCategories();

      print("Kategori yang berhasil dimuat:");
      for (var category in fetchedCategories) {
        print("ID: ${category.id}, Nama: ${category.name}");
      }

      if (fetchedCategories.isNotEmpty) {
        _categories = fetchedCategories;
        notifyListeners();
      } else {
        print("Tidak ada kategori yang ditemukan");
      }
    } catch (e) {
      print("Gagal memuat kategori: $e");
      _categories = [];
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// **🔹 Pick Image from Gallery**
  Future<File?> pickImageFromGallery(ImagePicker picker) async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
    return null;
  }

  /// **🔹 Upload Recipe (Create / Update)**
  Future<String?> uploadImage({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required File? imageFile,
    required RecipeModel recipe,
    required bool isEditMode,
  }) async {
    if (!formKey.currentState!.validate()) return null;

    if (imageFile == null && isEditMode && recipe.image.isNotEmpty) {
      updateRecipe(recipe);
      Navigator.pop(context);
    }

    if (imageFile == null && !isEditMode) {
      print('Tidak ada file gambar yang dipilih');
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Silakan pilih gambar terlebih dahulu')),
        );
      }
      return null;
    }

    _isUploadingImage = true;
    notifyListeners();

    try {
      return isEditMode ? updateRecipe(recipe) : createRecipe(recipe);
    } catch (e) {
      print('Error: $e');
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(
          navigatorKey.currentContext!,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan resep: $e')));
      }
      return null;
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// **🔹 Create Recipe**
  Future<String?> createRecipe(RecipeModel recipe) async {
    try {
      final formData = FormData.fromMap({
        'title': recipe.title,
        'description': recipe.description,
        'category_id': recipe.categoryId.toString(),
        if (recipe.image.isNotEmpty)
          'image': await MultipartFile.fromFile(
            recipe.image,
            filename: 'image.jpg',
          ),
      });

      final Dio dio = Dio(BaseOptions(headers: {'Accept': "application/json"}));
      final response = await dio.post(
        'https://tokopaedi.arfani.my.id/api/recipes',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text('Resep berhasil disimpan')),
          );
        }
        return response.data['data']['image'];
      } else {
        throw Exception('Gagal menyimpan resep: ${response.statusCode}');
      }
    } catch (e) {
      print('Error menyimpan resep: $e');
      return null;
    }
  }

  /// **🔹 Update Recipe**
  Future<String?> updateRecipe(RecipeModel recipe) async {
    try {
      final formData = FormData.fromMap({
        'title': recipe.title,
        'description': recipe.description,
        'category_id': recipe.categoryId.toString(),
        // This is important for Laravel-based APIs that need method spoofing
        if (recipe.image.isNotEmpty && recipe.image.startsWith('/'))
          'image': await MultipartFile.fromFile(
            recipe.image,
            filename: 'image.jpg',
          ),
      });
      final response = await _recipeService.dio.post(
        'https://tokopaedi.arfani.my.id/api/recipes/${recipe.id}/update',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        // Success handling
        return response.data['data']['image'];
      } else {
        throw Exception('Failed to update recipe: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating recipe: $e');
      return null;
    }
  }

  /// **🔹 Delete Recipe**
  Future<bool> deleteRecipe(int id) async {
    try {
      final success = await _recipeService.deleteRecipe(id);
      if (success) {
        _recipes.removeWhere((recipe) => recipe.id == id);
        notifyListeners();
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text('Resep berhasil dihapus')),
          );
        }
      }
      return success;
    } catch (e) {
      print("Error deleting recipe: $e");
      return false;
    }
  }

  /// **🔹 Fetch Recipes**
  Future<void> fetchRecipes({int page = 1}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedRecipes = await _recipeService.getAllRecipes(page: page);
      _recipes = fetchedRecipes;
      await fetchCategories(); // Pastikan kategori juga dimuat
    } catch (e) {
      print("Error fetching recipes: $e");
      _recipes = [];
    } finally {
      if (navigatorKey.currentContext != null) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
