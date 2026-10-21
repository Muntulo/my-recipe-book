import SwiftUI
import SwiftData
import PhotosUI
import UIKit

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
    
    // MARK: Scan / Import from Photo
    @State private var showingImportDialog = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var showingScanner = false
    @State private var isProcessingImage = false
    @State private var importResult: OCRResult?
    @State private var importImage: UIImage?
    @State private var showingImportSheet = false
    @State private var showingNoTextAlert = false
    
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
        .confirmationDialog("Import Recipe from Photo", isPresented: $showingImportDialog, titleVisibility: .visible) {
            Button("Photo Library") { showingPhotoPicker = true }
            if DocumentScannerView.isAvailable {
                Button("Scan Document") { showingScanner = true }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadPickedPhoto(newItem) }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            DocumentScannerView(
                onScan: { image in
                    showingScanner = false
                    Task { await runOCR(on: image) }
                },
                onCancel: { showingScanner = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingImportSheet) {
            AddRecipeView(
                title: importResult?.titleGuess ?? "",
                rawIngredientsText: importResult?.ingredientLines.joined(separator: "\n") ?? "",
                rawInstructionsText: importResult?.instructionLines.joined(separator: "\n") ?? "",
                clippingImage: importImage
            )
            .presentationDetents([.large])
        }
        .overlay {
            if isProcessingImage {
                ProgressView("Reading recipe…")
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .alert("No text recognized", isPresented: $showingNoTextAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Couldn't read any text from that image. The form opened blank — you can type the recipe in or attach the photo and try another.")
        }
    }
    
    // MARK: - Import orchestration
    
    private func loadPickedPhoto(_ item: PhotosPickerItem) async {
        photoPickerItem = nil
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }
        await runOCR(on: image)
    }
    
    private func runOCR(on image: UIImage) async {
        isProcessingImage = true
        let result = await RecipeOCRService.recognize(from: image)
        isProcessingImage = false
        
        importImage = image
        importResult = result
        showingImportSheet = true
        if !result.foundText {
            showingNoTextAlert = true
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
                Button(action: { showingImportDialog = true }) {
                    Label("Scan Recipe", systemImage: "doc.viewfinder")
                }
            }
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
