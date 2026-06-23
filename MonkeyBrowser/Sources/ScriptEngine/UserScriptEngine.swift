import Foundation
import WebKit

// MARK: - Models

struct UserScript: Codable {
    let id: String
    var name: String
    var description: String
    var version: String
    var author: String
    var matches: [String]
    var excludeMatches: [String]
    var runAt: ScriptRunAt
    var code: String
    var isEnabled: Bool
    var installDate: Date

    enum ScriptRunAt: String, Codable {
        case documentStart = "document-start"
        case documentEnd = "document-end"
        case documentIdle = "document-idle"

        var wkTime: WKUserScriptInjectionTime {
            switch self {
            case .documentStart: return .atDocumentStart
            case .documentEnd, .documentIdle: return .atDocumentEnd
            }
        }
    }
}

// MARK: - UserScriptEngine

class UserScriptEngine {

    static let shared = UserScriptEngine()

    private var scripts: [UserScript] = []
    private let scriptsDirectory: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        scriptsDirectory = documents.appendingPathComponent("UserScripts", isDirectory: true)
        try? FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        loadAllScripts()
    }

    // MARK: - Public

    func loadAllScripts() {
        scripts.removeAll()
        let files = try? FileManager.default.contentsOfDirectory(
            at: scriptsDirectory,
            includingPropertiesForKeys: nil
        )
        for file in files ?? [] {
            if file.pathExtension == "user.js" {
                if let data = try? Data(contentsOf: file),
                   let script = try? JSONDecoder().decode(UserScript.self, from: data) {
                    scripts.append(script)
                }
            }
        }
    }

    func getScriptsForURL(_ url: URL?) -> [UserScript] {
        guard let url = url else { return [] }
        return scripts.filter { script in
            guard script.isEnabled else { return false }
            return script.matches.contains { pattern in
                matchPattern(pattern, url: url)
            }
        }
    }

    func installScript(_ code: String, metadata: UserScriptMetadata) {
        let script = UserScript(
            id: UUID().uuidString,
            name: metadata.name,
            description: metadata.description,
            version: metadata.version,
            author: metadata.author,
            matches: metadata.matches,
            excludeMatches: metadata.excludeMatches,
            runAt: .documentEnd,
            code: code,
            isEnabled: true,
            installDate: Date()
        )

        scripts.append(script)
        saveScript(script)
    }

    func removeScript(_ id: String) {
        scripts.removeAll { $0.id == id }
        let fileURL = scriptsDirectory.appendingPathComponent("\(id).user.js")
        try? FileManager.default.removeItem(at: fileURL)
    }

    func toggleScript(_ id: String, enabled: Bool) {
        if let index = scripts.firstIndex(where: { $0.id == id }) {
            scripts[index].isEnabled = enabled
            saveScript(scripts[index])
        }
    }

    func getAllScripts() -> [UserScript] {
        return scripts
    }

    // MARK: - Private

    private func saveScript(_ script: UserScript) {
        let fileURL = scriptsDirectory.appendingPathComponent("\(script.id).user.js")
        if let data = try? JSONEncoder().encode(script) {
            try? data.write(to: fileURL)
        }
    }

    private func matchPattern(_ pattern: String, url: URL) -> Bool {
        // Convert URL pattern to regex
        var regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")

        if regexPattern.hasPrefix(".*") {
            regexPattern = "https?://" + regexPattern
        }

        regexPattern = "^" + regexPattern + "$"

        guard let regex = try? NSRegularExpression(pattern: regexPattern) else { return false }
        let range = NSRange(url.absoluteString.startIndex..., in: url.absoluteString)
        return regex.firstMatch(in: url.absoluteString, range: range) != nil
    }
}

// MARK: - Metadata Parser

struct UserScriptMetadata {
    var name: String
    var description: String
    var version: String
    var author: String
    var matches: [String]
    var excludeMatches: [String]

    static func parse(from code: String) -> UserScriptMetadata {
        var name = "Untitled"
        var description = ""
        var version = "1.0"
        var author = ""
        var matches: [String] = []
        var excludeMatches: [String] = []

        let lines = code.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("// @name") {
                name = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("// @description") {
                description = String(trimmed.dropFirst(14)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("// @version") {
                version = String(trimmed.dropFirst(10)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("// @author") {
                author = String(trimmed.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("// @match") {
                let pattern = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                matches.append(pattern)
            } else if trimmed.hasPrefix("// @exclude") {
                let pattern = String(trimmed.dropFirst(10)).trimmingCharacters(in: .whitespaces)
                excludeMatches.append(pattern)
            }
        }

        return UserScriptMetadata(
            name: name,
            description: description,
            version: version,
            author: author,
            matches: matches,
            excludeMatches: excludeMatches
        )
    }
}
