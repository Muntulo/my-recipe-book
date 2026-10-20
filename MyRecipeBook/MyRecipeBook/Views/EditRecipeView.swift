import SwiftUI
import SwiftData

struct EditRecipeView: View {
    @Bindable var recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    
    // Helper bindings for optionals
    private var sourceBinding: Binding<String> {
        Binding(
            get: { recipe.source ?? "" },
            set: { recipe.source = $0.isEmpty ? nil : $0 }
        )
    }
    
    private var notesBinding: Binding<String> {
        Binding(
            get: { recipe.notes ?? "" },
            set: { recipe.notes = $0.isEmpty ? nil : $0 }
        )
    }
    
    private var prepTimeBinding: Binding<Int> {
        Binding(
            get: { recipe.prepTime ?? 0 },
            set: { recipe.prepTime = $0 > 0 ? $0 : nil }
        )
    }
    
    private var cookTimeBinding: Binding<Int> {
        Binding(
            get: { recipe.cookTime ?? 0 },
            set: { recipe.cookTime = $0 > 0 ? $0 : nil }
        )
    }
    
    private var cuisineBinding: Binding<String> {
        Binding(
            get: { recipe.cuisine ?? "" },
            set: { recipe.cuisine = $0.isEmpty ? nil : $0 }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe Details") {
                    TextField("Title", text: $recipe.title)
                        .font(.headline)
                    
                    TextField("Source (Magazine, Handwritten, etc.)", text: sourceBinding)
                }
                
                Section("Timing & Servings") {
                    Stepper("\(recipe.servings) servings", value: $recipe.servings, in: 1...20)
                    
                    Stepper("Prep Time: \(recipe.prepTime ?? 0) min",
                           value: prepTimeBinding,
                           in: 0...300)
                    
                    Stepper("Cook Time: \(recipe.cookTime ?? 0) min",
                           value: cookTimeBinding,
                           in: 0...300)
                }
                
                Section("Details") {
                    TextField("Cuisine (e.g. Italian)", text: cuisineBinding)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= (recipe.rating ?? 0) ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                                .onTapGesture { recipe.rating = index }
                        }
                        Spacer()
                        Button("Clear") { recipe.rating = nil }
                            .buttonStyle(.borderless)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: notesBinding)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
