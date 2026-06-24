import SwiftUI

struct ReviewQuestionView: View {
    let question: Question
    let selected: [String]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label(question.type.title, systemImage: question.type.symbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)
                    Spacer()
                    Text("第 \(question.number) 题")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                }

                Text(question.question)
                    .font(.system(size: 22, weight: .semibold))
                    .lineSpacing(5)

                VStack(spacing: 10) {
                    ForEach(question.options) { option in
                        ReviewOptionRow(
                            option: option,
                            isSelected: selected.contains(option.key),
                            isAnswer: question.answer.contains(option.key)
                        )
                    }
                }

                answerSummary
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("题目回看")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var answerSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("正确答案")
                .font(.headline)
            Text(question.answer.joined(separator: "、"))
                .font(.system(.title3, design: .monospaced))
                .foregroundColor(.green)

            if !selected.isEmpty {
                Text("你的答案")
                    .font(.headline)
                    .padding(.top, 6)
                Text(selected.joined(separator: "、"))
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(Set(selected) == Set(question.answer) ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}
