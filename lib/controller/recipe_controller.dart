import 'package:flutter/material.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/services/recipe_service.dart';

class RecipeProvider with ChangeNotifier {
  final RecipeService _recipeService = RecipeService();
  List<RecipeModel> _recipes = [];
  bool _isLoading = false;

  List<RecipeModel> get recipes => _recipes;
  bool get isLoading => _isLoading;

  Future<void> fetchRecipes({int page = 1}) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedRecipes = await _recipeService.getAllRecipes(page: page);
      _recipes = fetchedRecipes;
    } catch (e) {
      print("Error fetching recipes: $e");
      _recipes = [];
    } finally {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.detached) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Add method to create a new recipe
  Future<bool> addRecipe(RecipeModel recipe) async {
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

  // Add method to update an existing recipe
  Future<bool> updateRecipe(RecipeModel recipe) async {
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

  // Add method to delete a recipe
  Future<bool> deleteRecipe(int id) async {
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