import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipeappfix_task5/controller/recipe_controller.dart';
import 'package:recipeappfix_task5/models/category_model.dart';
import 'package:recipeappfix_task5/pages/add_recipe_page.dart';
import 'package:recipeappfix_task5/pages/detail_recipe_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String searchQuery = '';
  CategoryModel? selectedCategory;
  bool showFilterOptions = false;

  @override
  void initState() {
    super.initState();
    // Ensure fetchRecipes() isn't called while the widget is being built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeProvider>(context, listen: false).fetchRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        automaticallyImplyLeading: false,
        title: Text("Aplikasi Resep", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar & Filter Button
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Filter Button
                IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.blueGrey),
                  onPressed: () {
                    setState(() {
                      showFilterOptions = !showFilterOptions;
                    });
                  },
                ),
              ],
            ),
          ),

          // Filter Options
          if (showFilterOptions)
            Consumer<RecipeProvider>(
              builder: (context, recipeProvider, _) {
                // Check if categories are loaded
                if (recipeProvider.categories.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Memuat kategori...",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  );
                }

                // Build category filter chips
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                        child: Text(
                          "Filter berdasarkan kategori:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          // Add "All" filter option
                          FilterChip(
                            label: Text("Semua"),
                            selected: selectedCategory == null,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategory = null;
                              });
                            },
                            backgroundColor: Colors.grey.shade200,
                            selectedColor: Colors.blueGrey.shade200,
                            checkmarkColor: Colors.white,
                          ),

                          // Add category filter options
                          ...recipeProvider.categories.map((category) {
                            return FilterChip(
                              label: Text(category.name),
                              selected: selectedCategory?.id == category.id,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = selected ? category : null;
                                });
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: Colors.blueGrey.shade200,
                              checkmarkColor: Colors.white,
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

          // ListView
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, recipeProvider, _) {
                if (recipeProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (recipeProvider.recipes.isEmpty) {
                  return Center(child: Text("Tidak ada resep yang ditemukan"));
                }

                // Filter recipes by search query and selected category
                final filteredRecipes =
                    recipeProvider.recipes.where((recipe) {
                      // Filter by search query
                      final matchesSearch = recipe.title.toLowerCase().contains(
                        searchQuery,
                      );

                      // Filter by category
                      final matchesCategory =
                          selectedCategory == null ||
                          recipe.categoryId == selectedCategory!.id;

                      return matchesSearch && matchesCategory;
                    }).toList();

                if (filteredRecipes.isEmpty) {
                  return Center(
                    child: Text(
                      selectedCategory != null
                          ? "Tidak ada resep yang cocok dengan kategori '${selectedCategory!.name}'"
                          : "Tidak ada resep yang cocok dengan pencarian",
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = filteredRecipes[index];
                    return Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DetailRecipePage(recipe: recipe),
                            ),
                          );
                        },
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.network(
                            recipe.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        title: Text(
                          recipe.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.description,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                recipe.category.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecipePage()),
          ).then((_) {
            // Refresh recipes when returning from add page
            Provider.of<RecipeProvider>(context, listen: false).fetchRecipes();
          });
        },
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Tambah Resep"),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
