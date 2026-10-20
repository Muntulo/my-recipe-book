import Foundation
import os

/// Rolled-up nutrition estimate for a recipe's full ingredient list (unscaled base totals).
struct NutritionEstimate {
    var totalKcal: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var matchedCount: Int
    var unmatchedNames: [String]

    var isEmpty: Bool { matchedCount == 0 }
}

/// Codable mirror of Resources/nutrition.json.
struct NutritionTable: Decodable {
    let version: Int
    let basisGrams: Double
    let entries: [NutritionEntry]
}

struct NutritionEntry: Decodable {
    let keys: [String]
    let kcal: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let gramsPerCup: Double?
    let mlDensity: Double?
    let gramsEach: Double?
}

/// On-device, best-effort nutrition estimation.
///
/// Mirrors `IngredientParser`/`MeasurementConverter` as an all-static `enum` namespace.
/// The per-100g table is loaded once from the bundle and matched against ingredient names
/// using a one-directional longest-key substring search. Grams are resolved via
/// `MeasurementConverter` plus the entry's density / gramsPerCup / gramsEach. Servings
/// scaling is intentionally NOT applied here — callers divide by their own serving count.
enum NutritionService {
    private static let logger = Logger(subsystem: "MyRecipeBook", category: "NutritionService")

    /// Loaded once, thread-safe via `let`. Nil if the resource is missing or fails to decode.
    private static let table: NutritionTable? = loadTable()

    private static func loadTable() -> NutritionTable? {
        guard let url = Bundle.main.url(forResource: "nutrition", withExtension: "json") else {
            logger.error("nutrition.json not found in bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(NutritionTable.self, from: data)
        } catch {
            logger.error("Failed to decode nutrition.json: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Estimates unscaled base totals for the given ingredients. If the table is unavailable
    /// every ingredient is reported unmatched and the estimate is empty.
    static func estimate(for ingredients: [Ingredient]) -> NutritionEstimate {
        guard let table else {
            return NutritionEstimate(
                totalKcal: 0,
                totalProtein: 0,
                totalCarbs: 0,
                totalFat: 0,
                matchedCount: 0,
                unmatchedNames: ingredients.map { $0.name }
            )
        }

        var totalKcal = 0.0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0
        var matchedCount = 0
        var unmatchedNames: [String] = []

        for ingredient in ingredients {
            // (1) MATCH
            guard let entry = matchEntry(for: ingredient.name, in: table) else {
                unmatchedNames.append(ingredient.name)
                continue
            }

            // (2) GRAMS
            guard let grams = grams(for: ingredient, using: entry) else {
                unmatchedNames.append(ingredient.name)
                continue
            }

            // (3) ACCUMULATE
            let factor = grams / table.basisGrams
            totalKcal += entry.kcal * factor
            totalProtein += entry.protein * factor
            totalCarbs += entry.carbs * factor
            totalFat += entry.fat * factor
            matchedCount += 1
        }

        return NutritionEstimate(
            totalKcal: totalKcal,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            matchedCount: matchedCount,
            unmatchedNames: unmatchedNames
        )
    }

    /// One-directional longest-key match: a key must be a substring of the (lowercased,
    /// trimmed) ingredient name — never the reverse. The winner is chosen by a total
    /// ordering: longest key first, then smallest start index in the name, then the
    /// lexicographically smallest key. An exact full-name match folds in as a longest key.
    private static func matchEntry(for name: String, in table: NutritionTable) -> NutritionEntry? {
        let haystack = name.lowercased().trimmingCharacters(in: .whitespaces)
        guard !haystack.isEmpty else { return nil }

        var best: (entry: NutritionEntry, key: String, start: Int)?

        for entry in table.entries {
            for key in entry.keys {
                guard let range = haystack.range(of: key) else { continue }
                let start = haystack.distance(from: haystack.startIndex, to: range.lowerBound)

                if let current = best {
                    if isBetter(candidateKey: key, candidateStart: start,
                                than: current.key, currentStart: current.start) {
                        best = (entry, key, start)
                    }
                } else {
                    best = (entry, key, start)
                }
            }
        }

        return best?.entry
    }

    /// Total-ordering tie-break: longer key wins; then smaller start index; then the
    /// lexicographically smaller key.
    private static func isBetter(candidateKey: String, candidateStart: Int,
                                 than currentKey: String, currentStart: Int) -> Bool {
        if candidateKey.count != currentKey.count {
            return candidateKey.count > currentKey.count
        }
        if candidateStart != currentStart {
            return candidateStart < currentStart
        }
        return candidateKey < currentKey
    }

    /// Resolves an ingredient's amount/unit to grams using the matched entry. Returns nil
    /// (unmatched) when the amount is missing or no density/count path applies.
    private static func grams(for ingredient: Ingredient, using entry: NutritionEntry) -> Double? {
        guard let amount = ingredient.amount else {
            return nil
        }

        if let canonical = MeasurementConverter.canonicalUnit(for: ingredient.unit) {
            switch canonical.dimension {
            case .mass:
                return amount * canonical.toBaseFactor
            case .volume:
                let milliliters = amount * canonical.toBaseFactor
                if let density = entry.mlDensity {
                    return milliliters * density
                } else if let gramsPerCup = entry.gramsPerCup {
                    return (milliliters / 236.5882365) * gramsPerCup
                } else {
                    return nil
                }
            }
        }

        // Unit did not resolve: fall back to a per-count weight if available ('3 eggs').
        if let gramsEach = entry.gramsEach {
            return amount * gramsEach
        }

        return nil
    }
}
