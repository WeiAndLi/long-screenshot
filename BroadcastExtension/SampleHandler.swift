import ReplayKit
import AVFoundation

/// 系统控制中心录屏扩展
/// 接收 ReplayKit 视频流 → 写入 App Group 共享目录 → 主 App 自动处理
final class SampleHandler: RPBroadcastSampleHandler {

    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var outputURL: URL?

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.longscreenshot.app"
        ) else {
            finishBroadcastWithError(NSError(
                domain: "LongScreenshot",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法访问共享存储，请检查 App Group 配置"]
            ))
            return
        }

        let recordingsDir = containerURL.appendingPathComponent("pending_recordings")
        try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)

        let url = recordingsDir
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        try? FileManager.default.removeItem(at: url)
        self.outputURL = url

        do {
            let writer = try AVAssetWriter(url: url, fileType: .mp4)

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1170,
                AVVideoHeightKey: 2532,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 8_000_000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]

            let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            input.expectsMediaDataInRealTime = true
            writer.add(input)

            self.assetWriter = writer
            self.videoInput = input
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

        } catch {
            finishBroadcastWithError(error)
        }
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with type: RPSampleBufferType) {
        guard type == .video,
              let writer = assetWriter,
              let input = videoInput,
              writer.status == .writing,
              input.isReadyForMoreMediaData else { return }

        input.append(sampleBuffer)
    }

    override func broadcastFinished() {
        guard let url = outputURL else {
            finishBroadcast()
            return
        }

        videoInput?.markAsFinished()
        assetWriter?.finishWriting { [weak self] in
            // 通知主 App：新录制已就绪
            let defaults = UserDefaults(suiteName: "group.com.longscreenshot.app")
            var pending: [String] = defaults?.stringArray(forKey: "pendingVideos") ?? []
            pending.append(url.path)
            defaults?.set(pending, forKey: "pendingVideos")
            defaults?.synchronize()
            self?.finishBroadcast()
        }
    }
}
