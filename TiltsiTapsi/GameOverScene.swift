//
//  GameOverScene.swift
//  TiltsiTapsi
//
//  Created by pc on 27.10.24.
//

import SpriteKit

class GameOverScene: BaseMenuScene {
    
    let statsData: StatsData
    let gameType: GameType
    let isCustom: Bool
    
    init(size: CGSize, gameType: GameType, statsData: StatsData, isCustom: Bool = true) {
        self.statsData = statsData
        self.gameType = gameType
        self.isCustom = isCustom
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let resultDescription = isCustom ? nil : generateResultDescription(for: gameType, with: statsData)
        
        let container = getContainer()
        let settingsNode = StatsDisplayNode(
            size: CGSize(width: container.calculateAccumulatedFrame().size.width * 0.75, height: container.calculateAccumulatedFrame().size.height * 0.70),
            statsData: statsData,
            resultDescription: resultDescription
        )
        settingsNode.position.y -= container.calculateAccumulatedFrame().size.height * 0.05
        container.addChild(settingsNode)
        container.isUserInteractionEnabled = true
        
        let backButton = CustomButtonNode(color: .gray, text: "Back", width: buttonWidth / 1.4) {
            self.view?.presentScene(MenuScene(size: self.size))
        }
        
        let buttons = [container, backButton]
        buildUI(items: buttons, wait: 0.5)
        
        ActionManager.shared.performAction(.win)
    }
    
    private func generateResultDescription(for gameType: GameType, with stats: StatsData) -> String {
        let mistakes = stats.mistakes
        let reactionTime = stats.time

        // Check if accuracy is 100%
        if mistakes < 1 {
            return "You need 100% accuracy to compete."
        }

        // Check if it's a new best record
        if RecordsManager.shared.isNewBestTime(for: gameType, time: reactionTime) {
            RecordsManager.shared.setBestTime(for: gameType, time: reactionTime)
            GameCenterManager.shared.submitScore(reactionTime, forGameType: gameType)
            return String(format: "🎉 New best time: %.2f s 🎉", reactionTime)
        } else if let bestTime = RecordsManager.shared.getBestTime(for: gameType) {
            return String(format: "Best time: %.2f s", bestTime)
        } else {
            return String(format: "Your time: %.2f s", reactionTime)
        }
    }
}

class MenuRulesScene: BaseMenuScene {
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let container = getContainer()
        
        let titleArea = container.calculateAccumulatedFrame().size.height * 0.2
        let titleLabel = AppLabelNode(text: "Rules")
        titleLabel.fontSize = titleArea / 2
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: container.frame.height / 2 - titleArea / 2)
        container.addChild(titleLabel)
        
        let ssize = CGSize(width: container.calculateAccumulatedFrame().size.width * 0.85, height: container.calculateAccumulatedFrame().size.height * 0.75)
        let container2 = SKShapeNode(rectOf: ssize, cornerRadius: 20)
        container2.position.y -= container.calculateAccumulatedFrame().size.height * 0.05
        container2.fillColor = .black.withAlphaComponent(0.5)
        container2.strokeColor = .black
        container2.lineWidth = 1
        container2.zPosition = 1
        container.addChild(container2)
        
        // Rules text label
        let rulesText = """
        Tap the aim ball as fast as you can in Tap Gravity and Tap Hop Pop!
         
        In Tilt games, steer the ball into the target by tilting your device.
        
        Customize Practice Mode with unique ball numbers and colors for your personal challenge!
        
        Test your reflexes and precision!
        """
        
        let rulesLabel = AppLabelNode(text: rulesText)
        rulesLabel.fontSize = container2.calculateAccumulatedFrame().height / 20
        rulesLabel.fontColor = .white
        rulesLabel.position = CGPoint(x: 0, y: titleLabel.position.y - 32)
        rulesLabel.verticalAlignmentMode = .top
        rulesLabel.numberOfLines = 0
        rulesLabel.preferredMaxLayoutWidth = container2.calculateAccumulatedFrame().width - 20
        container2.addChild(rulesLabel)
        
        // Back button
        let backButton = CustomButtonNode(color: .gray, text: "Back", width: buttonWidth / 1.4) {
            self.view?.presentScene(MenuScene(size: self.size))
        }
        let buttons = [container, backButton]
        buildUI(items: buttons, wait: 0.5)
    }
}

class MenuSetGameScene: BaseMenuScene {
    
    var gameSettingsNode: CustomGameSettingNode!
    var gameType: GameType = .gravity
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let container = getContainer()
        
        let titleArea = container.calculateAccumulatedFrame().size.height * 0.2
        let titleLabel = AppLabelNode(text: "Custom")
        titleLabel.fontSize = titleArea / 2
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: container.frame.height / 2 - titleArea / 2)
        container.addChild(titleLabel)
        
        let settingsNode = CustomGameSettingNode(size: CGSize(width: container.calculateAccumulatedFrame().size.width * 0.75, height: container.calculateAccumulatedFrame().size.height * 0.75))
        settingsNode.position.y -= container.calculateAccumulatedFrame().size.height * 0.05
        container.addChild(settingsNode)
        container.isUserInteractionEnabled = true
        gameSettingsNode = settingsNode
        
        let playButton = CustomButtonNode(color: .green, text: "Play", width: buttonWidth) {
            if let settings = self.gameSettingsNode {
                switch self.gameType {
                case .gravity:
                    let scene = GravityScene(size: self.size)
                    scene.isCustom = true
                    scene.aimBalls = settings.getAimBalls()
                    scene.colorsNumber = settings.getColorsNumber()
                    scene.totalBalls = settings.getTotalBalls()
                    self.view?.presentScene(scene)
                case .jump:
                    let scene = JumpScene(size: self.size)
                    scene.isCustom = true
                    scene.aimBalls = settings.getAimBalls()
                    scene.colorsNumber = settings.getColorsNumber()
                    scene.totalBalls = settings.getTotalBalls()
                    self.view?.presentScene(scene)
                case .spot:
                    let scene = SpotScene(size: self.size)
                    scene.isCustom = true
                    scene.aimBalls = settings.getAimBalls()
                    scene.colorsNumber = settings.getColorsNumber()
                    scene.totalBalls = settings.getTotalBalls()
                    self.view?.presentScene(scene)
                case .run:
                    let scene = RunScene(size: self.size)
                    scene.isCustom = true
                    scene.aimBalls = settings.getAimBalls()
                    scene.colorsNumber = settings.getColorsNumber()
                    scene.totalBalls = settings.getTotalBalls()
                    self.view?.presentScene(scene)                }
            }
        }
        
        let backButton = CustomButtonNode(color: .gray, text: "Back", width: buttonWidth / 1.4) {
            self.view?.presentScene(MenuScene(size: self.size))
        }
        
        let buttons = [container, playButton, backButton]
        buildUI(items: buttons, wait: 0.5)
    }
}
