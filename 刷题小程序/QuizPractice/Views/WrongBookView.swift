import SwiftUI

struct WrongBookView: View {
    @EnvironmentObject private var store: QuizStore
    @State private var showPractice = false

    var body: some View {
        Group {
            if store.wrongQuestions.isEmpty {
                emptyState
            } else {
                List {
                    Section {
                        Button {
                            store.startWrongPractice()
                            showPractice = true
                        } label: {
                            Label("开始错题练习", systemImage: "play.fill")
                        }
                    }

                    Section {
                        ForEach(store.wrongQuestions) { question in
                            NavigationLink(destination: ReviewQuestionView(question: question, selected: [])) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("第 \(question.number) 题")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(question.type.title)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(question.question)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { offsets in
                            let questions = store.wrongQuestions
                            offsets.map { questions[$0] }.forEach(store.removeWrongQuestion)
                        }
                    }
                }
            }
        }
        .navigationTitle("错题本")
        .background(
            NavigationLink(isActive: $showPractice) {
                PracticeView()
            } label: {
                EmptyView()
            }
            .hidden()
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("暂无错题")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
