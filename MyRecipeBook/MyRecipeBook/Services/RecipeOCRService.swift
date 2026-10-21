import Foundation
import Vision
import UIKit

/// Result of running on-device OCR over a recipe image.
///
/// `fullText` is every recognized line joined top-to-bottom in reading order.
/// `titleGuess`, `ingredientLines`, and `instructionLines` are a best-effort structuring
/// of that text for pre-filling the recipe form — the user reviews and edits everything.
struct OCRResult {
    let fullText: String
    let titleGuess: String
    let ingredientLines: [String]
    let instructionLines: [String]

    /// True when the image yielded any recognized text.
    var foundText: Bool { !fullText.isEmpty }

    /// An empty result: no CGImage, no text found, or a recognition failure.
    static let empty = OCRResult(fullText: "", titleGuess: "", ingredientLines: [], instructionLines: [])
}

/// On-device recipe OCR via the Vision framework. 100% local: no network, no cloud, no SDK.
///
/// `recognize(from:)` runs `VNRecognizeTextRequest` off the main thread and returns a value type
/// on the main actor. It never throws into the UI — any failure (no CGImage, no text, recognition
/// error) resolves to `OCRResult.empty` so the caller can show a message and still open a blank form.
enum RecipeOCRService {
    /// Runs Vision OCR on `image` off the main thread and returns the structured result.
    @MainActor
    static func recognize(from image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else { return .empty }

        let lines: [String] = await Task.detached(priority: .userInitiated) {
            recognizedLines(from: cgImage)
        }.value

        guard !lines.isEmpty else { return .empty }
        return structure(lines: lines)
    }

    // MARK: - Vision recognition (background)

    /// Performs the Vision request synchronously (call off the main thread) and returns the
    /// recognized lines sorted into top-to-bottom reading order. Returns `[]` on any failure.
    private static func recognizedLines(from cgImage: CGImage) -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let observations = request.results else { return [] }

        // Vision's coordinate origin is bottom-left, so a larger boundingBox.maxY is higher on
        // the page. Sort descending by top edge to reconstruct top-to-bottom reading order.
        let sorted = observations.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }

        return sorted.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    }

    // MARK: - Best-effort structuring

    /// Header keywords used to segment the recognized lines into ingredients vs. instructions.
    private static let ingredientsHeaders = ["ingredients"]
    private static let instructionsHeaders = ["method", "methods", "instructions", "directions", "steps", "preparation"]

    /// Structures recognized lines into (titleGuess, ingredientLines, instructionLines).
    ///
    /// Heuristic (deliberately simple):
    /// 1. First non-empty line is the title guess.
    /// 2. If an "Ingredients" header appears, lines after it are ingredients until an
    ///    instructions header ("Method"/"Instructions"/"Directions"/"Steps"/"Preparation"),
    ///    after which the rest are instructions.
    /// 3. Otherwise fall back: lines with a leading quantity (per IngredientParser) are
    ///    ingredients, the rest are instructions.
    private static func structure(lines: [String]) -> OCRResult {
        let fullText = lines.joined(separator: "\n")
        let titleGuess = lines.first ?? ""

        // Lines excluding the title guess are what we try to classify.
        let body = Array(lines.dropFirst())

        if let result = structureByHeaders(body: body, titleGuess: titleGuess, fullText: fullText) {
            return result
        }

        // Fallback: quantity-led lines are ingredients, everything else is an instruction.
        var ingredientLines: [String] = []
        var instructionLines: [String] = []
        for line in body {
            if IngredientParser.parse(line).amount != nil {
                ingredientLines.append(line)
            } else {
                instructionLines.append(line)
            }
        }

        return OCRResult(
            fullText: fullText,
            titleGuess: titleGuess,
            ingredientLines: ingredientLines,
            instructionLines: instructionLines
        )
    }

    /// Attempts header-driven segmentation. Returns nil when no "Ingredients" header is found.
    private static func structureByHeaders(body: [String], titleGuess: String, fullText: String) -> OCRResult? {
        guard let ingredientsIndex = body.firstIndex(where: { isHeader($0, in: ingredientsHeaders) }) else {
            return nil
        }

        // Find the first instructions header AFTER the ingredients header, if any.
        let afterIngredients = body.index(after: ingredientsIndex)
        let instructionsIndex = body[afterIngredients...].firstIndex(where: { isHeader($0, in: instructionsHeaders) })

        let ingredientSlice: ArraySlice<String>
        var instructionLines: [String] = []

        if let instructionsIndex {
            ingredientSlice = body[afterIngredients..<instructionsIndex]
            instructionLines = Array(body[body.index(after: instructionsIndex)...])
        } else {
            ingredientSlice = body[afterIngredients...]
        }

        let ingredientLines = ingredientSlice.filter { !isHeader($0, in: ingredientsHeaders) }

        return OCRResult(
            fullText: fullText,
            titleGuess: titleGuess,
            ingredientLines: Array(ingredientLines),
            instructionLines: instructionLines
        )
    }

    /// True when `line`, stripped of trailing punctuation and lowercased, matches a header keyword.
    private static func isHeader(_ line: String, in keywords: [String]) -> Bool {
        let normalized = line
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ":. "))
        return keywords.contains(normalized)
    }
}
