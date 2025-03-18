import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/models/category_model.dart';

class RecipeService {
  Dio _dio() {
    final options = BaseOptions(
      baseUrl: 'https://tokopaedi.arfani.my.id/api',
      followRedirects: false,
    );

    var dio = Dio(options);

    dio.interceptors.add(
      PrettyDioLogger(requestBody: true, requestHeader: true, maxWidth: 134),
    );

    return dio;
  }

  Dio get dio => _dio();
  final String baseUrl = "https://tokopaedi.arfani.my.id/api/recipes";
  final String categoriesUrl = "https://tokopaedi.arfani.my.id/api/categories";

  Future<List<RecipeModel>> getAllRecipes({int page = 1}) async {
    try {
      final response = await dio.get("$baseUrl?page=$page");
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

  Future<List<CategoryModel>> getAllCategories() async {
  try {
    final response = await dio.get(categoriesUrl);
    
    // Karena response sudah dalam bentuk List
    if (response.data is List) {
      return (response.data as List)
          .map<CategoryModel>((json) => CategoryModel.fromJson(json))
          .toList();
    }
    
    throw Exception("Invalid categories response format");
  } catch (e) {
    print("Error fetching categories: $e");
    throw Exception("Failed to load categories: $e");
  }
}

  // Add method to create a new recipe
  Future<RecipeModel> createRecipe(RecipeModel recipe) async {
    try {
      final response = await dio.post(
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
      final response = await dio.post(
        "$baseUrl/${recipe.id}/update", // Use this endpoint instead of "/recipes/${recipe.id}/update"
        options: Options(headers: {'Accept': 'application/json'}),
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
      final response = await dio.delete("$baseUrl/$id");
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to delete recipe: $e");
    }
  }
}
