import SwiftUI
import SwiftData

@Model
class Recipe {
    var id: UUID
    var title: String
    var source: String?                    // e.g. "Bon Appétit May 2023" or "Handwritten"
    var cuisine: String?
    var prepTime: Int?                     // in minutes
    var cookTime: Int?
    var servings: Int
    var rating: Int?                       // 1-5 stars
    var notes: String?
    var createdAt: Date
    var lastUsed: Date?
    
    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient] = []
    
    @Relationship(deleteRule: .cascade)
    var instructions: [Instruction] = []
    
    @Relationship(deleteRule: .cascade)
    var photos: [Photo] = []
    
    @Relationship(deleteRule: .nullify)
    var tags: [Tag] = []
    
    init(title: String, servings: Int = 4) {
        self.id = UUID()
        self.title = title
        self.servings = servings
        self.createdAt = Date()
    }
}

@Model
class Ingredient {
    var name: String
    var amount: Double?
    var unit: String?
    var isOptional: Bool = false
    
    init(name: String, amount: Double? = nil, unit: String? = nil) {
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}

@Model
class Instruction {
    var stepNumber: Int
    var text: String
    
    init(stepNumber: Int, text: String) {
        self.stepNumber = stepNumber
        self.text = text
    }
}

@Model
class Photo {
    var id: UUID
    var imageData: Data?
    var type: String // "hero", "clipping", "step"
    
    init(type: String, imageData: Data? = nil) {
        self.id = UUID()
        self.type = type
        self.imageData = imageData
    }
}

@Model
class Tag {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
