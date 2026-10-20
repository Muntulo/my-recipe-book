import SwiftUI
import SwiftData

enum UnitDisplay {
    case original
    case metric
    case us
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var servingsMultiplier: Double = 1.0
    @State private var unitSystem: UnitDisplay = .original
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddToGroceryList = false
    
    var scaledServings: Int {
        max(1, Int((Double(recipe.servings) * servingsMultiplier).rounded()))
    }
    
    var body: some View {
        let estimate = NutritionService.estimate(for: recipe.ingredients)

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Hero Header
                ZStack {
                    Rectangle()
                        .fill(.gray.opacity(0.25))
                        .frame(height: 280)
                        .overlay {
                            Text("📸")
                                .font(.system(size: 80))
                                .foregroundStyle(.secondary)
                        }
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text(recipe.title)
                        .font(.system(size: 34, weight: .bold))
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        if let source = recipe.source {
                            Label(source, systemImage: "book.pages")
                        }
                        Label("\(scaledServings) servings", systemImage: "person.2")
                    }
                    .foregroundStyle(.secondary)
                    .font(.title3)
                    
                    if recipe.prepTime != nil || recipe.cookTime != nil {
                        HStack(spacing: 16) {
                            if let prepTime = recipe.prepTime {
                                Label("\(prepTime) min prep", systemImage: "timer")
                            }
                            if let cookTime = recipe.cookTime {
                                Label("\(cookTime) min cook", systemImage: "flame")
                            }
                        }
                        .foregroundStyle(.secondary)
                        .font(.title3)
                    }
                    
                    if let cuisine = recipe.cuisine {
                        Label(cuisine, systemImage: "fork.knife")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    
                    if let rating = recipe.rating {
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= rating ? "star.fill" : "star")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .font(.title3)
                    }
                }
                .padding(.horizontal)
                
                // Scaling Control
                VStack(spacing: 8) {
                    Text("Servings")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        Button(action: { if servingsMultiplier > 0.25 { servingsMultiplier -= 0.25 } }) {
                            Text("–").font(.title2).frame(width: 44, height: 44)
                        }
                        .buttonStyle(.bordered)
                        
                        Text("\(scaledServings)")
                            .font(.title)
                            .fontWeight(.semibold)
                            .frame(width: 60)
                        
                        Button(action: { if servingsMultiplier < 4 { servingsMultiplier += 0.25 } }) {
                            Text("+").font(.title2).frame(width: 44, height: 44)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                
                // Ingredients (with scaling)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Ingredients")
                        .font(.title2).bold()
                    
                    Picker("Units", selection: $unitSystem) {
                        Text("Original").tag(UnitDisplay.original)
                        Text("Metric").tag(UnitDisplay.metric)
                        Text("US").tag(UnitDisplay.us)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    ForEach(recipe.ingredients) { ingredient in
                        HStack(alignment: .top) {
                            Text("•").foregroundStyle(.secondary)
                            Text(scaledIngredientText(ingredient))
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Instructions
                VStack(alignment: .leading, spacing: 18) {
                    Text("Instructions")
                        .font(.title2).bold()
                    
                    ForEach(recipe.instructions.sorted(by: { $0.stepNumber < $1.stepNumber })) { step in
                        HStack(alignment: .top, spacing: 16) {
                            Text("\(step.stepNumber)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .trailing)
                            Text(step.text)
                                .font(.title3)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Nutrition (estimated, on-device)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Nutrition")
                            .font(.title2).bold()
                        Text("Estimated")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if estimate.isEmpty {
                        Text("Not enough data to estimate")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    } else {
                        let perServingKcal = estimate.totalKcal / Double(scaledServings)
                        let perServingProtein = estimate.totalProtein / Double(scaledServings)
                        let perServingCarbs = estimate.totalCarbs / Double(scaledServings)
                        let perServingFat = estimate.totalFat / Double(scaledServings)
                        
                        Text("\(Int(perServingKcal.rounded())) kcal · \(AmountFormatter.string((perServingProtein * 10).rounded() / 10))g protein · \(AmountFormatter.string((perServingCarbs * 10).rounded() / 10))g carbs · \(AmountFormatter.string((perServingFat * 10).rounded() / 10))g fat")
                            .font(.body)
                        Text("per serving")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Total: \(Int(estimate.totalKcal.rounded())) kcal · \(AmountFormatter.string((estimate.totalProtein * 10).rounded() / 10))g protein · \(AmountFormatter.string((estimate.totalCarbs * 10).rounded() / 10))g carbs · \(AmountFormatter.string((estimate.totalFat * 10).rounded() / 10))g fat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !estimate.unmatchedNames.isEmpty {
                            Text("\(estimate.unmatchedNames.count) ingredient(s) not counted")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                if let notes = recipe.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.title2).bold()
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Add to Grocery List") { showingAddToGroceryList = true }
                    Button("Edit Recipe") { showingEditSheet = true }
                    Button("Delete Recipe", role: .destructive) { showingDeleteAlert = true }
                } label: {
                    Label("Options", systemImage: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecipeView(recipe: recipe)
        }
        .sheet(isPresented: $showingAddToGroceryList) {
            AddToGroceryListSheet(recipe: recipe, servingsMultiplier: servingsMultiplier)
        }
        .alert("Delete Recipe?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func deleteRecipe() {
        modelContext.delete(recipe)
        dismiss()
    }
    
    private func scaledIngredientText(_ ingredient: Ingredient) -> String {
        guard let amount = ingredient.amount else {
            return ingredient.name
        }
        
        let scaledAmount = amount * servingsMultiplier
        
        let displayAmount: Double
        let displayUnit: String
        
        switch unitSystem {
        case .original:
            displayAmount = scaledAmount
            displayUnit = ingredient.unit ?? ""
        case .metric, .us:
            let targetSystem: MeasurementConverter.System = (unitSystem == .metric) ? .metric : .us
            if let converted = MeasurementConverter.convert(amount: scaledAmount, from: ingredient.unit, to: targetSystem) {
                displayAmount = converted.amount
                displayUnit = converted.unit
            } else {
                displayAmount = scaledAmount
                displayUnit = ingredient.unit ?? ""
            }
        }
        
        let formattedAmount = AmountFormatter.string(displayAmount)
        return "\(formattedAmount) \(displayUnit) \(ingredient.name)".trimmingCharacters(in: .whitespaces)
    }
}
