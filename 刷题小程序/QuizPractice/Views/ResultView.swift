import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var store: QuizStore
    let result: QuizResult
    let onRestart: () -> Void
    let onWrongPractice: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                scorePanel
                actionPanel
                reviewList
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("练习结果")
        .navigationBarBackButtonHidden(false)
    }

    private var scorePanel: some View {
        VStack(spacing: 14) {
            Text("\(Int(result.accuracy * 100))%")
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .foregroundColor(result.accuracy >= 0.8 ? .green : .orange)

            Text("\(result.correct) / \(result.total)")
                .font(.title3.monospacedDigit())
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                StatCard(title: "错误", value: "\(result.wrong)", color: .red, symbolName: "xmark.circle")
                StatCard(title: "未答", value: "\(result.unanswered)", color: .orange, symbolName: "minus.circle")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    private var actionPanel: some View {
        VStack(spacing: 12) {
            Button(action: onRestart) {
                ActionLabel(title: "再练 150 题", symbolName: "arrow.clockwise")
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue))

            Button(action: onWrongPractice) {
                ActionLabel(title: "练习错题", symbolName: "tray.full.fill")
            }
            .buttonStyle(PrimaryButtonStyle(color: .red))
            .disabled(store.wrongIDs.isEmpty)
            .opacity(store.wrongIDs.isEmpty ? 0.45 : 1)
        }
    }

    private var reviewList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("答题明细")
                .font(.headline)

            ForEach(result.reviews) { review in
                NavigationLink(destination: ReviewQuestionView(question: review.question, selected: review.selected)) {
                    HStack(spacing: 12) {
                        Image(systemName: review.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(review.isCorrect ? .green : .red)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("第 \(review.question.number) 题")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text(review.question.type.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
}
