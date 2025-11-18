import Foundation

/// Handles translation validation with fuzzy matching for Turkish language
class TranslationValidator {

    // MARK: - Properties

    /// Maximum allowed character differences based on word length
    private static func maxAllowedDifferences(for length: Int) -> Int {
        switch length {
        case 0...3: return 0  // Very short words: exact match
        case 4...6: return 1  // Short words: 1 difference allowed
        case 7...10: return 2 // Medium words: 2 differences allowed
        default: return 3     // Long words: 3 differences allowed
        }
    }

    // MARK: - Public Methods

    /// Validates user input against correct translation with fuzzy matching
    static func validate(
        userInput: String,
        correctTranslation: String
    ) -> ValidationResult {
        let cleanedInput = cleanTranslation(userInput)
        let cleanedCorrect = cleanTranslation(correctTranslation)

        // Check for exact match first
        if cleanedInput.lowercased() == cleanedCorrect.lowercased() {
            return ValidationResult(
                isCorrect: true,
                confidence: 1.0,
                feedback: .perfect
            )
        }

        // Check if input matches any of multiple correct translations
        let correctTranslations = cleanedCorrect.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        for translation in correctTranslations {
            if let result = validateAgainstSingleTranslation(userInput: cleanedInput, correctTranslation: translation) {
                return result
            }
        }

        return ValidationResult(
            isCorrect: false,
            confidence: 0.0,
            feedback: .incorrect
        )
    }

    // MARK: - Private Methods

    /// Normalizes translation text for comparison
    private static func cleanTranslation(_ text: String) -> String {
        return text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    /// Validates against a single translation option
    private static func validateAgainstSingleTranslation(
        userInput: String,
        correctTranslation: String
    ) -> ValidationResult? {
        let input = userInput.lowercased()
        let correct = correctTranslation.lowercased()

        // Calculate Levenshtein distance
        let distance = levenshteinDistance(input, correct)
        let maxDifferences = maxAllowedDifferences(for: correct.count)

        if distance <= maxDifferences {
            let confidence = 1.0 - (Double(distance) / Double(max(correct.count, 1)))

            return ValidationResult(
                isCorrect: true,
                confidence: confidence,
                feedback: confidence > 0.8 ? .minorTypo : .close
            )
        }

        // Check for phonetic similarities and common Turkish substitutions
        if hasPhoneticSimilarity(input: input, correct: correct) {
            return ValidationResult(
                isCorrect: true,
                confidence: 0.7,
                feedback: .phoneticSimilarity
            )
        }

        return nil
    }

    /// Calculates Levenshtein distance between two strings
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let s1Count = s1Array.count
        let s2Count = s2Array.count

        var matrix = Array(repeating: Array(repeating: 0, count: s2Count + 1), count: s1Count + 1)

        // Initialize first row and column
        for i in 0...s1Count {
            matrix[i][0] = i
        }
        for j in 0...s2Count {
            matrix[0][j] = j
        }

        // Fill the matrix
        for i in 1...s1Count {
            for j in 1...s2Count {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }

        return matrix[s1Count][s2Count]
    }

    /// Checks for phonetic similarity and common Turkish character substitutions
    private static func hasPhoneticSimilarity(input: String, correct: String) -> Bool {
        let commonSubstitutions: [Character: Character] = [
            "ı": "i", "i": "ı",
            "ş": "s", "s": "ş",
            "ç": "c", "c": "ç",
            "ğ": "g", "g": "ğ",
            "ö": "o", "o": "ö",
            "ü": "u", "u": "ü"
        ]

        // Apply substitutions and check if they match
        let normalizedInput = applyTurkishSubstitutions(input, substitutions: commonSubstitutions)
        let normalizedCorrect = applyTurkishSubstitutions(correct, substitutions: commonSubstitutions)

        // If normalized strings are close enough, consider them phonetically similar
        let distance = levenshteinDistance(normalizedInput, normalizedCorrect)
        let maxDistance = maxAllowedDifferences(for: normalizedCorrect.count) + 1

        return distance <= maxDistance
    }

    /// Applies Turkish character substitutions to a string
    private static func applyTurkishSubstitutions(
        _ text: String,
        substitutions: [Character: Character]
    ) -> String {
        var result = ""
        for char in text {
            if let substitution = substitutions[char] {
                result.append(substitution)
            } else {
                result.append(char)
            }
        }
        return result
    }
}

// MARK: - Supporting Types

/// Represents the result of translation validation
struct ValidationResult {
    let isCorrect: Bool
    let confidence: Double // 0.0 to 1.0
    let feedback: ValidationFeedback

    /// User-friendly message for the validation result
    var message: String {
        switch feedback {
        case .perfect:
            return "Perfect! 🎉"
        case .minorTypo:
            return "Good! Minor typo fixed ✏️"
        case .close:
            return "Very close! Keep going 🎯"
        case .phoneticSimilarity:
            return "Good pronunciation! 👍"
        case .incorrect:
            return "Not quite right. Let's review! 📚"
        }
    }
}

/// Types of validation feedback
enum ValidationFeedback {
    case perfect              // Exact match
    case minorTypo           // Very close, high confidence
    case close               // Close enough, medium confidence
    case phoneticSimilarity  // Phonetic similarity detected
    case incorrect          // No match found
}