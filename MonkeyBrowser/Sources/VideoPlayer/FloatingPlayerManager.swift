import UIKit
import MobileVLCKit

// MARK: - Floating Player Manager

class FloatingPlayerManager: NSObject {

    static let shared = FloatingPlayerManager()

    private var floatingWindow: UIWindow?
    private var floatingViewController: FloatingViewController?
    private var originalWindow: UIWindow?
    private var originalSuperview: UIView?

    var isFloating: Bool {
        return floatingWindow != nil
    }

    var currentURL: URL?
    var currentTime: Double = 0

    // MARK: - Public

    func showFloating(
        from viewController: UIViewController,
        url: URL,
        time: Double = 0,
        subtitleURL: URL? = nil
    ) {
        guard let windowScene = viewController.view.window?.windowScene else { return }

        currentURL = url
        currentTime = time

        let floatingVC = FloatingViewController(
            url: url,
            time: time,
            subtitleURL: subtitleURL
        )
        floatingVC.onClose = { [weak self] in
            self?.dismissFloating()
        }
        floatingVC.onExpand = { [weak self] in
            self?.expandToFullScreen()
        }
        self.floatingViewController = floatingVC

        let window = PassThroughWindow(windowScene: windowScene)
        window.rootViewController = floatingVC
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1
        window.isHidden = false
        self.floatingWindow = window

        floatingVC.view.alpha = 0
        floatingVC.view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.3) {
            floatingVC.view.alpha = 1
            floatingVC.view.transform = .identity
        }
    }

    func dismissFloating() {
        guard let vc = floatingViewController else { return }

        currentTime = vc.getCurrentTime()

        UIView.animate(withDuration: 0.2, animations: {
            vc.view.alpha = 0
            vc.view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }) { [weak self] _ in
            self?.floatingViewController?.player?.stop()
            self?.floatingWindow?.isHidden = true
            self?.floatingWindow = nil
            self?.floatingViewController = nil
        }
    }

    func expandToFullScreen() {
        guard let vc = floatingViewController,
              let url = currentURL else { return }

        let time = vc.getCurrentTime()
        let subtitleURL = vc.currentSubtitleURL

        dismissFloating()

        let playerVC = VLCPlayerViewController(url: url)
        playerVC.startTime = time
        playerVC.subtitleURL = subtitleURL
        playerVC.modalPresentationStyle = .fullScreen

        if let topVC = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController() {
            topVC.present(playerVC, animated: true)
        }
    }

    func updatePosition() {
        guard let vc = floatingViewController else { return }
        vc.view.frame = FloatingPlayerConstants.floatingFrame
    }
}

// MARK: - Pass Through Window

class PassThroughWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result == self ? nil : result
    }
}

// MARK: - Floating View Controller

class FloatingViewController: UIViewController {

    var onClose: (() -> Void)?
    var onExpand: (() -> Void)?

    private let url: URL
    private let startTime: Double
    var currentSubtitleURL: URL?

    private(set) var player: VLCMediaPlayer?
    private var videoView: UIView!
    private var controlsView: UIView!
    private var playPauseButton: UIButton!
    private var closeButton: UIButton!
    private var expandButton: UIButton!
    private var subtitleLabel: UILabel!
    private var panGesture: UIPanGestureRecognizer!
    private var subtitleTimer: Timer?
    private var hideControlsTimer: Timer?

    private let subtitleManager = SubtitleManager()

    init(url: URL, time: Double = 0, subtitleURL: URL? = nil) {
        self.url = url
        self.startTime = time
        self.currentSubtitleURL = subtitleURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true

        setupVideoView()
        setupControls()
        setupGestures()
        setupPlayer()

        if let subURL = currentSubtitleURL {
            subtitleManager.loadSubtitles(from: subURL)
        }
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    // MARK: - Setup

    private func setupVideoView() {
        videoView = UIView()
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.backgroundColor = .black
        view.addSubview(videoView)

        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: view.topAnchor),
            videoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupControls() {
        controlsView = UIView()
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        controlsView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(controlsView)

        playPauseButton = UIButton(type: .system)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)

        closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        expandButton = UIButton(type: .system)
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        expandButton.tintColor = .white
        expandButton.addTarget(self, action: #selector(expandTapped), for: .touchUpInside)

        subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = .white
        subtitleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        subtitleLabel.layer.cornerRadius = 4
        subtitleLabel.layer.masksToBounds = true
        subtitleLabel.isHidden = true

        controlsView.addSubview(playPauseButton)
        controlsView.addSubview(closeButton)
        controlsView.addSubview(expandButton)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            controlsView.topAnchor.constraint(equalTo: view.topAnchor),
            controlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            playPauseButton.centerXAnchor.constraint(equalTo: controlsView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsView.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 36),
            playPauseButton.heightAnchor.constraint(equalToConstant: 36),

            closeButton.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 4),
            closeButton.leadingAnchor.constraint(equalTo: controlsView.leadingAnchor, constant: 4),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            expandButton.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 4),
            expandButton.trailingAnchor.constraint(equalTo: controlsView.trailingAnchor, constant: -4),
            expandButton.widthAnchor.constraint(equalToConstant: 24),
            expandButton.heightAnchor.constraint(equalToConstant: 24),

            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
    }

    private func setupGestures() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    private func setupPlayer() {
        let media = VLCMedia(url: url)
        player = VLCMediaPlayer()
        player?.drawable = videoView
        player?.media = media
        player?.delegate = self

        if startTime > 0 {
            player?.media?.addOptions(["start-time": "\(Int(startTime))"])
        }

        player?.currentVideoSubTitleIndex = 0

        player?.play()
        startSubtitleTimer()
        hideControlsAfterDelay()
    }

    // MARK: - Actions

    @objc private func togglePlayPause() {
        guard let player = player else { return }
        if player.isPlaying {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }

    @objc private func closeTapped() {
        subtitleTimer?.invalidate()
        onClose?()
    }

    @objc private func expandTapped() {
        subtitleTimer?.invalidate()
        onExpand?()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let window = view.window else { return }

        let translation = gesture.translation(in: window)
        let velocity = gesture.velocity(in: window)

        switch gesture.state {
        case .changed:
            let newX = view.center.x + translation.x
            let newY = view.center.y + translation.y

            let clampedX = max(view.bounds.width / 2, min(window.bounds.width - view.bounds.width / 2, newX))
            let clampedY = max(view.bounds.height / 2, min(window.bounds.height - view.bounds.height / 2, newY))

            view.center = CGPoint(x: clampedX, y: clampedY)
            gesture.setTranslation(.zero, in: window)

        case .ended:
            let finalX: CGFloat
            if velocity.x > 0 {
                finalX = window.bounds.width - view.bounds.width / 2 - 8
            } else {
                finalX = view.bounds.width / 2 + 8
            }

            let finalY = max(
                view.bounds.height / 2,
                min(window.bounds.height - view.bounds.height / 2, view.center.y)
            )

            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.view.center = CGPoint(x: finalX, y: finalY)
            }

        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        if controlsView.alpha > 0.5 {
            hideControls()
        } else {
            showControls()
            hideControlsAfterDelay()
        }
    }

    // MARK: - Subtitle

    private func startSubtitleTimer() {
        subtitleTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateSubtitle()
        }
    }

    private func updateSubtitle() {
        guard let currentTime = player?.time?.doubleValue else { return }

        if let subtitle = subtitleManager.getSubtitle(forTime: currentTime) {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.isHidden = true
        }
    }

    // MARK: - Controls visibility

    private func hideControlsAfterDelay() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }

    private func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlsView.alpha = 0
        }
    }

    private func showControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlsView.alpha = 1
        }
    }

    // MARK: - Public

    func getCurrentTime() -> Double {
        return player?.time?.doubleValue ?? 0
    }
}

// MARK: - VLCMediaPlayerDelegate

extension FloatingViewController: VLCMediaPlayerDelegate {

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        guard let player = player else { return }

        DispatchQueue.main.async {
            switch player.state {
            case .playing:
                self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            case .paused:
                self.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            case .ended:
                self.closeTapped()
            default:
                break
            }
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        // Update subtitle
    }
}

// MARK: - Floating Player Constants

struct FloatingPlayerConstants {
    static let floatingWidth: CGFloat = 200
    static let floatingHeight: CGFloat = 120
    static let margin: CGFloat = 16

    static var floatingFrame: CGRect {
        return CGRect(
            x: UIScreen.main.bounds.width - floatingWidth - margin,
            y: UIScreen.main.bounds.height - floatingHeight - margin - 100,
            width: floatingWidth,
            height: floatingHeight
        )
    }
}

// MARK: - UIViewController Extension

extension UIViewController {
    func topMostViewController() -> UIViewController? {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController()
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController()
        }
        return self
    }
}
