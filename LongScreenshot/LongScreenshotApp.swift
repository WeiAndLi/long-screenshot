import SwiftUI
import CoreData
import Photos

@main
struct LongScreenshotApp: App {
    let persistenceController = PersistenceController.shared

    @State private var autoProcessTask: Task<Void, Never>?

    init() {
        #if DEBUG
        if CommandLine.arguments.contains("-com.apple.CoreData.SQLDebug") {
            print("Core Data SQL 调试已启用")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .onAppear { startAutoProcessTimer() }
                .onReceive(
                    NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                ) { _ in
                    checkPendingRecordings()
                }
        }
    }

    // MARK: - 自动处理控制中心录屏

    private func startAutoProcessTimer() {
        autoProcessTask = Task {
            while !Task.isCancelled {
                checkPendingRecordings()
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒轮询
            }
        }
    }

    private func checkPendingRecordings() {
        let defaults = UserDefaults(suiteName: "group.com.longscreenshot.app")
        guard var pending: [String] = defaults?.stringArray(forKey: "pendingVideos"),
              !pending.isEmpty else { return }

        let videoPath = pending.removeFirst()
        defaults?.set(pending, forKey: "pendingVideos")

        let videoURL = URL(fileURLWithPath: videoPath)
        guard FileManager.default.fileExists(atPath: videoPath) else { return }

        // 异步处理录屏
        Task.detached(priority: .background) {
            let converter = VideoToFramesConverter()
            let progress = StitchingProgress()
            if let result = await converter.generateLongScreenshot(fromLocalURL: videoURL, progress: progress) {
                // 保存到相册
                try? await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: result)
                }
                // 清理临时文件
                try? FileManager.default.removeItem(at: videoURL)
            }
        }
    }
}

private struct PersistenceControllerKey: EnvironmentKey {
    static let defaultValue = PersistenceController.shared
}

extension EnvironmentValues {
    var persistenceController: PersistenceController {
        get { self[PersistenceControllerKey.self] }
        set { self[PersistenceControllerKey.self] = newValue }
    }
}
