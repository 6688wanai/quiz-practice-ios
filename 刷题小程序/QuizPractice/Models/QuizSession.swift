import Foundation

enum SessionMode: String, Codable {
    case regular
    case wrongBook

    var title: String {
        switch self {
        case .regular:
            return "随机练习"
        case .wrongBook:
            return "错题练习"
        }
    }
}

struct QuizSession: Codable, Identifiable {
    var id: UUID
    var questionIDs: [String]
    var answers: [String: [String]]
    var currentIndex: Int
    var startedAt: Date
    var mode: SessionMode

    init(questionIDs: [String], mode: SessionMode) {
        self.id = UUID()
        self.questionIDs = questionIDs
        self.answers = [:]
        self.currentIndex = 0
        self.startedAt = Date()
        self.mode = mode
    }
}

struct AnswerReview: Identifiable {
    let question: Question
    let selected: [String]
    let isCorrect: Bool

    var id: String { question.id }
    var isAnswered: Bool { !selected.isEmpty }
}

struct QuizResult: Identifiable {
    let id = UUID()
    let mode: SessionMode
    let total: Int
    let correct: Int
    let unanswered: Int
    let reviews: [AnswerReview]
    let completedAt: Date

    var wrong: Int {
        total - correct
    }

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    var wrongReviews: [AnswerReview] {
        reviews.filter { !$0.isCorrect }
    }
}
