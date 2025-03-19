import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipeappfix_task5/controller/recipe_controller.dart';
import 'package:recipeappfix_task5/models/category_model.dart';
import 'package:recipeappfix_task5/models/recipe_models.dart';
import 'package:recipeappfix_task5/pages/add_recipe_page.dart';
import 'package:recipeappfix_task5/pages/detail_recipe_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool showFilterOptions = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final recipeProvider = Provider.of<RecipeProvider>(
        context,
        listen: false,
      );
      recipeProvider.fetchCategories();
      recipeProvider.fetchRecipes();
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: Consumer<RecipeProvider>(
                    builder: (context, provider, _) {
                      return TextField(
                        controller: searchController,
                        onChanged: (value) {
                          // Jika string kosong, tetap pertahankan kategori yang dipilih
                          if (value.isEmpty) {
                            if (provider.selectedCategory != null) {
                              provider.getRecipesByCategoryFromApi(
                                provider.selectedCategory!,
                              );
                            } else {
                              provider.resetAndFetchAllRecipes();
                            }
                          } else if (value.length > 1) {
                            // Cari dengan mempertahankan filter kategori yang aktif
                            provider.searchRecipesFromApi(value.toLowerCase());
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Cari...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 10),
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

          // Filter Categories
          if (showFilterOptions)
            Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                // Check if categories are loaded
                if (provider.categories.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Memuat kategori...",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Filter berdasarkan kategori:",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            // Tombol "Semua" untuk reset filter kategori tapi tetap mempertahankan pencarian
                            FilterChip(
                              label: const Text("Semua"),
                              selected: provider.selectedCategory == null,
                              onSelected: (selected) {
                                if (selected) {
                                  // Jika ada pencarian aktif, tampilkan semua hasil pencarian
                                  if (searchController.text.isNotEmpty) {
                                    provider
                                        .showAllCategoriesWithCurrentSearch();
                                  } else {
                                    provider.resetAndFetchAllRecipes();
                                  }
                                }
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: Colors.blueGrey,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color:
                                    provider.selectedCategory == null
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),

                            // Filter untuk setiap kategori
                            ...provider.categories.map((category) {
                              final isSelected =
                                  provider.selectedCategory?.id == category.id;
                              return FilterChip(
                                label: Text(category.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    // Gunakan filter kategori dengan tetap mempertahankan pencarian
                                    provider.getRecipesByCategoryFromApi(
                                      category,
                                    );
                                  } else {
                                    // Saat deselect, kembali ke semua kategori tapi tetap pertahankan pencarian
                                    if (searchController.text.isNotEmpty) {
                                      provider
                                          .showAllCategoriesWithCurrentSearch();
                                    } else {
                                      provider.resetAndFetchAllRecipes();
                                    }
                                  }
                                },
                                backgroundColor: Colors.grey.shade200,
                                selectedColor: Colors.blueGrey,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Recipe List
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (provider.recipes.isEmpty) {
                  return Center(
                    child: Text(
                      provider.selectedCategory != null &&
                              provider.searchQuery.isNotEmpty
                          ? "Tidak ada hasil untuk '${provider.searchQuery}' dalam kategori '${provider.selectedCategory!.name}'"
                          : provider.selectedCategory != null
                          ? "Tidak ada resep dalam kategori '${provider.selectedCategory!.name}'"
                          : provider.searchQuery.isNotEmpty
                          ? "Tidak ada hasil untuk '${provider.searchQuery}'"
                          : "Tidak ada resep yang tersedia",
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = provider.recipes[index];
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
                          ).then((_) {
                            // Setelah kembali dari detail, refresh dengan mempertahankan pencarian dan kategori
                            if (provider.searchQuery.isNotEmpty) {
                              if (provider.selectedCategory != null) {
                                provider.getRecipesByCategoryFromApi(
                                  provider.selectedCategory!,
                                );
                              } else {
                                provider.searchRecipesFromApi(
                                  provider.searchQuery,
                                );
                              }
                            } else if (provider.selectedCategory != null) {
                              provider.getRecipesByCategoryFromApi(
                                provider.selectedCategory!,
                              );
                            } else {
                              provider.fetchRecipes();
                            }
                          });
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
            // Setelah tambah resep, refresh dengan mempertahankan pencarian dan kategori
            final provider = Provider.of<RecipeProvider>(
              context,
              listen: false,
            );
            if (provider.searchQuery.isNotEmpty) {
              if (provider.selectedCategory != null) {
                provider.getRecipesByCategoryFromApi(
                  provider.selectedCategory!,
                );
              } else {
                provider.searchRecipesFromApi(provider.searchQuery);
              }
            } else if (provider.selectedCategory != null) {
              provider.getRecipesByCategoryFromApi(provider.selectedCategory!);
            } else {
              provider.fetchRecipes();
            }
          });
        },
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Tambah Resep"),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
