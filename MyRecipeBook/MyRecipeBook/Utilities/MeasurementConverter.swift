import Foundation

/// Stateless metric<->US conversion for mass and volume.
///
/// Mirrors `IngredientParser` as an all-static `enum` namespace. Given a scaled amount
/// and a raw unit token (as parsed by `IngredientParser`), it re-ladders through a base
/// unit (grams for mass, millilitres for volume) and picks a sensible display unit in the
/// requested system. Unknown units return nil so callers can fall back to original display.
enum MeasurementConverter {
    enum Dimension {
        case mass
        case volume
    }

    enum System {
        case metric
        case us
    }

    enum CanonicalUnit: String, CaseIterable {
        case gram
        case kilogram
        case ounce
        case pound
        case milliliter
        case liter
        case teaspoon
        case tablespoon
        case cup
        case fluidOunce
        case pint
        case quart
        case gallon

        var dimension: Dimension {
            switch self {
            case .gram, .kilogram, .ounce, .pound:
                return .mass
            default:
                return .volume
            }
        }

        var system: System {
            switch self {
            case .gram, .kilogram, .milliliter, .liter:
                return .metric
            default:
                return .us
            }
        }

        /// Factor to the dimension's base unit (grams for mass, millilitres for volume).
        var toBaseFactor: Double {
            switch self {
            case .gram: return 1.0
            case .kilogram: return 1000.0
            case .ounce: return 28.349523125
            case .pound: return 453.59237
            case .milliliter: return 1.0
            case .liter: return 1000.0
            case .teaspoon: return 4.92892159375
            case .tablespoon: return 14.78676478125
            case .cup: return 236.5882365
            case .fluidOunce: return 29.5735295625
            case .pint: return 473.176473
            case .quart: return 946.352946
            case .gallon: return 3785.411784
            }
        }

        var displayAbbreviation: String {
            switch self {
            case .gram: return "g"
            case .kilogram: return "kg"
            case .ounce: return "oz"
            case .pound: return "lb"
            case .milliliter: return "ml"
            case .liter: return "l"
            case .teaspoon: return "tsp"
            case .tablespoon: return "tbsp"
            case .cup: return "cup"
            case .fluidOunce: return "fl oz"
            case .pint: return "pt"
            case .quart: return "qt"
            case .gallon: return "gal"
            }
        }
    }

    /// Lowercased single-token synonyms. `'T'`/`'t'` are intentionally absent — they are
    /// handled case-sensitively in `canonicalUnit(for:)` before lowercasing.
    private static let synonyms: [String: CanonicalUnit] = [
        "g": .gram, "gram": .gram, "grams": .gram, "gr": .gram,
        "kg": .kilogram, "kilogram": .kilogram, "kilograms": .kilogram, "kilo": .kilogram,
        "oz": .ounce, "ounce": .ounce, "ounces": .ounce,
        "lb": .pound, "lbs": .pound, "pound": .pound, "pounds": .pound,
        "ml": .milliliter, "milliliter": .milliliter, "milliliters": .milliliter, "millilitre": .milliliter,
        "l": .liter, "liter": .liter, "liters": .liter, "litre": .liter,
        "tsp": .teaspoon, "teaspoon": .teaspoon, "teaspoons": .teaspoon,
        "tbsp": .tablespoon, "tbs": .tablespoon, "tablespoon": .tablespoon, "tablespoons": .tablespoon,
        "cup": .cup, "cups": .cup, "c": .cup,
        "fl": .fluidOunce, "floz": .fluidOunce, "fluidounce": .fluidOunce,
        "pt": .pint, "pint": .pint, "pints": .pint,
        "qt": .quart, "quart": .quart, "quarts": .quart,
        "gal": .gallon, "gallon": .gallon, "gallons": .gallon
    ]

    /// Resolves a raw unit token to a canonical unit, or nil if unrecognized.
    static func canonicalUnit(for raw: String?) -> CanonicalUnit? {
        guard let raw else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespaces)

        // Case-sensitive pre-map on the trimmed token (before lowercasing).
        let caseSensitive: [String: CanonicalUnit] = ["T": .tablespoon, "t": .teaspoon]
        if let unit = caseSensitive[trimmed] {
            return unit
        }

        var key = trimmed.lowercased()
        if key.hasSuffix(".") {
            key.removeLast()
        }

        if let unit = synonyms[key] {
            return unit
        }

        // Strip a single trailing 's' only if the stripped form is a known key.
        if key.hasSuffix("s") {
            let stripped = String(key.dropLast())
            if let unit = synonyms[stripped] {
                return unit
            }
        }

        return nil
    }

    /// Converts `amount` of `rawUnit` into the best display unit for `system` within the
    /// source unit's dimension. Returns the converted amount and its display abbreviation,
    /// or nil if the raw unit is unrecognized.
    static func convert(amount: Double, from rawUnit: String?, to system: System) -> (amount: Double, unit: String)? {
        guard let source = canonicalUnit(for: rawUnit) else {
            return nil
        }

        let base = amount * source.toBaseFactor

        let chosen: CanonicalUnit
        switch (source.dimension, system) {
        case (.mass, .metric):
            chosen = base < 1000.0 ? .gram : .kilogram
        case (.mass, .us):
            chosen = base < 453.59237 ? .ounce : .pound
        case (.volume, .metric):
            chosen = base < 1000.0 ? .milliliter : .liter
        case (.volume, .us):
            if base < 14.78676478125 {
                chosen = .teaspoon
            } else if base < 236.5882365 {
                chosen = .tablespoon
            } else if base < 946.352946 {
                chosen = .cup
            } else if base < 3785.411784 {
                chosen = .quart
            } else {
                chosen = .gallon
            }
        }

        return (base / chosen.toBaseFactor, chosen.displayAbbreviation)
    }
}
