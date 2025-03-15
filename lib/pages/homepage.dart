import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipeappfix_task5/controller/recipe_controller.dart';
import 'package:recipeappfix_task5/pages/add_recipe_page.dart';
import 'package:recipeappfix_task5/pages/detail_recipe_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String searchQuery = '';

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
        title: Text("Recipe App", style: TextStyle(color: Colors.white)),
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
                    // Add filter function here
                  },
                ),
              ],
            ),
          ),
          // ListView
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, recipeProvider, _) {
                if (recipeProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (recipeProvider.recipes.isEmpty) {
                  return Center(child: Text("No recipes found"));
                }
                
                final filteredRecipes = recipeProvider.recipes
                    .where((recipe) => recipe.title.toLowerCase().contains(searchQuery))
                    .toList();
                
                if (filteredRecipes.isEmpty) {
                  return Center(child: Text("No recipes match your search"));
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
                              builder: (context) => DetailRecipePage(recipe: recipe),
                            ),
                          );
                        },
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: Image.network(recipe.image, fit: BoxFit.cover),
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
                            ),
                            Text(
                              recipe.category.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
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
            MaterialPageRoute(
              builder: (context) => AddRecipePage(), // Navigate to add recipe page
            ),
          );
        },
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Tambah Resep"),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}