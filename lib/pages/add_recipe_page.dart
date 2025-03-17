import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_quill/flutter_quill.dart';
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

  // Menggunakan QuillController untuk deskripsi
  late QuillController _descriptionController;

  CategoryModel? _selectedCategory;
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isUploadingImage = false;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();

    // Initialize QuillController
    _descriptionController = QuillController.basic();

    _loadCategories();

    // If recipe is provided, we're in edit mode
    if (widget.recipe != null) {
      _isEditMode = true;
      _titleController.text = widget.recipe!.title;

      // Set the description to QuillController
      // For edit mode, you might need to convert plain text to Delta
      // This is a simple approach - in a real app you might store the Delta format

      _imageUrl = widget.recipe!.image;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final RecipeService recipeService = RecipeService();
      // Use the method to get categories from recipes
      final categoriesData = await recipeService.getCategoriesFromRecipes();
      setState(() {
        _categories = categoriesData;
        // If in edit mode, find and set the matching category
        if (_isEditMode && widget.recipe != null) {
          _selectedCategory = _categories.firstWhere(
            (category) => category.id == widget.recipe!.categoryId,
            orElse: () => _categories.isNotEmpty ? _categories.first : null!,
          );
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
        _isLoading = false;
      });
      print("Categories loaded: ${_categories.length}");
      if (_categories.isNotEmpty) {
        print("First category: ${_categories.first.name}");
      }
    } catch (e) {
      print("Error in _loadCategories: $e");
      setState(() {
        _isLoading = false;
        // Create a default category if there's an exception
        if (_categories.isEmpty) {
          final defaultCategory = CategoryModel(
            id: 1,
            name: "Default Category",
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _categories = [defaultCategory];
          _selectedCategory = defaultCategory;

          // Show a warning to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Using default category - could not load categories',
              ),
            ),
          );
        }
      });
    }
  }

  // Method to pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrl = null; // Clear previous URL since we have a new file
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat mengakses galeri: $e')),
      );
    }
  }

  // Method to upload image to server
  Future<String?> _uploadImage() async {
    if (_imageFile == null)
      return _imageUrl; // Return existing URL if no new image

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Create form data
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          _imageFile!.path,
          filename: 'image.jpg',
        ),
      });

      // Upload image
      final Dio dio = Dio();
      final response = await dio.post(
        'https://tokopaedi.arfani.my.id/api/recipes?page=1&title=&category_id=',
        data: formData,
      );

      // Check response
      if (response.statusCode == 200 && response.data != null) {
        // Extract image URL from response
        final imageUrl = response.data['url'] as String;
        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      return null;
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
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

      if (_imageFile == null && _imageUrl == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select an image')));
        return;
      }

      // Get plain text from Quill editor
      final description = _descriptionController.document.toPlainText().trim();

      // Check if description is empty
      if (description.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deskripsi tidak boleh kosong')));
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Upload image if a new one is selected
        final uploadedImageUrl = await _uploadImage();
        if (uploadedImageUrl == null && _imageUrl == null) {
          throw Exception('Failed to get image URL');
        }

        final imageUrl = uploadedImageUrl ?? _imageUrl!;
        final RecipeProvider recipeProvider = Provider.of<RecipeProvider>(
          context,
          listen: false,
        );

        if (_isEditMode && widget.recipe != null) {
          // Update existing recipe
          final updatedRecipe = RecipeModel(
            id: widget.recipe!.id,
            title: _titleController.text,
            description: description,
            image: imageUrl,
            categoryId: _selectedCategory!.id,
            category: _selectedCategory!,
            createdAt: widget.recipe!.createdAt,
            updatedAt: DateTime.now(),
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
            id: 0,
            title: _titleController.text,
            description: description,
            image: imageUrl,
            categoryId: _selectedCategory!.id,
            category: _selectedCategory!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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
        print("Error saving recipe: $e");
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Resep' : 'Tambah Resep'),
        backgroundColor: Colors.blueGrey,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body:
          _isLoading || _isUploadingImage
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueGrey),
                    SizedBox(height: 16),
                    Text(
                      _isUploadingImage ? 'Uploading image...' : 'Loading...',
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Recipe image or image picker
                    GestureDetector(
                      onTap: _pickImageFromGallery,
                      child: Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child:
                            _imageFile != null || _imageUrl != null
                                ? ClipRect(
                                  child:
                                      _imageFile != null
                                          ? Image.file(
                                            _imageFile!,
                                            fit: BoxFit.cover,
                                            height: 250,
                                            width: double.infinity,
                                          )
                                          : Image.network(
                                            _imageUrl!,
                                            fit: BoxFit.cover,
                                            height: 250,
                                            width: double.infinity,
                                            loadingBuilder: (
                                              context,
                                              child,
                                              loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value:
                                                      loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                  color: Colors.blueGrey,
                                                ),
                                              );
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Center(
                                                child: Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          ),
                                )
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 64,
                                        color: Colors.blueGrey,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Tambah gambar resep',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),

                    // Form section with recipe details
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title field with styling consistent with detail page
                            Text(
                              'Nama Resep',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Ketik nama resep...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.blueGrey,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              style: TextStyle(fontSize: 16),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Isi nama resep';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Category dropdown with styling consistent with detail page
                            Text(
                              'Kategori',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            _categories.isEmpty
                                ? Text(
                                  "Tidak ada kategori tersedia",
                                  style: TextStyle(color: Colors.red),
                                )
                                : DropdownButtonFormField<CategoryModel>(
                                  decoration: InputDecoration(
                                    hintText: 'Pilih Kategori',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.blueGrey,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
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
                                ),
                            SizedBox(height: 16),

                            // Description field - REPLACED WITH FLUTTER QUILL
                            Text(
                              'Deskripsi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  // Toolbar for formatting
                                  QuillSimpleToolbar(
                                    controller: _descriptionController,
                                    config: const QuillSimpleToolbarConfig(
                                      showBoldButton: true,
                                      showItalicButton: true,
                                      showUnderLineButton: true,
                                      showStrikeThrough: false,
                                      showColorButton: false,
                                      showBackgroundColorButton: false,
                                      showClearFormat: true,
                                      showAlignmentButtons: false,
                                      showLeftAlignment: false,
                                      showCenterAlignment: false,
                                      showRightAlignment: false,
                                      showJustifyAlignment: false,
                                      showHeaderStyle: false,
                                      showListNumbers: true,
                                      showListBullets: true,
                                      showListCheck: false,
                                      showCodeBlock: false,
                                      showQuote: false,
                                      showIndent: false,
                                      showLink: false,
                                      showUndo: true,
                                      showRedo: true,
                                      showDirection: false,
                                      showSearchButton: false,
                                      showSubscript: false,
                                      showSuperscript: false,
                                    ),
                                  ),
                                  // Editor
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: QuillEditor.basic(
                                        controller: _descriptionController,
                                        config: const QuillEditorConfig(
                                          placeholder:
                                              'Tulis deskripsi resep Anda di sini...',
                                          padding: EdgeInsets.all(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),

                            // Save button with consistent styling
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _saveRecipe,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  _isEditMode ? 'Ubah Resep' : 'Simpan Resep',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
