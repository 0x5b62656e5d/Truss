import SwiftUI

@Observable
final class SettingsSelection {
    var title: String

    init(_ title: String) {
        self.title = title
    }
}

struct SettingsView: View {
    let panes: [SettingsPane]
    let selection: SettingsSelection

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            if let pane = panes.first(where: { $0.title == selection.title }) {
                detail(pane)
            } else {
                Spacer()
            }
        }
        .ignoresSafeArea()
    }

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(panes.indices, id: \.self) { index in
                    let pane = panes[index]
                    if let group = pane.group, index == 0 || panes[index - 1].group != group {
                        Text(group)
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                            .padding(.horizontal, 6)
                    }
                    row(pane)
                }
            }
            .padding(.top, 50)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.never)
        .frame(width: 220)
    }

    private func row(_ pane: SettingsPane) -> some View {
        Button {
            selection.title = pane.title
        } label: {
            HStack(spacing: 8) {
                PaneIcon(pane: pane, size: 28)
                Text(pane.title)
                Spacer()
            }
            .padding(5)
            .background {
                if pane.title == selection.title {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.quaternary)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private func detail(_ pane: SettingsPane) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                PaneIcon(pane: pane, size: 22)
                Text(pane.title).font(.title2)
                Spacer()
            }
            .padding(.horizontal, 11)
            .frame(height: 50)

            Divider()

            Form { pane.content }
                .formStyle(.grouped)
                .id(pane.id)
        }
    }
}

private struct PaneIcon: View {
    let pane: SettingsPane
    let size: CGFloat

    var body: some View {
        Image(systemName: pane.systemImage)
            .font(.system(size: size * 0.55, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(pane.color.gradient, in: .rect(cornerRadius: size * 0.25, style: .continuous))
    }
}
