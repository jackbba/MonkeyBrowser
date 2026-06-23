import Foundation

struct SubtitleEntry: Codable {
    let startTime: Double
    let endTime: Double
    let text: String
}

class SubtitleManager {

    static let shared = SubtitleManager()

    private var subtitles: [SubtitleEntry] = []
    private var customSubtitleDirectory: URL
    private var onSubtitlesUpdated: (() -> Void)?

    var subtitlesDidChange: (() -> Void)? {
        get { return onSubtitlesUpdated }
        set { onSubtitlesUpdated = newValue }
    }

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        customSubtitleDirectory = documents.appendingPathComponent("Subtitles", isDirectory: true)
        try? FileManager.default.createDirectory(at: customSubtitleDirectory, withIntermediateDirectories: true)
    }

    // MARK: - 从脚本桥接添加字幕

    func addSubtitleFromBridge(_ data: SubtitleBridge.SubtitleData) {
        let parsed = parseSubtitleContent(data.content, format: data.format)
        subtitles.append(contentsOf: parsed)
        subtitles.sort { $0.startTime < $1.startTime }
        onSubtitlesUpdated?()
        print("[SubtitleManager] Added \(parsed.count) subtitles from bridge (format: \(data.format))")
    }

    func setSubtitleFromBridge(_ data: SubtitleBridge.SubtitleData) {
        subtitles.removeAll()
        addSubtitleFromBridge(data)
    }

    // MARK: - Load Subtitles

    func loadSubtitles(from url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        let ext = url.pathExtension.lowercased()
        let format: String
        switch ext {
        case "srt": format = "srt"
        case "vtt": format = "vtt"
        case "ass", "ssa": format = "ass"
        default: format = "srt"
        }
        let parsed = parseSubtitleContent(content, format: format)
        subtitles.append(contentsOf: parsed)
        subtitles.sort { $0.startTime < $1.startTime }
        onSubtitlesUpdated?()
    }

    func loadCustomSubtitles() {
        let files = try? FileManager.default.contentsOfDirectory(
            at: customSubtitleDirectory,
            includingPropertiesForKeys: nil
        )
        for file in files ?? [] {
            let ext = file.pathExtension.lowercased()
            if ["srt", "vtt", "ass", "ssa"].contains(ext) {
                loadSubtitles(from: file)
            }
        }
    }

    // MARK: - 解析字幕内容

    func parseSubtitleContent(_ content: String, format: String) -> [SubtitleEntry] {
        switch format {
        case "srt":
            return parseSRT(content)
        case "vtt":
            return parseVTT(content)
        case "ass", "ssa":
            return parseASS(content)
        default:
            return parseSRT(content)
        }
    }

    // MARK: - Get Subtitle

    func getSubtitle(forTime time: Double) -> String? {
        return subtitles.first { entry in
            time >= entry.startTime && time <= entry.endTime
        }?.text
    }

    func getAllSubtitles() -> [SubtitleEntry] {
        return subtitles
    }

    func clearSubtitles() {
        subtitles.removeAll()
        onSubtitlesUpdated?()
    }

    // MARK: - Parse SRT

    private func parseSRT(_ content: String) -> [SubtitleEntry] {
        var entries: [SubtitleEntry] = []
        let blocks = content.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: "\n")
            guard lines.count >= 3 else { continue }

            let timeLine = lines[1]
            let timeParts = timeLine.components(separatedBy: " --> ")
            guard timeParts.count == 2 else { continue }

            let startTime = parseTimeSRT(timeParts[0])
            let endTime = parseTimeSRT(timeParts[1])
            let text = lines[2...].joined(separator: "\n")

            entries.append(SubtitleEntry(startTime: startTime, endTime: endTime, text: text))
        }
        return entries
    }

    private func parseTimeSRT(_ timeStr: String) -> Double {
        let parts = timeStr
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: ":")

        guard parts.count == 3 else { return 0 }
        let hours = Double(parts[0]) ?? 0
        let minutes = Double(parts[1]) ?? 0
        let seconds = Double(parts[2]) ?? 0

        return hours * 3600 + minutes * 60 + seconds
    }

    // MARK: - Parse VTT

    private func parseVTT(_ content: String) -> [SubtitleEntry] {
        var entries: [SubtitleEntry] = []
        let lines = content.components(separatedBy: .newlines)
        var index = 0

        while index < lines.count && !lines[index].contains("-->") {
            index += 1
        }

        while index < lines.count {
            let line = lines[index]
            if line.contains("-->") {
                let timeParts = line.components(separatedBy: " --> ")
                guard timeParts.count == 2 else { index += 1; continue }

                let startTime = parseTimeVTT(timeParts[0])
                let endTime = parseTimeVTT(timeParts[1])

                index += 1
                var text = ""
                while index < lines.count && !lines[index].isEmpty {
                    if !text.isEmpty { text += "\n" }
                    text += lines[index]
                    index += 1
                }

                entries.append(SubtitleEntry(startTime: startTime, endTime: endTime, text: text))
            }
            index += 1
        }
        return entries
    }

    private func parseTimeVTT(_ timeStr: String) -> Double {
        let parts = timeStr
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: ":")

        guard parts.count == 3 else { return 0 }
        let hours = Double(parts[0]) ?? 0
        let minutes = Double(parts[1]) ?? 0
        let seconds = Double(parts[2]) ?? 0

        return hours * 3600 + minutes * 60 + seconds
    }

    // MARK: - Parse ASS/SSA

    private func parseASS(_ content: String) -> [SubtitleEntry] {
        var entries: [SubtitleEntry] = []
        let lines = content.components(separatedBy: .newlines)
        var inEvents = false

        for line in lines {
            if line.hasPrefix("[Events]") {
                inEvents = true
                continue
            }
            if line.hasPrefix("[") {
                inEvents = false
                continue
            }

            if inEvents && line.hasPrefix("Dialogue:") {
                let parts = line.components(separatedBy: ",")
                guard parts.count >= 10 else { continue }

                let startTime = parseTimeASS(parts[1])
                let endTime = parseTimeASS(parts[2])
                let text = parts[9]
                    .replacingOccurrences(of: "\\N", with: "\n")
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "{\\[^}]*}", with: "", options: .regularExpression)

                entries.append(SubtitleEntry(startTime: startTime, endTime: endTime, text: text))
            }
        }
        return entries
    }

    private func parseTimeASS(_ timeStr: String) -> Double {
        let parts = timeStr.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
        guard parts.count == 3 else { return 0 }

        let hours = Double(parts[0]) ?? 0
        let minutesAndSec = parts[1].components(separatedBy: ".")
        let minutes = Double(minutesAndSec[0]) ?? 0
        let seconds = Double(minutesAndSec.count > 1 ? minutesAndSec[1] : "0") ?? 0

        return hours * 3600 + minutes * 60 + seconds
    }
}
