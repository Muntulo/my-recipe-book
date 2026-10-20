import SwiftUI
import SwiftData

struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var source = ""
    @State private var servings = 4
    @State private var notes = ""
    
    @State private var rawIngredientsText = ""   // Big text area for ingredients
    @State private var rawInstructionsText = ""  // Big text area for instructions
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Recipe Title *", text: $title)
                        .font(.headline)
                    
                    TextField("Source (e.g. Bon Appétit, Mom's Notebook)", text: $source)
                    
                    Stepper("\(servings) servings", value: $servings, in: 1...20)
                }
                
                Section("Ingredients (one per line)") {
                    TextEditor(text: $rawIngredientsText)
                        .frame(minHeight: 180)
                        .overlay(alignment: .topLeading) {
                            Text("Example:\n400 g spaghetti\n500 g shrimp\n4 tbsp butter")
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .opacity(rawIngredientsText.isEmpty ? 0.6 : 0)
                        }
                }
                
                Section("Instructions (one step per line)") {
                    TextEditor(text: $rawInstructionsText)
                        .frame(minHeight: 200)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveRecipe() {
        let newRecipe = Recipe(title: title, servings: servings)
        newRecipe.source = source.isEmpty ? nil : source
        newRecipe.notes = notes.isEmpty ? nil : notes
        
        // Parse ingredients (simple line-by-line)
        let ingredientLines = rawIngredientsText.components(separatedBy: .newlines)
        for line in ingredientLines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            let parsed = IngredientParser.parse(line)
            let ingredient = Ingredient(name: parsed.name, amount: parsed.amount, unit: parsed.unit)
            newRecipe.ingredients.append(ingredient)
        }
        
        // Parse instructions
        let instructionLines = rawInstructionsText.components(separatedBy: .newlines)
        for (index, text) in instructionLines.enumerated() where !text.trimmingCharacters(in: .whitespaces).isEmpty {
            let instruction = Instruction(stepNumber: index + 1, text: text.trimmingCharacters(in: .whitespaces))
            newRecipe.instructions.append(instruction)
        }
        
        modelContext.insert(newRecipe)
    }
}
