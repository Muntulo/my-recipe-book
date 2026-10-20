import Foundation

/// Formats a scaled amount so integers show without decimals ("2") and non-integers
/// show a reasonable precision trimmed of trailing zeros ("1.5", "0.75").
enum AmountFormatter {
    static func string(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
