import Foundation

enum QuestionType: String, Codable, CaseIterable {
    case single
    case multiple
    case truefalse

    var title: String {
        switch self {
        case .single:
            return "单选"
        case .multiple:
            return "多选"
        case .truefalse:
            return "判断"
        }
    }

    var symbolName: String {
        switch self {
        case .single:
            return "checkmark.circle"
        case .multiple:
            return "checklist"
        case .truefalse:
            return "arrow.left.arrow.right.circle"
        }
    }
}

struct Choice: Codable, Identifiable, Hashable {
    let key: String
    let text: String

    var id: String { key }
}

struct Question: Codable, Identifiable, Hashable {
    let id: String
    let number: Int
    let type: QuestionType
    let question: String
    let options: [Choice]
    let answer: [String]
}

struct QuestionBankMeta: Codable {
    let title: String
    let description: String
    let source: String
    let generatedAt: String
    let version: String
}

struct QuestionBankStats: Codable {
    let total: Int
    let single: Int
    let multiple: Int
    let truefalse: Int
}

struct QuestionBank: Codable {
    let meta: QuestionBankMeta
    let stats: QuestionBankStats
    let questions: [Question]
}
