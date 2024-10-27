//
//  MainMenuScene.swift
//  game
//
//  Created by pc on 03.09.24.
//
import SpriteKit
import GameKit

class BaseMenuScene: SKScene, SKPhysicsContactDelegate {

    var buttonWidth: CGFloat { self.size.width / 2.3 }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        self.backgroundColor = .black
        
        let extendedFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height * 2)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: extendedFrame)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9)
        
        self.physicsWorld.contactDelegate = self
    }
    
    func buildUI(items: [SKNode], wait: Double = 0.2) {
        removeCurrentButtons()
                
        var currentY = frame.maxY + frame.height / 2
        
        var i = 0
        
        for button in items.reversed() {
            button.position = CGPoint(
                x: self.size.width / 2 + .random(in: -32...32),
                y: currentY + .random(in: -32...32))
            button.physicsBody?.isDynamic = true
            button.physicsBody?.categoryBitMask = 1
            button.physicsBody?.collisionBitMask = 1
            button.physicsBody?.contactTestBitMask = 1
            self.run(.wait(forDuration: wait * Double(i))) {
                self.addChild(button)
            }
            i += 1
        }
    }
    
    func getContainer() -> SKNode {
        let w = frame.width * 0.9
        let container = SKShapeNode(rectOf: .init(width: w, height: w), cornerRadius: 0)
        container.name = "menu"
        container.physicsBody = .init(rectangleOf: container.calculateAccumulatedFrame().size)
        container.fillColor = .gray.withAlphaComponent(0.5)
        container.strokeColor = .gray
        container.physicsBody?.mass = 1
        container.physicsBody?.friction = 0.4
        container.run(.run {
            container.physicsBody?.applyAngularImpulse(.random(in: -0.5...0.5))
        })
        return container
    }
    
    func removeCurrentButtons() {
        children.forEach {
            if $0.name == "menu" {
                $0.removeFromParent()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        children.forEach {
            if $0.name == "menu" {
//                $0.physicsBody?.applyForce(.init(dx: .random(in: -20...20), dy: .random(in: -20...20)))
                $0.physicsBody?.applyAngularImpulse(CGFloat.random(in: -1...1))
                $0.physicsBody?.applyImpulse(.init(dx: .random(in: -40...40), dy: .random(in: -40...40)))
            }
        }
    }
}

class MenuScene: BaseMenuScene {
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let gravityButton = CustomButtonNode(color: colors[0], text: "Hexa Fall", width: buttonWidth) {
            let sc = MenuGamesCategoryScene(size: self.size)
            sc.selectedGameType = .gravity
            self.view?.presentScene(sc)
        }

        let hopButton = CustomButtonNode(color: colors[1], text: "Penta Jump", width: buttonWidth) {
            let sc = MenuGamesCategoryScene(size: self.size)
            sc.selectedGameType = .jump
            self.view?.presentScene(sc)
        }
        
        let tilt1Button = CustomButtonNode(color: colors[2], text: "Tri Spot", width: buttonWidth) {
            let sc = MenuGamesCategoryScene(size: self.size)
            sc.selectedGameType = .spot
            self.view?.presentScene(sc)
        }

        let tilt2Button = CustomButtonNode(color: colors[3], text: "Quatra Run", width: buttonWidth) {
            let sc = MenuGamesCategoryScene(size: self.size)
            sc.selectedGameType = .run
            self.view?.presentScene(sc)
        }
        
        let settingsButton = CustomButtonNode(color: .gray, text: "Settings", width: buttonWidth / 1.4) {
            self.view?.presentScene(MenuSettingsScene(size: self.size))
        }
        let rulesButton = CustomButtonNode(color: .gray, text: "Rules", width: buttonWidth / 1.4) {
            let stats = StatsData(overage: 0.5, mistakes: 1, fastest: 0.5, time: 0.5)
            let sc = GameOverScene(size: self.size, gameType: .gravity, statsData: stats)
            self.view?.presentScene(sc)
        }
        let gameCenter = CustomButtonNode(color: .gray, text: "Game Center", width: buttonWidth / 1.4) {
            if let vc = self.viewController() {
                GameCenterManager.shared.showGameCenter(from: vc)
            }
        }
        
        let buttons = [gravityButton, hopButton, tilt1Button, tilt2Button, settingsButton, rulesButton, gameCenter]
        buildUI(items: buttons)
    }
}

class MenuGamesCategoryScene: BaseMenuScene {
    var selectedGameType: GameType = .gravity

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        let practiceButton = CustomButtonNode(color: .green, text: "Challenge", width: buttonWidth) {
            self.presentGameScene(isPractice: true)
        }

        let customGameButton = CustomButtonNode(color: .orange, text: "Custom Game", width: buttonWidth) {
            self.presentGameScene(isPractice: false)
        }
        

        let backButton = CustomButtonNode(color: .gray, text: "Back", width: buttonWidth / 1.4) {
            self.view?.presentScene(MenuScene(size: self.size))
        }

        let buttons = [practiceButton, customGameButton, backButton]
        buildUI(items: buttons)
    }

    private func presentGameScene(isPractice: Bool) {
        if !isPractice {
            let scene = MenuSetGameScene(size: self.size)
            scene.gameType = selectedGameType
            self.view?.presentScene(scene)
        } else {
            // Transition based on gameType
            switch selectedGameType {
            case .gravity:
                let sc = GravityScene(size: self.size)
                self.view?.presentScene(sc)
            case .jump:
                let sc = JumpScene(size: self.size)
                self.view?.presentScene(sc)
            case .spot:
                let sc = SpotScene(size: self.size)
                self.view?.presentScene(sc)
            case .run:
                let sc = RunScene(size: self.size)
                self.view?.presentScene(sc)
            }
        }
    }
}

class MenuSettingsScene: BaseMenuScene {
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        let container = getContainer()
        
        let titleArea = container.calculateAccumulatedFrame().size.height * 0.2
        let titleLabel = AppLabelNode(text: "Settings")
        titleLabel.fontSize = titleArea / 2
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: container.frame.height / 2 - titleArea / 2)
        container.addChild(titleLabel)
        
        let ssize = CGSize(width: container.calculateAccumulatedFrame().size.width * 0.75, height: container.calculateAccumulatedFrame().size.height * 0.75)
        let settingsNode = SettingsComponentNode(size: ssize)
        settingsNode.position.y -= container.calculateAccumulatedFrame().size.height * 0.05
        container.addChild(settingsNode)
        container.isUserInteractionEnabled = true
        
        let backButton = CustomButtonNode(color: .gray, text: "Back", width: buttonWidth / 1.4) {
            self.view?.presentScene(MenuScene(size: self.size))
        }
        
        let buttons = [container, backButton]
        buildUI(items: buttons, wait: 0.5)
    }
}
