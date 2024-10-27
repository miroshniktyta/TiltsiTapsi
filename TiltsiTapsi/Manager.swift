
import AudioToolbox
import AVFoundation
import SpriteKit
import GameKit

class GameCenterManager: NSObject, GKGameCenterControllerDelegate {

    static let shared = GameCenterManager()
    
    func authenticatePlayer(from viewController: UIViewController) {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { gcAuthVC, error in
            if let vc = gcAuthVC {
                viewController.present(vc, animated: true, completion: nil)
            } else if localPlayer.isAuthenticated {
                print("Player authenticated")
            } else {
                if let error = error {
                    print("Error authenticating player: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Game Center leaderboard UI
    func showLeaderboard(from viewController: UIViewController, leaderboardID: String) {
        let gcVC = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true, completion: nil)
    }
    
    func showGameCenter(from viewController: UIViewController) {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func submitScore(_ score: Double, forGameType gameType: GameType) {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("Player is not authenticated")
            return
        }

        let convertedScore = Int(score * 1000)  // e.g., if score is 1.234, this becomes 1234 (milliseconds)

        let leaderboardID: String
        switch gameType {
        case .gravity:
            leaderboardID = "com.davideberts.gravityScore"
        case .jump:
            leaderboardID = "com.davideberts.jumpScore"
        case .spot:
            leaderboardID = "com.davideberts.tiltTargerScore"
        case .run:
            leaderboardID = "com.davideberts.tiltQuestScore"
        }

        GKLeaderboard.submitScore(convertedScore, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if error != nil {
                print("Error: \(error!.localizedDescription).")
            }
        }
    }
}

class SoundManager {
    
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    var isSoundEnabled: Bool = true
    
    enum SoundType: String, CaseIterable {
        case basso
        case hero
        case morse
        case ping
        case purr
        case pop
        case sosumi
        case tink
        case systemTic
        case systemTap
        case systemTac
        
        var fileName: String? {
            switch self {
            case .basso: return "Basso.aiff"
            case .hero: return "Hero.aiff"
            case .morse: return "Morse.aiff"
            case .ping: return "Ping.aiff"
            case .purr: return "Purr.aiff"
            case .pop: return "Pop.aiff"
            case .sosumi: return "Sosumi.aiff"
            case .tink: return "Tink.aiff"
            case .systemTic, .systemTap, .systemTac: return nil
            }
        }
        
        var systemSoundID: SystemSoundID? {
            switch self {
            case .systemTic:
                return 1103
            case .systemTap:
                return 1104
            case .systemTac:
                return 1105
            default:
                return nil
            }
        }
    }
    
    func play(sound: SoundType) {
        guard isSoundEnabled else { return }

        if let fileName = sound.fileName {
            playSoundFromFile(fileName: fileName)
        } else if let systemSoundID = sound.systemSoundID {
            playSystemSound(systemSoundID: systemSoundID)
        }
    }
    
    private func playSoundFromFile(fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Could not find sound file: \(fileName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    private func playSystemSound(systemSoundID: SystemSoundID) {
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

class SoundAndVibrationMenuScene: BaseMenuScene {

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let buttonWidth = self.buttonWidth / 4
    
        let ar = ActionManager.ActionType.allCases.map { actino in
            return  CustomButtonNode(color: .gray, text: "\(actino.rawValue)", width: buttonWidth) {
                ActionManager.shared.performAction(actino)
            }
        }
        
        buildUI(items: ar)
    }
}

class VibrationManager {
    static let shared = VibrationManager()
    
    var isVibrationEnabled: Bool = true
    
    enum VibrationType: String, CaseIterable {
        case light
        case medium
        case heavy
        case error
    }
    
    func vibrate(type: VibrationType) {
        guard isVibrationEnabled else { return }
        
        switch type {
        case .light:
            AudioServicesPlaySystemSound(1519) // Short, subtle vibration
        case .medium:
            AudioServicesPlaySystemSound(1520) // Medium, noticeable vibration
        case .heavy:
            AudioServicesPlaySystemSound(1521) // Heavy vibration
        case .error:
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // Standard vibration
        }
    }
}

class ActionManager {
    
    static let shared = ActionManager()
    
    enum ActionType: String, CaseIterable {
        case buttonTap
        case itemTap
        case win
        case lose
        case backButtonTap
        case menuAppear
        case ball
        case ball2
    }
    
    func performAction(_ action: ActionType) {
        switch action {
        case .buttonTap:
            SoundManager.shared.play(sound: .systemTac)
            VibrationManager.shared.vibrate(type: .light)
        case .itemTap:
            SoundManager.shared.play(sound: .systemTic)
            VibrationManager.shared.vibrate(type: .medium)
        case .win:
            SoundManager.shared.play(sound: .hero)
//            VibrationManager.shared.vibrate(type: .heavy)
        case .lose:
            SoundManager.shared.play(sound: .basso)
            VibrationManager.shared.vibrate(type: .error)
        case .backButtonTap:
            SoundManager.shared.play(sound: .systemTac)
            VibrationManager.shared.vibrate(type: .light)
        case .menuAppear:
            SoundManager.shared.play(sound: .hero)
            VibrationManager.shared.vibrate(type: .light)
        case .ball:
            SoundManager.shared.play(sound: .systemTap)
            VibrationManager.shared.vibrate(type: .light)
        case .ball2:
            SoundManager.shared.play(sound: .purr)
            VibrationManager.shared.vibrate(type: .light)
        }
    }
}

class SettingsManager {
    static let shared = SettingsManager()
    
    private let userDefaults = UserDefaults.standard
    private let notificationKey = "isNotificationEnabled"
    private let ballColorKey = "selectedBallColor"
    
    var isNotificationEnabled: Bool {
        get {
            return userDefaults.bool(forKey: notificationKey)
        }
        set {
            userDefaults.set(newValue, forKey: notificationKey)
        }
    }
    
    var selectedBallColor: Int {
        get {
            return userDefaults.integer(forKey: ballColorKey)
        }
        set {
            userDefaults.set(newValue, forKey: ballColorKey)
        }
    }
    
    private init() {}
}

class RecordsManager {
    
    static let shared = RecordsManager()
    
    private let userDefaults = UserDefaults.standard
    private let bestTimeKeyPrefix = "bestTime_"
    
    private init() {}
    
    // Function to get the best time for a game
    func getBestTime(for gameType: GameType) -> Double? {
        let key = bestTimeKey(for: gameType)
        return userDefaults.double(forKey: key) != 0 ? userDefaults.double(forKey: key) : nil
    }
    
    // Function to set a new best time for a game
    func setBestTime(for gameType: GameType, time: Double) {
        let key = bestTimeKey(for: gameType)
        userDefaults.set(time, forKey: key)
    }
    
    // Function to check if the new time is better than the previous best time
    func isNewBestTime(for gameType: GameType, time: Double) -> Bool {
        if let bestTime = getBestTime(for: gameType) {
            return time < bestTime
        }
        return true
    }
    
    // Private helper function to generate the UserDefaults key
    private func bestTimeKey(for gameType: GameType) -> String {
        return "\(bestTimeKeyPrefix)\(gameType.rawValue)"
    }
}
