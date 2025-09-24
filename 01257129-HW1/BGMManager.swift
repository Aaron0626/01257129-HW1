import Foundation
import AVFoundation
import UIKit

final class BGMManager {
    static let shared = BGMManager()

    private var player: AVAudioPlayer?
    private var fadeTimer: CADisplayLink?
    private var fadeStartVolume: Float = 0
    private var fadeTargetVolume: Float = 0
    private var fadeDuration: CFTimeInterval = 0
    private var fadeStartTime: CFTimeInterval = 0
    private var stopAfterFade: Bool = false
    private var pauseAfterFade: Bool = false

    private init() {}

    // 狀態
    var isPlaying: Bool { player?.isPlaying == true }
    var isPaused: Bool { (player?.isPlaying == false) && player != nil }

    // MARK: - Asset Catalog
    func playAsset(named name: String, loops: Int = -1, volume: Float = 1.0) {
        stopFadeTimer()

        guard let asset = NSDataAsset(name: name) else {
            print("BGMManager: NSDataAsset named \(name) not found.")
            return
        }
        do {
            let p = try AVAudioPlayer(data: asset.data)
            p.numberOfLoops = loops
            p.volume = volume
            p.prepareToPlay()
            p.play()
            self.player = p
        } catch {
            print("BGMManager: AVAudioPlayer init error: \(error)")
        }
    }

    func playAssetWithFadeIn(named name: String, loops: Int = -1, duration: CFTimeInterval = 5, targetVolume: Float = 1.0) {
        stopFadeTimer()

        guard let asset = NSDataAsset(name: name) else {
            print("BGMManager: NSDataAsset named \(name) not found.")
            return
        }
        do {
            let p = try AVAudioPlayer(data: asset.data)
            p.numberOfLoops = loops
            p.volume = 0
            p.prepareToPlay()
            p.play()
            self.player = p

            fadeStartVolume = 0
            fadeTargetVolume = targetVolume
            fadeDuration = max(0.001, duration)
            fadeStartTime = CACurrentMediaTime()
            stopAfterFade = false
            pauseAfterFade = false
            startFadeTimer()
        } catch {
            print("BGMManager: AVAudioPlayer init error: \(error)")
        }
    }

    // MARK: - File URL 版本
    func playFile(named name: String, ext: String, loops: Int = -1, volume: Float = 1.0) {
        stopFadeTimer()

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("BGMManager: File \(name).\(ext) not found in bundle.")
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = loops
            p.volume = volume
            p.prepareToPlay()
            p.play()
            self.player = p
        } catch {
            print("BGMManager: AVAudioPlayer init error: \(error)")
        }
    }

    func playFileWithFadeIn(named name: String, ext: String, loops: Int = -1, duration: CFTimeInterval = 5, targetVolume: Float = 1.0) {
        stopFadeTimer()

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("BGMManager: File \(name).\(ext) not found in bundle.")
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = loops
            p.volume = 0
            p.prepareToPlay()
            p.play()
            self.player = p

            fadeStartVolume = 0
            fadeTargetVolume = targetVolume
            fadeDuration = max(0.001, duration)
            fadeStartTime = CACurrentMediaTime()
            stopAfterFade = false
            pauseAfterFade = false
            startFadeTimer()
        } catch {
            print("BGMManager: AVAudioPlayer init error: \(error)")
        }
    }

    // MARK: - 控制
    func stop() {
        stopFadeTimer()
        player?.stop()
        player = nil
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func setVolume(_ v: Float) {
        player?.volume = v
    }

    // 淡出並停止
    func fadeOutAndStop(duration: CFTimeInterval = 5) {
        guard let player = player else { return }
        stopFadeTimer()

        fadeStartVolume = player.volume
        fadeTargetVolume = 0
        fadeDuration = max(0.001, duration)
        fadeStartTime = CACurrentMediaTime()
        stopAfterFade = true
        pauseAfterFade = false
        startFadeTimer()
    }

    // 淡出並暫停（不清空 player，保留播放進度）
    func fadeOutAndPause(duration: CFTimeInterval = 5) {
        guard let player = player else { return }
        stopFadeTimer()

        fadeStartVolume = player.volume
        fadeTargetVolume = 0
        fadeDuration = max(0.001, duration)
        fadeStartTime = CACurrentMediaTime()
        stopAfterFade = false
        pauseAfterFade = true
        startFadeTimer()
    }

    // 新增：從暫停狀態淡入繼續播放
    func resumeWithFadeIn(duration: CFTimeInterval = 5, targetVolume: Float = 1.0) {
        guard let player = player else { return }
        stopFadeTimer()

        if !player.isPlaying {
            player.volume = 0
            player.play()
        }
        fadeStartVolume = player.volume
        fadeTargetVolume = targetVolume
        fadeDuration = max(0.001, duration)
        fadeStartTime = CACurrentMediaTime()
        stopAfterFade = false
        pauseAfterFade = false
        startFadeTimer()
    }

    // MARK: - 私有：淡入/淡出計時
    private func startFadeTimer() {
        let link = CADisplayLink(target: self, selector: #selector(handleFadeStep))
        link.add(to: .main, forMode: .common)
        fadeTimer = link
    }

    private func stopFadeTimer() {
        fadeTimer?.invalidate()
        fadeTimer = nil
    }

    @objc private func handleFadeStep() {
        guard let player = player else {
            stopFadeTimer()
            return
        }
        let now = CACurrentMediaTime()
        let t = min(1.0, (now - fadeStartTime) / fadeDuration)
        let newVol = fadeStartVolume + Float(t) * (fadeTargetVolume - fadeStartVolume)
        player.volume = max(0, min(1, newVol))

        if t >= 1.0 {
            stopFadeTimer()
            if stopAfterFade {
                stop()
            } else if pauseAfterFade {
                pause()
            }
        }
    }
}
