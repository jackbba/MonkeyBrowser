import UIKit
import AVKit
import MobileVLCKit

// MARK: - PiP Manager

class PiPManager: NSObject {

    static let shared = PiPManager()

    private var pipController: AVPictureInPictureController?
    private var playerLayer: AVPlayerLayer?
    private var onRestore: (() -> Void)?

    var isPiPAvailable: Bool {
        return AVPictureInPictureController.isPictureInPictureSupported()
    }

    func startPiP(
        with player: AVPlayer,
        restoreHandler: @escaping () -> Void
    ) -> Bool {
        guard isPiPAvailable else { return false }

        self.onRestore = restoreHandler

        if pipController == nil {
            pipController = AVPictureInPictureController(playerLayer: AVPlayerLayer(player: player))
            pipController?.delegate = self
        }

        pipController?.playerLayer = AVPlayerLayer(player: player)
        pipController?.startPictureInPicture()
        return true
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
    }
}

extension PiPManager: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("PiP will start")
    }

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("PiP did start")
    }

    func pictureInPictureControllerWillStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("PiP will stop")
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        print("PiP did stop")
        DispatchQueue.main.async {
            self.onRestore?()
        }
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        print("PiP failed: \(error.localizedDescription)")
    }
}
