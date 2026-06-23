import Foundation

class ScriptImporter {

    static func importFromURL(_ urlString: String, completion: @escaping (Result<UserScript, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(ScriptError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let code = String(data: data, encoding: .utf8) else {
                completion(.failure(ScriptError.invalidData))
                return
            }

            let metadata = UserScriptMetadata.parse(from: code)
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

            completion(.success(script))
        }
        task.resume()
    }

    static func importFromFile(_ url: URL) -> UserScript? {
        guard let code = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let metadata = UserScriptMetadata.parse(from: code)
        return UserScript(
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
    }

    enum ScriptError: LocalizedError {
        case invalidURL
        case invalidData
        case parseError

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的URL"
            case .invalidData: return "无效的数据"
            case .parseError: return "解析错误"
            }
        }
    }
}
