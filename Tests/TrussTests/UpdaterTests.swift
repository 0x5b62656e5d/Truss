import Foundation
import Testing
@testable import Truss

struct UpdaterTests {
    @Test func decodesRelease() throws {
        let json = """
        {
            "tag_name": "v1.2.3",
            "body": "Notes",
            "html_url": "https://github.com/owner/repo/releases/tag/v1.2.3",
            "assets": [{ "name": "App.zip", "browser_download_url": "https://github.com/owner/repo/releases/download/v1.2.3/App.zip" }]
        }
        """
        let release = try Release.decode(Data(json.utf8))

        #expect(release.version == "1.2.3")
        #expect(release.body == "Notes")
        #expect(release.htmlUrl.absoluteString == "https://github.com/owner/repo/releases/tag/v1.2.3")
        #expect(release.assets.first?.name == "App.zip")
        #expect(release.assets.first?.browserDownloadUrl.lastPathComponent == "App.zip")
    }

    @Test func comparesVersionsNumerically() {
        #expect(isNewer("1.10.0", than: "1.9.2"))
        #expect(!isNewer("1.9.2", than: "1.10.0"))
        #expect(!isNewer("1.2.3", than: "1.2.3"))
    }
}
