import Foundation

final class QuizStore: ObservableObject {
    let bank: QuestionBank

    @Published var session: QuizSession?
    @Published var lastResult: QuizResult?
    @Published private(set) var wrongIDs: Set<String>

    private let questionByID: [String: Question]
    private static let sessionKey = "quiz.session.v1"
    private static let wrongIDsKey = "quiz.wrong.ids.v1"
    private let sessionSize = 150

    init() {
        let loadedBank = QuestionBankLoader.load()
        self.bank = loadedBank
        self.questionByID = Dictionary(uniqueKeysWithValues: loadedBank.questions.map { ($0.id, $0) })
        self.wrongIDs = Self.loadWrongIDs(key: Self.wrongIDsKey)
        self.session = Self.loadSession(key: Self.sessionKey, validIDs: Set(loadedBank.questions.map(\.id)))
    }

    var hasSavedSession: Bool {
        session != nil
    }

    var wrongQuestions: [Question] {
        wrongIDs.compactMap { questionByID[$0] }.sorted { $0.number < $1.number }
    }

    func question(for id: String) -> Question? {
        questionByID[id]
    }

    func currentQuestion() -> Question? {
        guard let session, session.questionIDs.indices.contains(session.currentIndex) else {
            return nil
        }
        return questionByID[session.questionIDs[session.currentIndex]]
    }

    func selectedAnswers(for question: Question) -> [String] {
        session?.answers[question.id] ?? []
    }

    func isSelected(_ key: String, for question: Question) -> Bool {
        selectedAnswers(for: question).contains(key)
    }

    func startRegularPractice() {
        let ids = Array(bank.questions.shuffled().prefix(min(sessionSize, bank.questions.count)).map(\.id))
        session = QuizSession(questionIDs: ids, mode: .regular)
        lastResult = nil
        persistSession()
    }

    func startWrongPractice() {
        let pool = wrongQuestions
        let ids = Array(pool.shuffled().prefix(min(sessionSize, pool.count)).map(\.id))
        session = QuizSession(questionIDs: ids, mode: .wrongBook)
        lastResult = nil
        persistSession()
    }

    func resumeSavedPractice() {
        lastResult = nil
    }

    func choose(_ key: String, for question: Question) {
        guard var updated = session else { return }

        var selected = Set(updated.answers[question.id] ?? [])
        switch question.type {
        case .single, .truefalse:
            selected = [key]
        case .multiple:
            if selected.contains(key) {
                selected.remove(key)
            } else {
                selected.insert(key)
            }
        }

        updated.answers[question.id] = selected.sorted()
        session = updated
        persistSession()
    }

    func goPrevious() {
        guard var updated = session, updated.currentIndex > 0 else { return }
        updated.currentIndex -= 1
        session = updated
        persistSession()
    }

    func goNext() {
        guard var updated = session, updated.currentIndex + 1 < updated.questionIDs.count else { return }
        updated.currentIndex += 1
        session = updated
        persistSession()
    }

    func jump(to index: Int) {
        guard var updated = session, updated.questionIDs.indices.contains(index) else { return }
        updated.currentIndex = index
        session = updated
        persistSession()
    }

    func submitCurrentSession() -> QuizResult? {
        guard let current = session else { return nil }

        let reviews = current.questionIDs.compactMap { id -> AnswerReview? in
            guard let question = questionByID[id] else { return nil }
            let selected = current.answers[id] ?? []
            let isCorrect = Set(selected) == Set(question.answer)
            return AnswerReview(question: question, selected: selected.sorted(), isCorrect: isCorrect)
        }

        for review in reviews {
            if review.isCorrect {
                wrongIDs.remove(review.question.id)
            } else {
                wrongIDs.insert(review.question.id)
            }
        }

        let correct = reviews.filter(\.isCorrect).count
        let unanswered = reviews.filter { !$0.isAnswered }.count
        let result = QuizResult(
            mode: current.mode,
            total: reviews.count,
            correct: correct,
            unanswered: unanswered,
            reviews: reviews,
            completedAt: Date()
        )

        persistWrongIDs()
        clearSavedSession()
        session = nil
        lastResult = result
        return result
    }

    func discardSavedSession() {
        clearSavedSession()
        session = nil
        lastResult = nil
    }

    func removeWrongQuestion(_ question: Question) {
        wrongIDs.remove(question.id)
        persistWrongIDs()
    }

    func clearWrongBook() {
        wrongIDs.removeAll()
        persistWrongIDs()
    }

    private func persistSession() {
        guard let session else {
            clearSavedSession()
            return
        }

        do {
            let data = try JSONEncoder().encode(session)
            UserDefaults.standard.set(data, forKey: Self.sessionKey)
        } catch {
            assertionFailure("Failed to persist quiz session: \(error)")
        }
    }

    private func clearSavedSession() {
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
    }

    private func persistWrongIDs() {
        let values = wrongIDs.sorted()
        UserDefaults.standard.set(values, forKey: Self.wrongIDsKey)
    }

    private static func loadWrongIDs(key: String) -> Set<String> {
        let values = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(values)
    }

    private static func loadSession(key: String, validIDs: Set<String>) -> QuizSession? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        do {
            var decoded = try JSONDecoder().decode(QuizSession.self, from: data)
            decoded.questionIDs = decoded.questionIDs.filter { validIDs.contains($0) }
            if decoded.questionIDs.isEmpty {
                UserDefaults.standard.removeObject(forKey: key)
                return nil
            }
            decoded.currentIndex = min(decoded.currentIndex, decoded.questionIDs.count - 1)
            return decoded
        } catch {
            UserDefaults.standard.removeObject(forKey: key)
            return nil
        }
    }
}
