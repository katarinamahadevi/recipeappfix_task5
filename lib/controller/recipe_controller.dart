import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipeappfix_task5/models/category_model.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/pages/homepage.dart';
import 'package:recipeappfix_task5/services/recipe_service.dart';
import 'package:recipeappfix_task5/main.dart';

class RecipeProvider with ChangeNotifier {
  String _searchQuery = '';
  CategoryModel? _selectedCategory;
  List<RecipeModel> _allRecipes = []; // Store all loaded recipes
  String get searchQuery => _searchQuery;
  CategoryModel? get selectedCategory => _selectedCategory;
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

  // Metode untuk mencari resep dari API
  Future<void> searchRecipesFromApi(String query) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      _searchQuery = query;
      
      // Jika query kosong, kembalikan semua resep
      if (query.isEmpty) {
        await fetchRecipes();
        return;
      }
      
      final searchedRecipes = await _recipeService.searchRecipes(query);
      _allRecipes = searchedRecipes; // Simpan dalam allRecipes
      
      // Filter berdasarkan query
      _recipes = searchedRecipes.where((recipe) {
        return recipe.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      // Jika ada kategori yang dipilih, terapkan filter kategori juga
      if (_selectedCategory != null) {
        _recipes = _recipes.where((recipe) {
          return recipe.categoryId == _selectedCategory!.id;
        }).toList();
      }
      
      print("Hasil Filter Lokal: ${_recipes.map((e) => e.title).toList()}");
    } catch (e) {
      print("Error searching recipes from API: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk mendapatkan resep berdasarkan kategori dari API
  Future<void> getRecipesByCategoryFromApi(CategoryModel category) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      _selectedCategory = category;
      
      // Jika tidak ada query pencarian, ambil langsung dari API
      if (_searchQuery.isEmpty) {
        final categoryRecipes = await _recipeService.getRecipesByCategory(category.id);
        _recipes = categoryRecipes;
        _allRecipes = categoryRecipes;
      } else {
        // Jika ada query pencarian, filter hasil pencarian berdasarkan kategori
        // Pertama, periksa apakah sudah ada data pencarian
        if (_allRecipes.isEmpty) {
          // Jika belum ada, ambil data pencarian dulu
          await searchRecipesFromApi(_searchQuery);
        }
        
        // Filter berdasarkan kategori dari hasil pencarian yang sudah ada
        _recipes = _allRecipes.where((recipe) {
          return recipe.categoryId == category.id && 
                 recipe.title.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    } catch (e) {
      print("Error filtering recipes by category from API: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metode untuk me-reset filter dan mendapatkan semua resep
  Future<void> resetAndFetchAllRecipes() async {
    _searchQuery = '';
    _selectedCategory = null;
    _allRecipes = [];

    await fetchRecipes();
  }

  // Metode untuk mendapatkan semua resep yang memuat pencarian saat ini
  Future<void> showAllCategoriesWithCurrentSearch() async {
    _selectedCategory = null;
    
    if (_searchQuery.isNotEmpty) {
      // Jika ada pencarian aktif, terapkan filter pencarian pada semua resep
      await searchRecipesFromApi(_searchQuery);
    } else {
      // Jika tidak ada pencarian, tampilkan semua resep
      await fetchRecipes();
    }
  }

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

  /// **🔹 Fetch Recipes**
  Future<void> fetchRecipes({int page = 1}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedRecipes = await _recipeService.getAllRecipes(page: page);
      _recipes = fetchedRecipes;
      _allRecipes = fetchedRecipes; // Simpan juga di allRecipes
      await fetchCategories(); // Pastikan kategori juga dimuat
    } catch (e) {
      print("Error fetching recipes: $e");
      _recipes = [];
      _allRecipes = [];
    } finally {
      if (navigatorKey.currentContext != null) {
        _isLoading = false;
        notifyListeners();
      }
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
        (route) => false,
      );
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
        _allRecipes.removeWhere((recipe) => recipe.id == id);
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
}