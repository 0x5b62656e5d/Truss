import SwiftUI

public struct SettingsPane: Identifiable {
    public let title: String
    public let systemImage: String
    public let color: Color
    public let group: String?
    let content: AnyView

    public var id: String { title }

    public init(
        _ title: String,
        systemImage: String,
        color: Color = .gray,
        group: String? = nil,
        @ViewBuilder content: () -> some View
    ) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.group = group
        self.content = AnyView(content())
    }
}
