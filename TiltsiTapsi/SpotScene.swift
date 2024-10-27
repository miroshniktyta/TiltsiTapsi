//
//  SpotScene.swift
//  game
//
//  Created by pc on 04.09.24.
//

import SpriteKit
import CoreMotion

class SpotScene: SKScene, SKPhysicsContactDelegate {

    var motionManager = CMMotionManager()
    var colorsNumber = 4
    var totalBalls: Int = 100
    var aimBalls: Int = 25
    var aimBallColor = UIColor.blue
    var collectedBalls = 0
    var mistakes = 0
    var startTime: TimeInterval = 0
    var balls = [Ball]()
    var recordedReactionTimes: [TimeInterval] = []
    var lastTap = CACurrentMediaTime()
    let appearanceDuration: Double = 2.5
    let navBarHeight: CGFloat = 48

    var isCustom = false

    var aimedBallsLeft: Int {
        return balls.filter { $0.color == aimBallColor }.count
    }
    
    // Labels
    var collectedLabel = AppLabelNode(text: "0")
    var tapToStartLabel = AppLabelNode(text: "Tap to Start")
    var infoLabel: AppLabelNode!

    // Center Square for contact
    lazy var square: Ball = {
        let ballDiameter = calculateBallSize(numberOfBalls: totalBalls)
        return Ball(color: aimBallColor, width: ballDiameter, shapeType: .triangle)
    }()
    
    // Define physics categories
    struct PhysicsCategory {
        static let ball: UInt32 = 1 << 0
        static let square: UInt32 = 1 << 1
        static let border: UInt32 = 1 << 2
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        setupNavBar()
        setupTapToStartLabel()
        setupBorders()
        physicsWorld.contactDelegate = self
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 50,
                                            dy: accelerometerData.acceleration.y * 50)
        }
    }
    
    func setupTapToStartLabel() {
        infoLabel = AppLabelNode(text: "Tilt your phone to move around\nCollect all the BLUE items to win")
        infoLabel.numberOfLines = 0
        infoLabel.fontSize = 18
        infoLabel.fontColor = .white
        infoLabel.position = CGPoint(x: frame.midX, y: frame.midY + 30)
        addChild(infoLabel)
        
        tapToStartLabel.fontSize = 18
        tapToStartLabel.verticalAlignmentMode = .top
        tapToStartLabel.position = CGPoint(x: frame.midX, y: frame.midY - 40)
        addChild(tapToStartLabel)
        tapToStartLabel.run(.repeatForever(.sequence([.scale(by: 1.2, duration: 0.8), .scale(to: 1, duration: 0.7)])))
    }
    
    private func setupNavBar() {
        let navBar = SKShapeNode(rect: CGRect(x: 0, y: frame.height - navBarHeight, width: frame.width, height: navBarHeight))
        navBar.fillColor = .black
        navBar.strokeColor = .clear
        navBar.zPosition = 100
        addChild(navBar)
        
        let ball = Ball(color: aimBallColor, width: 32)
        ball.position = CGPoint(x: frame.maxX - 36, y: frame.height - navBarHeight / 2)
        navBar.addChild(ball)
        
        let backButton = SKShapeNode(rectOf: CGSize(width: 40, height: 30), cornerRadius: 5)
        backButton.fillColor = .clear
        backButton.strokeColor = .clear
        backButton.name = "backButton"
        backButton.position = CGPoint(x: 36, y: frame.height - navBarHeight / 2)
        let backArrow = AppLabelNode(text: "<")
        backArrow.fontColor = .white
        backArrow.fontSize = 32
        backArrow.position = CGPoint(x: 0, y: -10)
        backArrow.verticalAlignmentMode = .center
        backButton.addChild(backArrow)
        navBar.addChild(backButton)
        
        collectedLabel.fontSize = 32
        collectedLabel.horizontalAlignmentMode = .right
        collectedLabel.position = CGPoint(x: ball.frame.minX - 20, y: frame.height - navBarHeight / 2)
        navBar.addChild(collectedLabel)
    }
    
    func setupBorders() {
        let extendedFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height - navBarHeight)
        let borderBody = SKPhysicsBody(edgeLoopFrom: extendedFrame)
        borderBody.categoryBitMask = PhysicsCategory.border
        borderBody.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.square
        self.physicsBody = borderBody
    }
    
    func startGame() {
        tapToStartLabel.removeFromParent()
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        setupCenterSquare()
        spawnBalls()
    }
    
    func setupCenterSquare() {
        square.position = CGPoint(x: frame.midX, y: frame.midY)
        square.createPhysicsBody()
        square.physicsBody?.isDynamic = false
        square.physicsBody?.categoryBitMask = PhysicsCategory.square
        square.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        addChild(square)
    }
    
    func spawnBalls() {
        let ballDiameter = calculateBallSize(numberOfBalls: totalBalls)
        let delayPerBall = appearanceDuration / Double(totalBalls)
        
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnBall(size: ballDiameter)
        }
        
        let spawnSequence = SKAction.sequence([spawnAction, SKAction.wait(forDuration: delayPerBall)])
        let repeatSpawn = SKAction.repeat(spawnSequence, count: totalBalls)
        
        run(repeatSpawn) { [weak self] in
            self?.colorBalls()
            self?.startTime = CACurrentMediaTime()
            self?.motionManager.startAccelerometerUpdates()
        }
    }
    
    func spawnBall(size: CGFloat) {
        let ball = Ball(color: .gray, width: size)
        ball.position = CGPoint(
            x: CGFloat.random(in: frame.minX + size / 2...frame.maxX - size / 2),
            y: CGFloat.random(in: frame.minY + size / 2...frame.maxY - size / 2 - navBarHeight)
        )
        
        ball.createPhysicsBody()
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 0.3
        ball.physicsBody?.friction = 0.3
        ball.physicsBody?.density = 1.0
        ball.physicsBody?.allowsRotation = true
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.square
        
        addChild(ball)
        balls.append(ball)
        
        ActionManager.shared.performAction(.ballAppear)
    }
    
    func colorBalls() {
        let colorsToUse = Array(colors.filter { $0 != aimBallColor }.prefix(colorsNumber - 1))
        guard colorsToUse.count + 1 == colorsNumber else { return }
        
        var colorAssignments = Array(repeating: aimBallColor, count: aimBalls)
        let remainingBallsCount = totalBalls - aimBalls
        let ballCountPerColor = remainingBallsCount / colorsToUse.count
        let remainingBallsAfterDistribution = remainingBallsCount % colorsToUse.count

        for color in colorsToUse {
            colorAssignments.append(contentsOf: Array(repeating: color, count: ballCountPerColor))
        }
        
        let remainingColorAssignments = colorsToUse.shuffled().prefix(remainingBallsAfterDistribution)
        colorAssignments.append(contentsOf: remainingColorAssignments)
        colorAssignments.shuffle()
        
        for (index, ball) in balls.enumerated() where index < colorAssignments.count {
            ball.color = colorAssignments[index]
        }
        
        collectedLabel.text = "\(aimedBallsLeft)"
    }
    
    func calculateBallSize(numberOfBalls: Int) -> CGFloat {
        let screenArea = self.size.width * self.size.height
        let totalBallArea = screenArea * 0.5
        let ballArea = totalBallArea / CGFloat(numberOfBalls)
        return sqrt(ballArea / .pi) * 2
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard startTime > 0 else { return }
        
        let (firstBody, secondBody) = contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask ?
            (contact.bodyA, contact.bodyB) : (contact.bodyB, contact.bodyA)
        
        if firstBody.categoryBitMask == PhysicsCategory.ball && secondBody.categoryBitMask == PhysicsCategory.square {
            if let ball = firstBody.node as? Ball {
                handleBallContact(ball: ball)
            }
        }
    }
    
    func handleBallContact(ball: Ball) {
        if ball.color == aimBallColor {
            ball.boom()
            if let index = balls.firstIndex(of: ball) {
                balls.remove(at: index)
            }
            collectedBalls += 1
            collectedLabel.text = "\(aimedBallsLeft)"
            ActionManager.shared.performAction(.itemCollected)
        }

        if balls.filter({ $0.color == aimBallColor }).isEmpty {
            gameOver()
        }
    }
    
    func gameOver() {
        let totalTime = CACurrentMediaTime() - startTime
        let reaction = totalTime / Double(collectedBalls)
        let fastest = recordedReactionTimes.min() ?? reaction
        
        let statsData = StatsData(overage: reaction, mistakes: mistakes, fastest: fastest, time: totalTime)
        let sc = GameOverScene(size: self.view?.frame.size ?? .zero, gameType: .spot, statsData: statsData, isCustom: isCustom)
        
        self.view?.presentScene(sc)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesArray = nodes(at: location)

        if let backButtonNode = nodesArray.first(where: { $0.name == "backButton" }) {
            ActionManager.shared.performAction(.buttonTap)
            transitionBackToMenu()
            return
        }

        if tapToStartLabel.parent != nil {
            tapToStartLabel.removeFromParent()
            infoLabel.removeFromParent() // Remove info label as well
            startGame()
        }
    }

    func transitionBackToMenu() {
        let sc = MenuScene(size: self.size)
        self.view?.presentScene(sc)
    }
    
}
