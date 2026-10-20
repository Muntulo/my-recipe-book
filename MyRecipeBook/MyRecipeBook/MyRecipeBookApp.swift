import SwiftUI
import SwiftData

@main
struct MyRecipeBookApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Recipe.self, Ingredient.self, Instruction.self, Photo.self, Tag.self, GroceryList.self, GroceryItem.self])
    }
}
