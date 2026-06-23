import Foundation

struct BrowserTab: Identifiable {
    let id: String
    var title: String
    var url: URL?
    var favicon: Data?
    var lastAccessed: Date

    init(id: String = UUID().uuidString, title: String = "New Tab", url: URL? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.lastAccessed = Date()
    }
}

struct Bookmark: Codable {
    let id: String
    var title: String
    var url: URL
    var favicon: Data?
    var folder: String?
    var createdDate: Date

    init(id: String = UUID().uuidString, title: String, url: URL, folder: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.folder = folder
        self.createdDate = Date()
    }
}

struct DownloadItem: Identifiable {
    let id: String
    var filename: String
    var url: URL
    var localURL: URL?
    var progress: Float
    var totalBytes: Int64
    var receivedBytes: Int64
    var state: DownloadState

    enum DownloadState {
        case waiting
        case downloading
        case paused
        case completed
        case failed
    }
}
