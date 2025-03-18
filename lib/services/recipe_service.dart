import 'package:dio/dio.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/models/category_model.dart';

class RecipeService {
  final Dio _dio = Dio();
  final String baseUrl = "https://tokopaedi.arfani.my.id/api/recipes";
  final String categoriesUrl = "https://tokopaedi.arfani.my.id/api/categories";

  Future<List<RecipeModel>> getAllRecipes({int page = 1}) async {
    try {
      final response = await _dio.get("$baseUrl?page=$page");
      print("API Response: ${response.data}");

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey("data") &&
          response.data["data"] is Map<String, dynamic> &&
          response.data["data"].containsKey("data")) {
        List<dynamic> recipesJson = response.data["data"]["data"];
        return recipesJson.map((json) => RecipeModel.fromJson(json)).toList();
      } else {
        throw Exception("Invalid response format");
      }
    } catch (e) {
      print("Error fetching recipes: $e");
      throw Exception("Failed to load recipes: $e");
    }
  }

  // Method to fetch categories using the recipe data
  // This extracts categories from recipe data we already have
  Future<List<CategoryModel>> getCategoriesFromRecipes() async {
    try {
      // Get recipes first
      final recipes = await getAllRecipes();

      // Extract unique categories
      final Map<int, CategoryModel> uniqueCategories = {};
      for (var recipe in recipes) {
        if (!uniqueCategories.containsKey(recipe.category.id)) {
          uniqueCategories[recipe.category.id] = recipe.category;
        }
      }

      print("Categories extracted from recipes: ${uniqueCategories.length}");
      return uniqueCategories.values.toList();
    } catch (e) {
      print("Error extracting categories: $e");
      throw Exception("Failed to extract categories: $e");
    }
  }

  // Add method to create a new recipe
  Future<RecipeModel> createRecipe(RecipeModel recipe) async {
    try {
      final response = await _dio.post(
        'https://tokopaedi.arfani.my.id/api/recipes',
        options: Options(headers: {'Accept': 'application/json'}),
        data: {
          "title": recipe.title,
          "description": recipe.description,
          "image": recipe.image,
          "category_id": recipe.categoryId,
        },
      );

      return RecipeModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception("Failed to create recipe: $e");
    }
  }

  // Add method to update a recipe
  Future<bool> updateRecipe(RecipeModel recipe) async {
    try {
      final response = await _dio.put(
        "$baseUrl/${recipe.id}",
        data: {
          "title": recipe.title,
          "description": recipe.description,
          "image": recipe.image,
          "category_id": recipe.categoryId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to update recipe: $e");
    }
  }

  // Add method to delete a recipe
  Future<bool> deleteRecipe(int id) async {
    try {
      final response = await _dio.delete("$baseUrl/$id");
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to delete recipe: $e");
    }
  }
}
