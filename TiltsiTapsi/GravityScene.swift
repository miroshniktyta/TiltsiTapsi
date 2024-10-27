//
//  GravityScene.swift
//  game
//
//  Created by pc on 04.09.24.
//

import SpriteKit
import SpriteKit

class GravityScene: SKScene {
    
    var totalBalls: Int = 80
    var aimBalls: Int = 20
    var isCustom = false
    var aimBallColor = UIColor.red
    var colorsNumber = 4
    var collectedBalls = 0
    var mistakes = 0
    var startTime: TimeInterval = 0
    var balls = [Ball]()
    var recordedReactionTimes: [TimeInterval] = []
    var lastTap = CACurrentMediaTime()
    let appearanceDuration: Double = 2.5
    let navBarHeight: CGFloat = 48
    
    // Labels
    var collectedLabel = AppLabelNode(text: "0")
    var tapToStartLabel = AppLabelNode(text: "Tap to Start")
    var infoLabel: AppLabelNode!
    
    var gravityAngle: CGFloat = 0.0
    
    var aimedBallsLeft: Int {
        return balls.filter { $0.color == aimBallColor }.count
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        setupNavBar()
        setupTapToStartLabel()
    }
    
    private func setupNavBar() {
        let navBar = SKShapeNode(rect: CGRect(x: 0, y: frame.height - navBarHeight, width: frame.width, height: navBarHeight))
        navBar.fillColor = .black
        navBar.strokeColor = .clear
        navBar.zPosition = 100
        addChild(navBar)
        
        let ball = Ball(color: aimBallColor, width: 32, shapeType: .hexagon)
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
    
    func setupTapToStartLabel() {
        infoLabel = AppLabelNode(text: "Tap all RED items as soon as possible.")
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
    
    func startGame() {
        let ballDiameter = calculateBallSize(numberOfBalls: totalBalls)
        let delayPerBall = appearanceDuration / Double(totalBalls)
        
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnBall(size: ballDiameter)
        }
        
        let spawnSequence = SKAction.sequence([spawnAction, SKAction.wait(forDuration: delayPerBall)])
        let repeatSpawn = SKAction.repeat(spawnSequence, count: totalBalls)
        
        let extendedFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height - navBarHeight)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: extendedFrame)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0) // Disable gravity
        
        run(repeatSpawn) { [weak self] in
            self?.colorBalls()
            self?.startTime = CACurrentMediaTime()
        }
    }
    
    func spawnBall(size: CGFloat) {
        let ball = Ball(color: .gray, width: size, shapeType: .hexagon)
        ball.position = CGPoint(x: frame.midX + .random(in: -5...5), y: frame.midY + .random(in: -5...5))
        
        ball.createPhysicsBody()
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 0.8
        ball.physicsBody?.friction = 0.3
        ball.physicsBody?.density = 1.0
        ball.physicsBody?.allowsRotation = true
        
        addChild(ball)
        balls.append(ball)
        
        ActionManager.shared.performAction(.ballAppear)
    }
    
    func colorBalls() {
        let colorsToUse = Array(colors.filter { $0 != aimBallColor }.prefix(colorsNumber - 1))
        
        guard colorsToUse.count + 1 == colorsNumber else {
            print("Error: Insufficient unique colors available.")
            return
        }
        
        var colorAssignments = Array(repeating: aimBallColor, count: aimBalls)
        let remainingBallsCount = totalBalls - aimBalls
        let ballCountPerRestColor = remainingBallsCount / colorsToUse.count
        let remainingBallsAfterDistribution = remainingBallsCount % colorsToUse.count
        
        for color in colorsToUse {
            let count = ballCountPerRestColor
            colorAssignments.append(contentsOf: Array(repeating: color, count: count))
        }
        
        let remainingColorAssignments = colorsToUse.shuffled().prefix(remainingBallsAfterDistribution)
        colorAssignments.append(contentsOf: remainingColorAssignments)
        
        colorAssignments.shuffle()
        
        for (index, ball) in balls.enumerated() {
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
    
    override func update(_ currentTime: TimeInterval) {
        if startTime > 0 {
            let gravitySpeed: CGFloat = 0.02
            gravityAngle += gravitySpeed
            let gravityDirection = CGVector(dx: cos(gravityAngle) * 5, dy: sin(gravityAngle) * 5)
            physicsWorld.gravity = gravityDirection
        }
    }
    
    func gameOver() {
        let totalTime = CACurrentMediaTime() - startTime
        
        let reaction = totalTime / Double(collectedBalls)
        let fastest = recordedReactionTimes.min() ?? reaction
        
        let statsData = StatsData(overage: reaction, mistakes: mistakes, fastest: fastest, time: totalTime)
        let sc = GameOverScene(size: self.view?.frame.size ?? .zero, gameType: .gravity, statsData: statsData, isCustom: isCustom)
        
        self.view?.presentScene(sc)
    }
    
    func transitionBackToMenu() {
        let sc = MenuScene(size: self.size)
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
            infoLabel.removeFromParent()
            startGame()
            return
        }
        
        guard startTime > 0 else { return }

        if let ballNode = nodesArray.first(where: { $0 is Ball }) as? Ball {
            if ballNode.color == aimBallColor {
                ballNode.boom()
                balls.removeAll { $0 == ballNode }
                collectedBalls += 1
                collectedLabel.text = "\(aimedBallsLeft)"
                
                let reactionTime = CACurrentMediaTime() - lastTap
                recordedReactionTimes.append(reactionTime)
                ActionManager.shared.performAction(.itemCollected)
            } else {
                backgroundColor = .red
                run(.wait(forDuration: 0.25)) { self.backgroundColor = .black }
                mistakes += 1
                ActionManager.shared.performAction(.error)
            }
            lastTap = CACurrentMediaTime()
            if balls.filter({ $0.color == aimBallColor }).isEmpty {
                gameOver()
            }
        }
    }
}
