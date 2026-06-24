import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: QuizStore
    @State private var showPractice = false
    @State private var showWrongPractice = false
    @State private var showDiscardAlert = false
    @State private var showClearWrongAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statsGrid
                actionPanel
                savedSessionPanel
                wrongBookPanel
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("刷题练习")
        .background(navigationLinks)
        .alert("放弃当前练习？", isPresented: $showDiscardAlert) {
            Button("取消", role: .cancel) {}
            Button("放弃", role: .destructive) {
                store.discardSavedSession()
            }
        }
        .alert("清空错题本？", isPresented: $showClearWrongAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                store.clearWrongBook()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.bank.meta.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.primary)
            Text("每次随机 150 题")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "总题数", value: "\(store.bank.stats.total)", color: .blue, symbolName: "square.stack.3d.up")
            StatCard(title: "错题", value: "\(store.wrongIDs.count)", color: .red, symbolName: "exclamationmark.circle")
            StatCard(title: "单选", value: "\(store.bank.stats.single)", color: .green, symbolName: "checkmark.circle")
            StatCard(title: "多选/判断", value: "\(store.bank.stats.multiple + store.bank.stats.truefalse)", color: .orange, symbolName: "checklist")
        }
    }

    private var actionPanel: some View {
        VStack(spacing: 12) {
            Button {
                store.startRegularPractice()
                showPractice = true
            } label: {
                ActionLabel(title: "开始 150 题", symbolName: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue))

            Button {
                store.startWrongPractice()
                showWrongPractice = true
            } label: {
                ActionLabel(title: "错题练习", symbolName: "tray.full.fill")
            }
            .buttonStyle(PrimaryButtonStyle(color: .red))
            .disabled(store.wrongIDs.isEmpty)
            .opacity(store.wrongIDs.isEmpty ? 0.45 : 1)
        }
    }

    @ViewBuilder
    private var savedSessionPanel: some View {
        if store.hasSavedSession {
            VStack(alignment: .leading, spacing: 12) {
                Text("未完成练习")
                    .font(.headline)

                if let session = store.session {
                    Text("\(session.mode.title) · \(session.currentIndex + 1) / \(session.questionIDs.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 10) {
                    Button {
                        store.resumeSavedPractice()
                        showPractice = true
                    } label: {
                        Label("继续", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle(tint: .blue))

                    Button {
                        showDiscardAlert = true
                    } label: {
                        Label("放弃", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle(tint: .red))
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
    }

    private var wrongBookPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("错题本")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: WrongBookView()) {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .disabled(store.wrongIDs.isEmpty)
            }

            Text(store.wrongIDs.isEmpty ? "暂无错题" : "已收录 \(store.wrongIDs.count) 道")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !store.wrongIDs.isEmpty {
                Button {
                    showClearWrongAlert = true
                } label: {
                    Label("清空错题", systemImage: "xmark.bin")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle(tint: .red))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }

    private var navigationLinks: some View {
        Group {
            NavigationLink(isActive: $showPractice) {
                PracticeView()
            } label: {
                EmptyView()
            }
            NavigationLink(isActive: $showWrongPractice) {
                PracticeView()
            } label: {
                EmptyView()
            }
        }
        .hidden()
    }
}
