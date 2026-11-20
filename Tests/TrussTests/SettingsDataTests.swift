import Foundation
import Testing
@testable import Truss

struct SettingsDataTests {
    @Test func exportsAndImportsSettings() throws {
        let domain = "truss-tests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(domain).plist")
        defer {
            defaults.removePersistentDomain(forName: domain)
            try? FileManager.default.removeItem(at: file)
        }

        defaults.set(true, forKey: "flag")
        defaults.set("value", forKey: "text")
        try exportSettings(defaults, domain: domain, to: file)

        defaults.removePersistentDomain(forName: domain)
        defaults.set(42, forKey: "leftover")
        try importSettings(defaults, domain: domain, from: file)

        #expect(defaults.bool(forKey: "flag"))
        #expect(defaults.string(forKey: "text") == "value")
        #expect(defaults.object(forKey: "leftover") == nil)
    }
}
