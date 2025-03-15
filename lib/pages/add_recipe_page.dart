import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipeappfix_task5/controller/recipe_controller.dart';
import 'package:recipeappfix_task5/models/category_model.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/services/recipe_service.dart';

class AddRecipePage extends StatefulWidget {
  final RecipeModel? recipe; // Optional recipe for editing mode

  const AddRecipePage({Key? key, this.recipe}) : super(key: key);

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  CategoryModel? _selectedCategory;
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // If recipe is provided, we're in edit mode
    if (widget.recipe != null) {
      _isEditMode = true;
      _titleController.text = widget.recipe!.title;
      _descriptionController.text = widget.recipe!.description;
      _imageUrlController.text = widget.recipe!.image;
      // We'll set the selected category when categories are loaded
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final RecipeService recipeService = RecipeService();
      final categoriesJson = await recipeService.getCategories();

      setState(() {
        _categories =
            categoriesJson
                .map(
                  (json) => CategoryModel(
                    id: json['id'],
                    name: json['name'],
                    createdAt: DateTime.parse(json['created_at']),
                    updatedAt: DateTime.parse(json['updated_at']),
                  ),
                )
                .toList();

        // If in edit mode, find and set the matching category
        if (_isEditMode && widget.recipe != null) {
          _selectedCategory = _categories.firstWhere(
            (category) => category.id == widget.recipe!.categoryId,
            orElse: () => _categories.first,
          );
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
    }
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a category')));
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final RecipeProvider recipeProvider = Provider.of<RecipeProvider>(
          context,
          listen: false,
        );

        if (_isEditMode && widget.recipe != null) {
          // Update existing recipe
          final updatedRecipe = RecipeModel(
            id: widget.recipe!.id,
            title: _titleController.text,
            description: _descriptionController.text,
            image: _imageUrlController.text,
            categoryId: _selectedCategory!.id,
            category: _selectedCategory!,
            createdAt:
                widget.recipe!.createdAt, // Preserve original creation date
            updatedAt: DateTime.now(), // Update modification date
          );

          final success = await recipeProvider.updateRecipe(updatedRecipe);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recipe updated successfully')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to update recipe')));
          }
        } else {
          // Create new recipe
          final newRecipe = RecipeModel(
            id: 0, // This will be assigned by the server
            title: _titleController.text,
            description: _descriptionController.text,
            image: _imageUrlController.text,
            categoryId: _selectedCategory!.id,
            category: _selectedCategory!,
            createdAt: DateTime.now(), // Add current date
            updatedAt: DateTime.now(), // Add current date
          );

          final success = await recipeProvider.addRecipe(newRecipe);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recipe added successfully')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to add recipe')));
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Recipe' : 'Add Recipe'),
        backgroundColor: Colors.blueGrey,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Image URL field
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                          helperText: 'Enter a valid image URL',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an image URL';
                          }
                          // You can add more validation for URL format if needed
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Category dropdown
                      DropdownButtonFormField<CategoryModel>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedCategory,
                        items:
                            _categories.map((category) {
                              return DropdownMenuItem<CategoryModel>(
                                value: category,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (CategoryModel? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),

                      // Save button
                      ElevatedButton(
                        onPressed: _saveRecipe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _isEditMode ? 'Update Recipe' : 'Add Recipe',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
