import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipeappfix_task5/controller/recipe_controller.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/pages/add_recipe_page.dart';

class DetailRecipePage extends StatelessWidget {
  final RecipeModel recipe;

  const DetailRecipePage({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Details'),
        backgroundColor: Colors.blueGrey,
        actions: [
          // Edit button
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRecipePage(recipe: recipe),
                ),
              ).then((_) {
                // Refresh the recipe list when returning from edit page
                Provider.of<RecipeProvider>(
                  context,
                  listen: false,
                ).fetchRecipes();
              });
            },
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipe image
            Image.network(
              recipe.image,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                );
              },
            ),

            // Recipe details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recipe.title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  // Category
                  Row(
                    children: [
                      Icon(Icons.category, size: 20, color: Colors.blueGrey),
                      SizedBox(width: 8),
                      Text(
                        recipe.category.name,
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Divider
                  Divider(thickness: 1),
                  SizedBox(height: 16),

                  // Description header
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  // Description text
                  Text(
                    recipe.description,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 24),

                  // Added date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Added: ${_formatDate(recipe.createdAt)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

                  // Last updated
                  Row(
                    children: [
                      Icon(Icons.update, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Updated: ${_formatDate(recipe.updatedAt)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format DateTime to a readable string
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Recipe'),
          content: Text('Are you sure you want to delete this recipe?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _deleteRecipe(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Delete the recipe
  void _deleteRecipe(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Deleting..."),
            ],
          ),
        );
      },
    );

    // Delete the recipe
    recipeProvider.deleteRecipe(recipe.id).then((success) {
      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Show success message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Recipe deleted successfully')));
        // Return to previous screen
        Navigator.of(context).pop();
      } else {
        // Show error message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete recipe')));
      }
    });
  }
}
