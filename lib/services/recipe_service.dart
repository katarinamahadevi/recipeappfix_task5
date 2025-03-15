import 'package:dio/dio.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';

class RecipeService {
  final Dio _dio = Dio();
  final String baseUrl = "https://tokopaedi.arfani.my.id/api/recipes";

  Future<List<RecipeModel>> getAllRecipes({int page = 1}) async {
    try {
      final response = await _dio.get("$baseUrl?page=$page");
      // Debugging: Print response before processing
      print("API Response: ${response.data}");
      
      // Extract recipe list from JSON response
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
      throw Exception("Failed to load recipes: $e");
    }
  }

  // Add method to create a new recipe
  Future<RecipeModel> createRecipe(RecipeModel recipe) async {
    try {
      final response = await _dio.post(
        baseUrl,
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

  // Add method to get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get("https://tokopaedi.arfani.my.id/api/categories");
      if (response.data is Map<String, dynamic> && 
          response.data.containsKey("data")) {
        return List<Map<String, dynamic>>.from(response.data["data"]);
      } else {
        throw Exception("Invalid categories response format");
      }
    } catch (e) {
      throw Exception("Failed to load categories: $e");
    }
  }
}