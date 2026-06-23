import Foundation
import WebKit

// MARK: - JavaScript Bridge for Subtitle Passing

class SubtitleBridge: NSObject {

    static let shared = SubtitleBridge()

    weak var webView: WKWebView?
    var onSubtitleReceived: ((SubtitleData) -> Void)?

    struct SubtitleData: Codable {
        let format: String
        let content: String
        let language: String?
        let name: String?
    }

    private override init() {
        super.init()
    }

    // MARK: - Register to WKWebView

    func register(to webView: WKWebView) {
        self.webView = webView
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: "subtitleBridge")
        contentController.add(self, name: "addSubtitle")
        contentController.add(self, name: "setSubtitle")
        contentController.add(self, name: "getSubtitle")

        // Inject helper JS functions
        let helperJS = SubtitleBridgeHelper.javaScript
        let userScript = WKUserScript(
            source: helperJS,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(userScript)
    }

    // MARK: - Send subtitle to native layer

    func parseAndSendSubtitle(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let subtitleData = try? JSONDecoder().decode(SubtitleData.self, from: data) else {
            print("Failed to parse subtitle data")
            return
        }
        onSubtitleReceived?(subtitleData)
    }
}

// MARK: - WKScriptMessageHandler

extension SubtitleBridge: WKScriptMessageHandler {

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        switch message.name {
        case "subtitleBridge", "addSubtitle", "setSubtitle":
            if let body = message.body as? String {
                parseAndSendSubtitle(body)
            } else if let body = message.body as? [String: Any],
                      let jsonData = try? JSONSerialization.data(withJSONObject: body),
                      let jsonString = String(data: jsonData, encoding: .utf8) {
                parseAndSendSubtitle(jsonString)
            }

        case "getSubtitle":
            respondToSubtitleRequest()

        default:
            break
        }
    }

    private func respondToSubtitleRequest() {
        guard let webView = webView else { return }

        let js = """
        if (window.__monkeyBrowser) {
            window.__monkeyBrowser.onSubtitleState({
                hasSubtitle: \(SubtitleManager.shared.getAllSubtitles().count > 0),
                count: \(SubtitleManager.shared.getAllSubtitles().count)
            });
        }
        """
        webView.evaluateJavaScript(js)
    }
}

// MARK: - JavaScript Helper Functions

struct SubtitleBridgeHelper {

    static let javaScript = """
    // MonkeyBrowser Subtitle Bridge Helper
    window.MonkeyBrowserSubtitle = {
        /**
         * Add SRT format subtitle
         * @param {string} content - SRT subtitle content
         * @param {object} options - Optional params {language: 'zh', name: 'Chinese Subtitle'}
         */
        addSRT: function(content, options = {}) {
            const data = {
                format: 'srt',
                content: content,
                language: options.language || 'zh',
                name: options.name || 'SRT Subtitle'
            };
            this._send(data);
        },

        /**
         * Add VTT format subtitle
         * @param {string} content - VTT subtitle content
         * @param {object} options - Optional params
         */
        addVTT: function(content, options = {}) {
            const data = {
                format: 'vtt',
                content: content,
                language: options.language || 'zh',
                name: options.name || 'VTT Subtitle'
            };
            this._send(data);
        },

        /**
         * Add ASS format subtitle
         * @param {string} content - ASS subtitle content
         * @param {object} options - Optional params
         */
        addASS: function(content, options = {}) {
            const data = {
                format: 'ass',
                content: content,
                language: options.language || 'zh',
                name: options.name || 'ASS Subtitle'
            };
            this._send(data);
        },

        /**
         * Load subtitle from URL
         * @param {string} url - Subtitle file URL
         */
        loadFromURL: function(url) {
            const ext = url.split('.').pop().toLowerCase();
            const formatMap = {'srt': 'srt', 'vtt': 'vtt', 'ass': 'ass', 'ssa': 'ass'};
            const format = formatMap[ext] || 'srt';

            fetch(url)
                .then(r => r.text())
                .then(content => {
                    this._send({
                        format: format,
                        content: content,
                        language: 'auto',
                        name: url.split('/').pop()
                    });
                })
                .catch(err => console.error('Failed to load subtitle:', err));
        },

        /**
         * Add timed subtitle entries
         * @param {Array} entries - [{start: 0, end: 5, text: 'Hello'}, ...]
         * @param {string} format - Output format 'srt' or 'vtt'
         */
        addTimedEntries: function(entries, format = 'srt') {
            let content = '';
            if (format === 'srt') {
                entries.forEach((entry, i) => {
                    content += (i + 1) + '\\n';
                    content += this._formatTimeSRT(entry.start) + ' --> ' + this._formatTimeSRT(entry.end) + '\\n';
                    content += entry.text + '\\n\\n';
                });
            } else if (format === 'vtt') {
                content = 'WEBVTT\\n\\n';
                entries.forEach(entry => {
                    content += this._formatTimeVTT(entry.start) + ' --> ' + this._formatTimeVTT(entry.end) + '\\n';
                    content += entry.text + '\\n\\n';
                });
            }
            this._send({ format, content, language: 'auto', name: 'Auto Generated' });
        },

        // Internal methods
        _send: function(data) {
            if (window.webkit && window.webkit.messageHandlers) {
                window.webkit.messageHandlers.addSubtitle.postMessage(JSON.stringify(data));
            }
        },

        _formatTimeSRT: function(seconds) {
            const h = Math.floor(seconds / 3600);
            const m = Math.floor((seconds % 3600) / 60);
            const s = Math.floor(seconds % 60);
            const ms = Math.floor((seconds % 1) * 1000);
            return String(h).padStart(2,'0') + ':' + String(m).padStart(2,'0') + ':' +
                   String(s).padStart(2,'0') + ',' + String(ms).padStart(3,'0');
        },

        _formatTimeVTT: function(seconds) {
            const h = Math.floor(seconds / 3600);
            const m = Math.floor((seconds % 3600) / 60);
            const s = Math.floor(seconds % 60);
            const ms = Math.floor((seconds % 1) * 1000);
            return String(h).padStart(2,'0') + ':' + String(m).padStart(2,'0') + ':' +
                   String(s).padStart(2,'0') + '.' + String(ms).padStart(3,'0');
        }
    };

    // Compatibility for Tampermonkey scripts
    window.__monkeyBrowser = {
        addSubtitle: function(content, format, options) {
            window.MonkeyBrowserSubtitle['add' + format.toUpperCase()](content, options || {});
        },
        loadSubtitleFromURL: function(url) {
            window.MonkeyBrowserSubtitle.loadFromURL(url);
        }
    };

    // Trigger event to notify scripts
    document.addEventListener('DOMContentLoaded', function() {
        const event = new CustomEvent('monkeyBrowserReady', { detail: { version: '1.0' } });
        document.dispatchEvent(event);
    });

    console.log('[MonkeyBrowser] Subtitle bridge loaded');
    """;
}
