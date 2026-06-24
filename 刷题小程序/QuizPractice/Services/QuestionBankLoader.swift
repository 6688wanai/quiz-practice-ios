import Foundation

enum QuestionBankLoader {
    static func load() -> QuestionBank {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            fatalError("questions.json was not found in the app bundle.")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(QuestionBank.self, from: data)
        } catch {
            fatalError("Failed to load questions.json: \(error)")
        }
    }
}
