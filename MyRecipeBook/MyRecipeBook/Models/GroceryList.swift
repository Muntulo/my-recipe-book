import SwiftUI
import SwiftData

@Model
class GroceryList {
    var id: UUID
    var name: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \GroceryItem.list)
    var items: [GroceryItem] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}

@Model
class GroceryItem {
    var id: UUID
    var name: String
    var amount: Double?
    var unit: String?
    var isChecked: Bool
    var recipeSource: String?
    var list: GroceryList?
    
    init(name: String, amount: Double? = nil, unit: String? = nil, recipeSource: String? = nil) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.unit = unit
        self.isChecked = false
        self.recipeSource = recipeSource
    }
}
