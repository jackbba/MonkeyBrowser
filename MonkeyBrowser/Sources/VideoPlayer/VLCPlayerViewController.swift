import UIKit
import AVKit
import MobileVLCKit

class VLCPlayerViewController: UIViewController {

    // MARK: - Properties

    let mediaURL: URL
    var startTime: Double = 0
    var subtitleURL: URL?

    private var mediaPlayer: VLCMediaPlayer?
    private var videoView: UIView!
    private var controlsContainer: UIView!
    private var playPauseButton: UIButton!
    private var timeSlider: UISlider!
    private var timeLabel: UILabel!
    private var subtitleButton: UIButton!
    private var pipButton: UIButton!
    private var floatButton: UIButton!
    private var dismissButton: UIButton!
    private var activityIndicator: UIActivityIndicatorView!
    private var subtitleLabel: UILabel!
    private var hideControlsTimer: Timer?
    private var subtitleTimer: Timer?

    // PiP
    private var avPlayer: AVPlayer?
    private var pipController: AVPictureInPictureController?
    private var isPiPActive = false

    // Subtitle
    private let subtitleManager = SubtitleManager()
    private var currentSubtitleIndex: Int = -1

    // MARK: - Init

    init(url: URL) {
        self.mediaURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupVideoView()
        setupSubtitleLabel()
        setupControls()
        setupPiP()
        setupPlayer()

        if let subURL = subtitleURL {
            subtitleManager.loadSubtitles(from: subURL)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        subtitleTimer?.invalidate()
        mediaPlayer?.stop()
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

    private func setupSubtitleLabel() {
        subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = .white
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 3
        subtitleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        subtitleLabel.layer.cornerRadius = 6
        subtitleLabel.layer.masksToBounds = true
        subtitleLabel.isHidden = true
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            subtitleLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupControls() {
        controlsContainer = UIView()
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.addSubview(controlsContainer)

        // Activity Indicator
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        // Dismiss Button
        dismissButton = UIButton(type: .system)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismissButton.tintColor = .white
        dismissButton.addTarget(self, action: #selector(dismissPlayer), for: .touchUpInside)

        // Play/Pause Button
        playPauseButton = UIButton(type: .system)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        playPauseButton.configuration = .plain()
        playPauseButton.configuration?.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 40)

        // Time Slider
        timeSlider = UISlider()
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        timeSlider.tintColor = .systemBlue
        timeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        timeSlider.addTarget(self, action: #selector(sliderTouchUp), for: [.touchUpInside, .touchUpOutside])

        // Time Label
        timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = .white
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        timeLabel.text = "00:00 / 00:00"

        // Subtitle Button
        subtitleButton = UIButton(type: .system)
        subtitleButton.translatesAutoresizingMaskIntoConstraints = false
        subtitleButton.setImage(UIImage(systemName: "captions.bubble"), for: .normal)
        subtitleButton.tintColor = .white
        subtitleButton.addTarget(self, action: #selector(showSubtitleOptions), for: .touchUpInside)

        // PiP Button
        pipButton = UIButton(type: .system)
        pipButton.translatesAutoresizingMaskIntoConstraints = false
        pipButton.setImage(UIImage(systemName: "pip.enter"), for: .normal)
        pipButton.tintColor = .white
        pipButton.addTarget(self, action: #selector(togglePiP), for: .touchUpInside)
        pipButton.isHidden = !AVPictureInPictureController.isPictureInPictureSupported()

        // Float Button
        floatButton = UIButton(type: .system)
        floatButton.translatesAutoresizingMaskIntoConstraints = false
        floatButton.setImage(UIImage(systemName: "pip.exit"), for: .normal)
        floatButton.tintColor = .white
        floatButton.addTarget(self, action: #selector(showFloating), for: .touchUpInside)

        controlsContainer.addSubview(dismissButton)
        controlsContainer.addSubview(playPauseButton)
        controlsContainer.addSubview(timeSlider)
        controlsContainer.addSubview(timeLabel)
        controlsContainer.addSubview(subtitleButton)
        controlsContainer.addSubview(pipButton)
        controlsContainer.addSubview(floatButton)

        NSLayoutConstraint.activate([
            controlsContainer.topAnchor.constraint(equalTo: view.topAnchor),
            controlsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dismissButton.widthAnchor.constraint(equalToConstant: 44),
            dismissButton.heightAnchor.constraint(equalToConstant: 44),

            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 80),
            playPauseButton.heightAnchor.constraint(equalToConstant: 80),

            subtitleButton.centerYAnchor.constraint(equalTo: timeSlider.centerYAnchor),
            subtitleButton.trailingAnchor.constraint(equalTo: pipButton.leadingAnchor, constant: -12),
            subtitleButton.widthAnchor.constraint(equalToConstant: 40),
            subtitleButton.heightAnchor.constraint(equalToConstant: 40),

            pipButton.centerYAnchor.constraint(equalTo: timeSlider.centerYAnchor),
            pipButton.trailingAnchor.constraint(equalTo: floatButton.leadingAnchor, constant: -12),
            pipButton.widthAnchor.constraint(equalToConstant: 40),
            pipButton.heightAnchor.constraint(equalToConstant: 40),

            floatButton.centerYAnchor.constraint(equalTo: timeSlider.centerYAnchor),
            floatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            floatButton.widthAnchor.constraint(equalToConstant: 40),
            floatButton.heightAnchor.constraint(equalToConstant: 40),

            timeSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeSlider.trailingAnchor.constraint(equalTo: subtitleButton.leadingAnchor, constant: -12),
            timeSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            timeSlider.heightAnchor.constraint(equalToConstant: 30),

            timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: timeSlider.topAnchor, constant: -8)
        ])
    }

    private func setupPiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }

        // Create AVPlayer for PiP (VLC doesn't support native PiP, so we use AVPlayer as bridge)
        let avPlayerItem = AVPlayerItem(url: mediaURL)
        avPlayer = AVPlayer(playerItem: avPlayerItem)

        pipController = AVPictureInPictureController(playerLayer: AVPlayerLayer(player: avPlayer))
        pipController?.delegate = self
    }

    private func setupPlayer() {
        activityIndicator.startAnimating()

        let media = VLCMedia(url: mediaURL)
        if startTime > 0 {
            media.addOptions(["start-time": "\(Int(startTime))"])
        }

        mediaPlayer = VLCMediaPlayer()
        mediaPlayer?.drawable = videoView
        mediaPlayer?.media = media
        mediaPlayer?.delegate = self

        // Enable subtitles
        mediaPlayer?.currentVideoSubTitleIndex = 0

        // Listen for subtitle updates from scripts
        SubtitleManager.shared.subtitlesDidChange = { [weak self] in
            DispatchQueue.main.async {
                self?.updateSubtitleDisplay()
            }
        }

        mediaPlayer?.play()
        startSubtitleTimer()
        hideControlsAfterDelay()
    }

    // MARK: - Actions

    @objc private func dismissPlayer() {
        subtitleTimer?.invalidate()
        mediaPlayer?.stop()
        avPlayer?.pause()
        dismiss(animated: true)
    }

    @objc private func togglePlayPause() {
        guard let player = mediaPlayer else { return }
        if player.isPlaying {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        guard let duration = mediaPlayer?.media?.length else { return }
        let time = VLCTime(int: Int32(sender.value * Float(duration.intValue / 1000)))
        mediaPlayer?.time = time
        updateTimeLabel()
    }

    @objc private func sliderTouchUp() {
        hideControlsAfterDelay()
    }

    // MARK: - PiP

    @objc private func togglePiP() {
        guard let pipController = pipController else { return }

        if pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        } else {
            // Sync VLC time to AVPlayer
            if let currentTime = mediaPlayer?.time?.doubleValue {
                let cmTime = CMTime(seconds: currentTime, preferredTimescale: 600)
                avPlayer?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }

            // Pause VLC and start PiP
            mediaPlayer?.pause()
            pipController.startPictureInPicture()
        }
    }

    // MARK: - Floating Window

    @objc private func showFloating() {
        let currentTime = mediaPlayer?.time?.doubleValue ?? 0
        mediaPlayer?.stop()
        avPlayer?.pause()
        subtitleTimer?.invalidate()

        FloatingPlayerManager.shared.showFloating(
            from: self,
            url: mediaURL,
            time: currentTime,
            subtitleURL: subtitleURL
        )

        dismiss(animated: false)
    }

    // MARK: - Subtitles

    @objc private func showSubtitleOptions() {
        let alert = UIAlertController(title: "字幕选项", message: nil, preferredStyle: .actionSheet)

        // Built-in subtitles
        if let player = mediaPlayer, let subtitleNames = player.videoSubTitles as? [String] {
            for (index, name) in subtitleNames.enumerated() where index > 0 {
                alert.addAction(UIAlertAction(title: "\(name) (内置)", style: .default) { [weak self] _ in
                    self?.mediaPlayer?.currentVideoSubTitleIndex = Int32(index)
                    self?.currentSubtitleIndex = index
                })
            }
        }

        // Load external subtitle
        alert.addAction(UIAlertAction(title: "加载外部字幕文件", style: .default) { [weak self] _ in
            self?.loadExternalSubtitle()
        })

        // Disable subtitles
        alert.addAction(UIAlertAction(title: "关闭字幕", style: .default) { [weak self] _ in
            self?.mediaPlayer?.currentVideoSubTitleIndex = -1
            self?.currentSubtitleIndex = -1
            self?.subtitleLabel.isHidden = true
        })

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func loadExternalSubtitle() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .init(filenameExtension: "srt")!,
            .init(filenameExtension: "ass")!,
            .init(filenameExtension: "ssa")!,
            .init(filenameExtension: "vtt")!
        ])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    // MARK: - Subtitle Timer

    private func startSubtitleTimer() {
        subtitleTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateSubtitle()
        }
    }

    private func updateSubtitle() {
        guard let currentTime = mediaPlayer?.time?.doubleValue else { return }

        if let subtitle = subtitleManager.getSubtitle(forTime: currentTime) {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
        } else if currentSubtitleIndex < 0 {
            subtitleLabel.isHidden = true
        }
    }

    private func updateSubtitleDisplay() {
        let count = subtitleManager.getAllSubtitles().count
        if count > 0 {
            subtitleButton.tintColor = .systemBlue
            print("[VLCPlayer] Subtitles updated: \(count) entries")
        } else {
            subtitleButton.tintColor = .white
        }
    }

    // MARK: - Time

    private func updateTimeLabel() {
        guard let current = mediaPlayer?.time?.intValue,
              let remaining = mediaPlayer?.remainingTime?.intValue else { return }
        let elapsed = current / 1000
        let total = (current - remaining) / 1000

        let elapsedStr = String(format: "%02d:%02d:%02d", elapsed / 3600, (elapsed % 3600) / 60, elapsed % 60)
        let totalStr = String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)

        timeLabel.text = "\(elapsedStr) / \(totalStr)"

        if total > 0 {
            timeSlider.value = Float(current) / Float(total * 1000)
        }
    }

    // MARK: - Controls

    private func hideControlsAfterDelay() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.hideControls()
        }
    }

    private func hideControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlsContainer.alpha = 0
        }
    }

    private func showControls() {
        UIView.animate(withDuration: 0.3) {
            self.controlsContainer.alpha = 1
        }
        hideControlsAfterDelay()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if controlsContainer.alpha > 0.5 {
            hideControls()
        } else {
            showControls()
        }
    }
}

// MARK: - VLCMediaPlayerDelegate

extension VLCPlayerViewController: VLCMediaPlayerDelegate {

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        guard let player = mediaPlayer else { return }

        DispatchQueue.main.async {
            switch player.state {
            case .playing:
                self.activityIndicator.stopAnimating()
                self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            case .paused:
                self.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            case .ended:
                self.dismissPlayer()
            case .error:
                self.showError("播放出错")
            default:
                break
            }
            self.updateTimeLabel()
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        DispatchQueue.main.async {
            self.updateTimeLabel()
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.dismissPlayer()
        })
        present(alert, animated: true)
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension VLCPlayerViewController: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {
        isPiPActive = true
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        print("PiP started")
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ controller: AVPictureInPictureController) {
        isPiPActive = false
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        // Sync time back to VLC
        if let avPlayer = avPlayer, let currentTime = avPlayer.currentTime().seconds as Double? {
            let vlcTime = VLCTime(int: Int32(currentTime))
            mediaPlayer?.time = vlcTime
        }
        mediaPlayer?.play()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        isPiPActive = false
        showError("画中画启动失败: \(error.localizedDescription)")
    }
}

// MARK: - UIDocumentPickerDelegate

extension VLCPlayerViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let subtitleURL = urls.first else { return }

        self.subtitleURL = subtitleURL
        subtitleManager.loadSubtitles(from: subtitleURL)
        currentSubtitleIndex = 0
    }
}
