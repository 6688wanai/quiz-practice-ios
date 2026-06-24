import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var store: QuizStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var showSubmitAlert = false
    @State private var result: QuizResult?

    var body: some View {
        Group {
            if let result {
                ResultView(
                    result: result,
                    onRestart: {
                        store.startRegularPractice()
                        self.result = nil
                    },
                    onWrongPractice: {
                        store.startWrongPractice()
                        self.result = nil
                    }
                )
            } else if let session = store.session, let question = store.currentQuestion() {
                practiceContent(session: session, question: question)
            } else {
                emptyState
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func practiceContent(session: QuizSession, question: Question) -> some View {
        VStack(spacing: 0) {
            progressHeader(session: session, question: question)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(question.question)
                        .font(.system(size: 22, weight: .semibold))
                        .lineSpacing(5)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 10) {
                        ForEach(question.options) { option in
                            OptionRow(
                                option: option,
                                isSelected: store.isSelected(option.key, for: question),
                                isMultiple: question.type == .multiple
                            )
                            .onTapGesture {
                                store.choose(option.key, for: question)
                            }
                        }
                    }
                }
                .padding(20)
            }

            bottomBar(session: session)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.mode.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSubmitAlert = true
                } label: {
                    Image(systemName: "checkmark.seal.fill")
                }
            }
        }
        .alert("确认交卷？", isPresented: $showSubmitAlert) {
            Button("取消", role: .cancel) {}
            Button("交卷") {
                result = store.submitCurrentSession()
            }
        }
    }

    private func progressHeader(session: QuizSession, question: Question) -> some View {
        VStack(spacing: 10) {
            HStack {
                Label(question.type.title, systemImage: question.type.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.blue)

                Spacer()

                Text("\(session.currentIndex + 1) / \(session.questionIDs.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(session.currentIndex + 1), total: Double(session.questionIDs.count))
                .accentColor(.blue)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func bottomBar(session: QuizSession) -> some View {
        HStack(spacing: 12) {
            Button {
                store.goPrevious()
            } label: {
                Label("上一题", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle(tint: .blue))
            .disabled(session.currentIndex == 0)

            Button {
                if session.currentIndex + 1 == session.questionIDs.count {
                    showSubmitAlert = true
                } else {
                    store.goNext()
                }
            } label: {
                Label(session.currentIndex + 1 == session.questionIDs.count ? "交卷" : "下一题", systemImage: session.currentIndex + 1 == session.questionIDs.count ? "checkmark.seal" : "chevron.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: session.currentIndex + 1 == session.questionIDs.count ? .green : .blue))
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("返回首页", systemImage: "house")
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue))
            .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
