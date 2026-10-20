import SwiftUI
import SwiftData

enum SidebarItem: Hashable {
    case allRecipes
    case groceryLists
}

struct LibraryView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @State private var showingAddSheet = false
    @State private var sidebarSelection: SidebarItem? = .allRecipes
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        }
        return recipes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.source?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $sidebarSelection) {
                Section("Collections") {
                    Label("All Recipes", systemImage: "book")
                        .badge(recipes.count)
                        .tag(SidebarItem.allRecipes)
                    Label("Favorites", systemImage: "star")
                    Label("Recently Used", systemImage: "clock")
                    Label("Grocery Lists", systemImage: "cart")
                        .tag(SidebarItem.groceryLists)
                }
            }
            .navigationTitle("My Recipe Book")
        } content: {
            switch sidebarSelection {
            case .groceryLists:
                GroceryListsView()
            case .allRecipes, .none:
                recipeGridContent
            }
        } detail: {
            Text("Select a recipe from the list")
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRecipeView()
                .presentationDetents([.large])
        }
    }
    
    private var recipeGridContent: some View {
        VStack {
            if recipes.isEmpty {
                ContentUnavailableView("No Recipes Yet",
                                     systemImage: "book",
                                     description: Text("Add your first recipe using the + button"))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 24) {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeCard(recipe: recipe)
                            }
                            .buttonStyle(PlainButtonStyle())   // Makes it look like a card
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("All Recipes (\(recipes.count))")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Recipe", systemImage: "plus")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes...")
    }
}

// MARK: - Recipe Card
struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .aspectRatio(16/9, contentMode: .fill)
                .overlay {
                    Text("📸")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                if let source = recipe.source {
                    Text(source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("\(recipe.servings) servings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let rating = recipe.rating {
                        Text("★".repeated(count: rating))
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension String {
    func repeated(count: Int) -> String {
        String(repeating: self, count: count)
    }
}
