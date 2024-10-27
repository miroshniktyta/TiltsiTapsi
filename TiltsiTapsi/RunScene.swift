import SpriteKit
import CoreMotion

class RunScene: SKScene, SKPhysicsContactDelegate {

    var colorsNumber = 4
    var totalBalls: Int = 100
    var aimBalls: Int = 25
    var aimBallColor = UIColor.orange
    var collectedBalls = 0
    var mistakes = 0
    var startTime: TimeInterval = 0
    var balls = [Ball]()
    var recordedReactionTimes: [TimeInterval] = []
    var lastTap = CACurrentMediaTime()
    let appearanceDuration: Double = 2.5
    let navBarHeight: CGFloat = 48
    var motionManager = CMMotionManager()
    
    var isCustom = false

    var aimedBallsLeft: Int {
        return balls.filter { $0.color == aimBallColor }.count
    }
    // Labels
    var collectedLabel = AppLabelNode(text: "0")
    var tapToStartLabel = AppLabelNode(text: "Tap to Start")
    var infoLabel: AppLabelNode!
    
    // Square in the game
    lazy var squareC: Ball = {
        let ballDiameter = calculateBallSize(numberOfBalls: totalBalls)
        return Ball(color: aimBallColor, width: ballDiameter, shapeType: .square)
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
    
    func setupTapToStartLabel() {
        infoLabel = AppLabelNode(text: "Tilt your phone to move around\nCollect all the ORANGE items to win")
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
    
    func setupBorders() {
        let extendedFrame = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: frame.height - navBarHeight
        )

        let borderBody = SKPhysicsBody(edgeLoopFrom: extendedFrame)
        borderBody.categoryBitMask = PhysicsCategory.border
        borderBody.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.square
        self.physicsBody = borderBody
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
    
    func startGame() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        setupMovableSquare()
        spawnBalls()
    }
    
    func setupMovableSquare() {
        squareC.position = CGPoint(x: frame.midX, y: frame.midY)
        squareC.createPhysicsBody()
        squareC.physicsBody?.isDynamic = true
        squareC.physicsBody?.affectedByGravity = false
        squareC.physicsBody?.allowsRotation = true
        squareC.physicsBody?.categoryBitMask = PhysicsCategory.square
        squareC.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        squareC.physicsBody?.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.border
        addChild(squareC)
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
            self?.squareC.physicsBody?.affectedByGravity = true
            self?.motionManager.startAccelerometerUpdates()
        }
    }
    
    func spawnBall(size: CGFloat) {
        let ball = Ball(color: .gray, width: size)
        ball.position = CGPoint(
            x: CGFloat.random(in: frame.minX + size / 2...frame.maxX - size / 2),
            y: CGFloat.random(in: frame.minY + size / 2...frame.maxY - size / 2 - navBarHeight)
        )

        ball.physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.allowsRotation = true
        ball.physicsBody?.categoryBitMask = PhysicsCategory.ball
        ball.physicsBody?.contactTestBitMask = PhysicsCategory.square
        ball.physicsBody?.collisionBitMask = PhysicsCategory.ball | PhysicsCategory.square | PhysicsCategory.border

        addChild(ball)
        balls.append(ball)
        
        ActionManager.shared.performAction(.ballAppear)
    }
    
    func colorBalls() {
        // Choose non-target colors, excluding `aimBallColor`
        let allAvailableColors = colors.filter { $0 != aimBallColor }
        guard allAvailableColors.count >= colorsNumber - 1 else {
            print("Error: Not enough colors to distribute.")
            return
        }
        
        // Get random non-target colors
        let colorsToUse = Array(allAvailableColors.prefix(colorsNumber - 1))
        
        // Create color assignments for target and non-target balls
        var colorAssignments = Array(repeating: aimBallColor, count: aimBalls)
        let remainingBallsCount = totalBalls - aimBalls
        let ballCountPerColor = remainingBallsCount / colorsToUse.count
        let remainingBallsAfterDistribution = remainingBallsCount % colorsToUse.count

        // Distribute non-target colors evenly
        for color in colorsToUse {
            colorAssignments.append(contentsOf: Array(repeating: color, count: ballCountPerColor))
        }
        
        // Add remaining balls with random colors from non-target colors
        let remainingColorAssignments = colorsToUse.shuffled().prefix(remainingBallsAfterDistribution)
        colorAssignments.append(contentsOf: remainingColorAssignments)
        colorAssignments.shuffle() // Randomize ball color order

        // Apply color assignments to each ball
        for (index, ball) in balls.enumerated() where index < colorAssignments.count {
            ball.color = colorAssignments[index]
        }
        
        // Update the collected label to show remaining target balls
        collectedLabel.text = "\(aimedBallsLeft)"
    }
    
    func calculateBallSize(numberOfBalls: Int) -> CGFloat {
        let screenArea = self.size.width * self.size.height
        let totalBallArea = screenArea * 0.5
        let ballArea = totalBallArea / CGFloat(numberOfBalls)
        return sqrt(ballArea / .pi) * 2
    }
    
    func gameOver() {
        let totalTime = CACurrentMediaTime() - startTime
        let reaction = totalTime / Double(collectedBalls)
        let speed = recordedReactionTimes.min() ?? reaction
        let statsData = StatsData(overage: reaction, mistakes: mistakes, fastest: speed, time: totalTime)
        let sc = GameOverScene(size: self.view?.frame.size ?? .zero, gameType: .run, statsData: statsData, isCustom: isCustom)
        
        self.view?.presentScene(sc)
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

    override func update(_ currentTime: TimeInterval) {
        if let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(
                dx: accelerometerData.acceleration.x * 30,
                dy: accelerometerData.acceleration.y * 30
            )
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesArray = nodes(at: location)

        if let backButtonNode = nodesArray.first(where: { $0.name == "backButton" }) {
            transitionBackToMenu()
            ActionManager.shared.performAction(.buttonTap)
            return
        }
        
        if tapToStartLabel.parent != nil {
            tapToStartLabel.removeFromParent()
            infoLabel.removeFromParent() // Remove info label as well
            startGame()
            return
        }
    }

    func transitionBackToMenu() {
        let sc = MenuScene(size: self.size)
        self.view?.presentScene(sc)
    }
}
