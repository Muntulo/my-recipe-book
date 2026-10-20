import Foundation

/// Parses a raw ingredient line into a quantity, an optional unit, and the remaining name.
///
/// Supported quantity formats:
/// - Integer: "400"
/// - Decimal: "1.5"
/// - Simple fraction: "1/2"
/// - Mixed number: "1 1/2"
///
/// The first word after the quantity is treated as the unit only when a quantity was
/// found AND at least one more word remains for the name. Lines with no leading quantity
/// (e.g. "salt to taste") keep the whole line as the name with amount/unit nil.
enum IngredientParser {
    static func parse(_ line: String) -> (amount: Double?, unit: String?, name: String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var tokens = trimmed.split(separator: " ", omittingEmptySubsequences: true).map(String.init)

        guard !tokens.isEmpty else {
            return (nil, nil, trimmed)
        }

        guard let (amount, consumed) = leadingAmount(from: tokens) else {
            // No leading quantity: keep the whole line as the name.
            return (nil, nil, trimmed)
        }

        tokens.removeFirst(consumed)

        // Treat the next token as a unit only if there is still something left for the name.
        var unit: String? = nil
        if tokens.count >= 2 {
            unit = tokens.removeFirst()
        }

        let name = tokens.joined(separator: " ")
        return (amount, unit, name)
    }

    /// Attempts to read a leading quantity from the tokens.
    /// Returns the parsed amount and how many tokens it consumed, or nil if none was found.
    private static func leadingAmount(from tokens: [String]) -> (amount: Double, consumed: Int)? {
        guard let first = tokens.first, let firstValue = parseNumber(first) else {
            return nil
        }

        // Mixed number: integer followed by a fraction, e.g. "1 1/2".
        if tokens.count >= 2,
           isInteger(first),
           let fraction = parseFraction(tokens[1]) {
            return (firstValue + fraction, 2)
        }

        return (firstValue, 1)
    }

    /// Parses a token that is an integer, decimal, or simple fraction.
    private static func parseNumber(_ token: String) -> Double? {
        if let fraction = parseFraction(token) {
            return fraction
        }
        return Double(token)
    }

    /// Parses a simple fraction like "1/2". Returns nil if the token is not a fraction.
    private static func parseFraction(_ token: String) -> Double? {
        let parts = token.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator != 0 else {
            return nil
        }
        return numerator / denominator
    }

    private static func isInteger(_ token: String) -> Bool {
        Int(token) != nil
    }
}
