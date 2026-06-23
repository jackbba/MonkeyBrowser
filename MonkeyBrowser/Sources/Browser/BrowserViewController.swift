import UIKit
import WebKit
import AVKit

class BrowserViewController: UIViewController {

    // MARK: - Properties

    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var urlBar: UITextField!
    private var toolbar: UIToolbar!
    private var tabsButton: UIButton!
    private var tabsCount: Int = 1
    private var tabs: [BrowserTab] = []

    // PiP
    private var pipController: AVPictureInPictureController?

    // Floating indicator
    private var floatingIndicator: UIButton?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        setupToolbar()
        setupURLBar()
        setupProgressView()
        setupNavigationButtons()
        setupFloatingIndicator()
        setupPiPObserver()
        loadHomepage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFloatingIndicator()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1.0
        }
    }

    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "MonkeyBrowser"
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        // Enable PiP for WKWebView
        config.allowsPictureInPictureMediaPlayback = true

        // Enable JavaScript
        let prefs = WKPreferences()
        prefs.setValue(true, forKey: "developerExtrasEnabled")
        config.preferences = prefs

        // User Script injection
        let contentController = WKUserContentController()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)

        // Setup Subtitle Bridge
        setupSubtitleBridge()

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -44)
        ])
    }

    private func setupSubtitleBridge() {
        SubtitleBridge.shared.register(to: webView)
        SubtitleBridge.shared.onSubtitleReceived = { [weak self] subtitleData in
            self?.handleSubtitleFromScript(subtitleData)
        }
    }

    private func handleSubtitleFromScript(_ data: SubtitleBridge.SubtitleData) {
        SubtitleManager.shared.addSubtitleFromBridge(data)

        // Show notification
        let notification = UILabel()
        notification.text = "字幕已加载: \(data.name ?? data.format)"
        notification.textColor = .white
        notification.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        notification.textAlignment = .center
        notification.font = .systemFont(ofSize: 14, weight: .medium)
        notification.layer.cornerRadius = 8
        notification.layer.masksToBounds = true
        notification.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notification)

        NSLayoutConstraint.activate([
            notification.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notification.topAnchor.constraint(equalTo: urlBar.bottomAnchor, constant: 8),
            notification.widthAnchor.constraint(equalToConstant: 200),
            notification.heightAnchor.constraint(equalToConstant: 36)
        ])

        UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
            notification.alpha = 0
        } completion: { _ in
            notification.removeFromSuperview()
        }
    }

    private func setupURLBar() {
        urlBar = UITextField()
        urlBar.translatesAutoresizingMaskIntoConstraints = false
        urlBar.borderStyle = .roundedRect
        urlBar.placeholder = "输入网址或搜索"
        urlBar.font = .systemFont(ofSize: 15)
        urlBar.autocapitalizationType = .none
        urlBar.autocorrectionType = .no
        urlBar.keyboardType = .URL
        urlBar.returnKeyType = .go
        urlBar.delegate = self
        urlBar.clearButtonMode = .whileEditing
        urlBar.leftView = UIImageView(image: UIImage(systemName: "lock.fill"))
        urlBar.leftViewMode = .always

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(urlBarTapped))
        urlBar.addGestureRecognizer(tapGesture)

        view.addSubview(urlBar)

        NSLayoutConstraint.activate([
            urlBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            urlBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            urlBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            urlBar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tintColor = .systemBlue
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: urlBar.bottomAnchor, constant: 4),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func setupToolbar() {
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupNavigationButtons() {
        let backBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )

        let forwardBtn = UIBarButtonItem(
            image: UIImage(systemName: "chevron.right"),
            style: .plain,
            target: self,
            action: #selector(goForward)
        )

        let refreshBtn = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refresh)
        )

        let shareBtn = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(sharePage)
        )

        let tabsBtn = UIBarButtonItem(
            image: UIImage(systemName: "square.on.square"),
            style: .plain,
            target: self,
            action: #selector(showTabs)
        )

        let addBtn = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(newTab)
        )

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [backBtn, spacer, forwardBtn, spacer, refreshBtn, spacer, shareBtn, spacer, addBtn, spacer, tabsBtn]
        toolbar.tintColor = .systemBlue
    }

    // MARK: - Floating Indicator

    private func setupFloatingIndicator() {
        floatingIndicator = UIButton(type: .system)
        floatingIndicator?.translatesAutoresizingMaskIntoConstraints = false
        floatingIndicator?.setImage(UIImage(systemName: "pip.fill"), for: .normal)
        floatingIndicator?.tintColor = .white
        floatingIndicator?.backgroundColor = .systemBlue
        floatingIndicator?.layer.cornerRadius = 25
        floatingIndicator?.layer.shadowColor = UIColor.black.cgColor
        floatingIndicator?.layer.shadowOffset = CGSize(width: 0, height: 2)
        floatingIndicator?.layer.shadowOpacity = 0.3
        floatingIndicator?.layer.shadowRadius = 4
        floatingIndicator?.addTarget(self, action: #selector(showFloatingPlayer), for: .touchUpInside)
        floatingIndicator?.isHidden = true

        if let indicator = floatingIndicator {
            view.addSubview(indicator)

            NSLayoutConstraint.activate([
                indicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                indicator.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: -16),
                indicator.widthAnchor.constraint(equalToConstant: 50),
                indicator.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }

    private func updateFloatingIndicator() {
        floatingIndicator?.isHidden = !FloatingPlayerManager.shared.isFloating
    }

    @objc private func showFloatingPlayer() {
        FloatingPlayerManager.shared.expandToFullScreen()
    }

    // MARK: - PiP Observer

    private func setupPiPObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePiPNotification(_:)),
            name: .pipDidStart,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePiPNotification(_:)),
            name: .pipDidStop,
            object: nil
        )
    }

    @objc private func handlePiPNotification(_ notification: Notification) {
        updateFloatingIndicator()
    }

    // MARK: - Actions

    @objc private func urlBarTapped() {
        urlBar.becomeFirstResponder()
        urlBar.selectAll(nil)
    }

    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    @objc private func refresh() {
        webView.reload()
    }

    @objc private func sharePage() {
        guard let url = webView.url else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    @objc private func showTabs() {
        let tabsVC = TabsViewController()
        tabsVC.modalPresentationStyle = .overFullScreen
        present(tabsVC, animated: true)
    }

    @objc private func newTab() {
        tabsCount += 1
        loadHomepage()
    }

    // MARK: - Load

    func openURL(_ url: URL) {
        webView.load(URLRequest(url: url))
        updateURLBar()
    }

    private func loadHomepage() {
        if let homepage = UserDefaults.standard.url(forKey: "homepage") {
            webView.load(URLRequest(url: homepage))
        } else {
            let url = URL(string: "https://www.google.com")!
            webView.load(URLRequest(url: url))
        }
        updateURLBar()
    }

    private func loadURL(_ urlString: String) {
        var urlString = urlString
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            if urlString.contains(".") && !urlString.contains(" ") {
                urlString = "https://" + urlString
            } else {
                urlString = "https://www.google.com/search?q=" + urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            }
        }
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
            updateURLBar()
        }
    }

    private func updateURLBar() {
        if let url = webView.url {
            urlBar.text = url.absoluteString
        }
    }

    // MARK: - Script Injection

    private func injectUserScripts() {
        let scripts = UserScriptEngine.shared.getScriptsForURL(webView.url)
        for script in scripts {
            let userScript = WKUserScript(
                source: script.code,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
            webView.configuration.userContentController.addUserScript(userScript)
        }
    }
}

// MARK: - WKNavigationDelegate

extension BrowserViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
        updateURLBar()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateURLBar()
        injectUserScripts()

        // Try to detect video on page
        detectVideoOnPage()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation failed: \(error.localizedDescription)")
    }

    private func detectVideoOnPage() {
        let js = """
        (function() {
            var videos = document.querySelectorAll('video');
            var sources = [];
            videos.forEach(function(video) {
                if (video.src) sources.push(video.src);
                video.querySelectorAll('source').forEach(function(s) {
                    if (s.src) sources.push(s.src);
                });
            });
            return sources;
        })()
        """
        webView.evaluateJavaScript(js) { result, error in
            if let urls = result as? [String], !urls.isEmpty {
                self.showVideoDetected(urls)
            }
        }
    }

    private func showVideoDetected(_ urls: [String]) {
        let alert = UIAlertController(
            title: "检测到视频",
            message: "选择播放方式",
            preferredStyle: .actionSheet
        )

        for url in urls.prefix(5) {
            alert.addAction(UIAlertAction(title: "VLC播放: \(URL(string: url)?.lastPathComponent ?? url)", style: .default) { _ in
                self.openInVLC(urlString: url)
            })
        }

        alert.addAction(UIAlertAction(title: "浮窗播放", style: .default) { _ in
            if let firstURL = urls.first, let url = URL(string: firstURL) {
                self.openInFloating(url: url)
            }
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func openInVLC(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let vlcPlayer = VLCPlayerViewController(url: url)
        vlcPlayer.modalPresentationStyle = .fullScreen
        present(vlcPlayer, animated: true)
    }

    private func openInFloating(url: URL) {
        FloatingPlayerManager.shared.showFloating(
            from: self,
            url: url,
            time: 0,
            subtitleURL: nil
        )
        updateFloatingIndicator()
    }
}

// MARK: - WKUIDelegate

extension BrowserViewController: WKUIDelegate {

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension BrowserViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text, !text.isEmpty {
            loadURL(text)
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pipDidStart = Notification.Name("pipDidStart")
    static let pipDidStop = Notification.Name("pipDidStop")
}
