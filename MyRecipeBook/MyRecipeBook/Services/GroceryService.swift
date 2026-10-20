import Foundation
import SwiftData

/// Single writer of grocery items from recipe ingredients.
///
/// View-independent: callers pass the ingredients, a scaling multiplier, the target list,
/// a source label, and the model context. `add` scales each amount, then merges into any
/// existing matching line, or appends a new item.
enum GroceryMerger {
    /// Adds `ingredients` (scaled by `multiplier`) into `list`, merging mergeable lines.
    static func add(ingredients: [Ingredient], scaledBy multiplier: Double, to list: GroceryList, source: String, in context: ModelContext) {
        for ingredient in ingredients {
            let scaledAmount: Double? = ingredient.amount.map { $0 * multiplier }
            let key = normalizationKey(name: ingredient.name, unit: ingredient.unit)
            let canonical = MeasurementConverter.canonicalUnit(for: ingredient.unit)

            // Attempt to merge into an existing line sharing the same normalization key,
            // but only when BOTH amounts are non-nil (no cross-unit / nil-amount arithmetic).
            if let scaledAmount,
               let existing = list.items.first(where: {
                   normalizationKey(name: $0.name, unit: $0.unit) == key && $0.amount != nil
               }) {
                existing.amount = (existing.amount ?? 0) + scaledAmount
                // Keep the existing item's original-cased name. If the incoming unit resolved to a
                // canonical unit, normalize the kept unit to its abbreviation; otherwise leave the
                // existing raw unit untouched.
                if let canonical {
                    existing.unit = canonical.displayAbbreviation
                }
                // Checked state is preserved on merge. Flag cross-recipe merges as 'Multiple'.
                if let existingSource = existing.recipeSource, existingSource != source {
                    existing.recipeSource = "Multiple"
                } else if existing.recipeSource == nil {
                    existing.recipeSource = source
                }
            } else {
                let item = GroceryItem(name: ingredient.name, amount: scaledAmount, unit: ingredient.unit, recipeSource: source)
                item.list = list
                list.items.append(item)
                context.insert(item)
            }
        }
    }

    /// Normalization key used for merge matching: (normalizedName, canonicalUnitOrRaw).
    ///
    /// normalizedName is trimmed, lowercased, with internal whitespace collapsed — NO stemming or
    /// pluralization, so 'tomato' != 'tomatoes'.
    ///
    /// AMENDMENT FINDING 3: raw (non-converter-recognized) units are matched byte-for-byte after
    /// lowercase/trim with NO singularization, so '1 clove' and '2 cloves' are DIFFERENT units and
    /// stay on separate lines. Only converter-recognized units normalize/merge across plural and
    /// abbreviation forms (via canonicalUnit's displayAbbreviation). Do NOT "fix" this to
    /// singularize raw units — that would over-merge distinct units.
    private static func normalizationKey(name: String, unit: String?) -> String {
        let normalizedName = name
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")

        let canonicalUnitOrRaw: String
        if let canonical = MeasurementConverter.canonicalUnit(for: unit) {
            canonicalUnitOrRaw = canonical.displayAbbreviation
        } else {
            canonicalUnitOrRaw = (unit ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        }

        return "\(normalizedName)|\(canonicalUnitOrRaw)"
    }
}
