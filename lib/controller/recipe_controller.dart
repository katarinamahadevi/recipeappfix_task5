import 'package:flutter/material.dart';
import 'package:recipeappfix_task5/models/category_model.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/services/recipe_service.dart';

class RecipeProvider with ChangeNotifier {


  final RecipeService _recipeService = RecipeService();
  List<RecipeModel> _recipes = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isCategoriesLoading = false;

  List<RecipeModel> get recipes => _recipes;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;

  Future<void> fetchRecipes({int page = 1}) async { 
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedRecipes = await _recipeService.getAllRecipes(page: page);
      _recipes = fetchedRecipes;

      await fetchCategories();
    } catch (e) {
      print("Error fetching recipes: $e");
      _recipes = [];
    } finally {
      if (WidgetsBinding.instance.lifecycleState !=
          AppLifecycleState.detached) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchCategories() async {
    if (_isCategoriesLoading) return;
    _isCategoriesLoading = true;
    notifyListeners();

    try {
      final fetchedCategories = await _recipeService.getCategoriesFromRecipes();
      _categories = fetchedCategories;
      print("Categories fetched: ${_categories.length}");
    } catch (e) {
      print("Error fetching categories: $e");
      _categories = [];
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRecipe(RecipeModel recipe) async { //methpd add recipe
    try {
      final newRecipe = await _recipeService.createRecipe(recipe);
      _recipes.add(newRecipe);
      notifyListeners();
      return true;
    } catch (e) {
      print("Error adding recipe: $e");
      return false;
    }
  }

  Future<bool> updateRecipe(RecipeModel recipe) async { //method update recipe
    try {
      final success = await _recipeService.updateRecipe(recipe);
      if (success) {
        final index = _recipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _recipes[index] = recipe;
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      print("Error updating recipe: $e");
      return false;
    }
  }

  Future<bool> deleteRecipe(int id) async { //method delete recipe
    try {
      final success = await _recipeService.deleteRecipe(id);
      if (success) {
        _recipes.removeWhere((recipe) => recipe.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print("Error deleting recipe: $e");
      return false;
    }
  }
}
