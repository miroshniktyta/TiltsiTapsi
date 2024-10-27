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
    var totalBalls: Int = 80
    var aimBalls: Int = 20
    var aimBallColor = UIColor.red
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

    // Center Square for contact
    lazy var square: Ball = {
        let ballDiameter = calculateBallSize(numberOfBalls: totalBalls)
        let color = colors[SettingsManager.shared.selectedBallColor]
        return Ball(color: color, width: ballDiameter, shapeType: .triangle)
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
        tapToStartLabel.fontSize = 32
        tapToStartLabel.verticalAlignmentMode = .top
        tapToStartLabel.position = CGPoint(x: frame.midX, y: frame.midY - 8)
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
            transitionBackToMenu()
            return
        }

        if tapToStartLabel.parent != nil {
            tapToStartLabel.removeFromParent()
            startGame()
        }
    }

    func transitionBackToMenu() {
        let sc = MenuScene(size: self.size)
        self.view?.presentScene(sc)
    }
    
}
//
//class TiltScene: BaseGameScene, SKPhysicsContactDelegate {
//    
//    var motionManager = CMMotionManager()
//    
//    let instructionNode = SKNode()
//    let tiltUpLabel = AppLabelNode(text: "Tilt Up to Start")
//    let tiltDownLabel = AppLabelNode(text: "Tilt Down to Start")
//
//    var isTiltUpCompleted = false
//    var isTiltDownCompleted = false
//    
//    required init(size: CGSize) {
//        super.init(size: size)
//        self.totalBalls = 80  // default values
//        self.aimBalls = 20  // default values
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        self.totalBalls = 80  // default values
//        self.aimBalls = 20  // default values
//    }
//    
//    override func didMove(to view: SKView) {
//        super.didMove(to: view)
//        setupInstructionLabels()
//        
//        let extendedFrame = CGRect(
//            x: frame.minX,
//            y: frame.minY,
//            width: frame.width,
//            height: frame.height - navBarHeight)
//
//        self.physicsBody = SKPhysicsBody(edgeLoopFrom: extendedFrame)
//        self.physicsWorld.contactDelegate = self
//    }
//    
//    func setupInstructionLabels() {
//        instructionNode.position = CGPoint(x: frame.midX, y: frame.midY)
//        
//        let labels = [tapToStartLabel, tiltUpLabel, tiltDownLabel]
//        let positions: [CGFloat] = [40, 0, -40]
//        
//        for (label, offsetY) in zip(labels, positions) {
//            label.fontSize = 32
//            label.verticalAlignmentMode = .center
//            label.horizontalAlignmentMode = .center
//            label.position = CGPoint(x: 0, y: offsetY)
//            instructionNode.addChild(label)
//        }
//        
//        addChild(instructionNode)
//        
//        instructionNode.physicsBody = SKPhysicsBody(rectangleOf: instructionNode.calculateAccumulatedFrame().size)
//        instructionNode.physicsBody?.isDynamic = true
//        instructionNode.physicsBody?.affectedByGravity = false
//    }
//        
//    lazy var square: Ball = {
//        let ballDiameter = calculateBallSize(numberOfBalls: totalBalls)
//        let color = colors[SettingsManager.shared.selectedBallColor]
//        let sq = Ball(color: color, width: ballDiameter, shapeType: .triangle)
//
//        return sq
//    }()
//    
//    
//    override func gameOver() {
//        let totalTime = CACurrentMediaTime() - startTime
//        
//        let reaction = totalTime / Double(collectedBalls)
//        let accuracy = Double(collectedBalls) / Double(collectedBalls + mistakes)
//        let speed = recordedReactionTimes.min() ?? reaction
//        
//        let statsData = StatsData(reaction: reaction, accuracy: accuracy, speed: speed, time: totalTime)
//
//        let sc = GameOverScene(size: self.view?.frame.size ?? .zero, gameType: .spot, statsData: statsData, isCustom:  isCustom)
//        
//        self.view?.presentScene(sc)
//    }
//    
//    override func startGame() {
//        instructionNode.removeFromParent()
//        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
//        motionManager = CMMotionManager()
//        
//        setupCenterSquare()
//
//        let ballDiameter = calculateBallSize(numberOfBalls: totalBalls)
//        let delayPerBall = appearanceDuration / Double(totalBalls)
//
//        let spawnAction = SKAction.run { [weak self] in
//            self?.spawnBall(size: ballDiameter)
//        }
//
//        let spawnSequence = SKAction.sequence([spawnAction, SKAction.wait(forDuration: delayPerBall)])
//        let repeatSpawn = SKAction.repeat(spawnSequence, count: totalBalls)
//
//        let extendedFrame = CGRect(
//            x: frame.minX,
//            y: frame.minY,
//            width: frame.width,
//            height: frame.height - navBarHeight)
//        
//        // Set up physics border and disable gravity
//        self.physicsBody = SKPhysicsBody(edgeLoopFrom: extendedFrame)
//        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
//        self.physicsWorld.contactDelegate = self
//        
//        // Start spawning balls and enable motion
//        run(repeatSpawn) { [weak self] in
//            self?.colorBalls()
//            self?.startTime = CACurrentMediaTime()
//            self?.motionManager.startAccelerometerUpdates()
//        }
//    }
//
//    override func update(_ currentTime: TimeInterval) {
//        if let accelerometerData = motionManager.accelerometerData {
//            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 50,
//                                            dy: accelerometerData.acceleration.y * 50)
//        }
//
//        if instructionNode.parent != nil {
//            checkInstructionNodePosition()
//        }
//    }
//    
//    func checkInstructionNodePosition() {
//        // Check if instruction node is at the bottom
//        if instructionNode.calculateAccumulatedFrame().minY <= 8 + frame.minY && !isTiltDownCompleted {
//            tiltDownLabel.fontColor = .green
//            isTiltDownCompleted = true
//        }
//        // Check if instruction node is at the top
//        if instructionNode.calculateAccumulatedFrame().maxY >= frame.maxY - 8 - navBarHeight && !isTiltUpCompleted {
//            tiltUpLabel.fontColor = .green
//            isTiltUpCompleted = true
//        }
//
//        // Check if both tilts are completed
//        if isTiltUpCompleted && isTiltDownCompleted {
//            startGame()
//        }
//    }
//
//    func setupCenterSquare() {
//        square.position = CGPoint(x: frame.midX, y: frame.midY)
//        square.createPhysicsBody()
//        square.physicsBody?.isDynamic = false // The square won't move
//        square.physicsBody?.categoryBitMask = 1 << 1 // Custom category for the square
//        square.physicsBody?.contactTestBitMask = 1 << 0 // Detect collision with balls
//        
//        addChild(square)
//    }
//
//    func spawnBall(size: CGFloat) {
//        let ball = Ball(color: .gray, width: size)
//        ball.position = CGPoint(x: CGFloat.random(in: frame.minX + size/2...frame.maxX - size/2),
//                                y: CGFloat.random(in: frame.minY + size/2...frame.maxY - size/2 - navBarHeight))
//        // Add physics to the ball
//        ball.createPhysicsBody()
//        ball.physicsBody?.isDynamic = true
//        ball.physicsBody?.restitution = 0.3
//        ball.physicsBody?.friction = 0.3
//        ball.physicsBody?.density = 1.0
//        ball.physicsBody?.allowsRotation = true
//        ball.physicsBody?.categoryBitMask = 1 << 0 // Custom category for the ball
//        ball.physicsBody?.contactTestBitMask = 1 << 1 // Detect contact with the square
//
//        addChild(ball)
//        balls.append(ball)
//        
//        ActionManager.shared.performAction(.ball)
//    }
//
//    // Handle contact between balls and square
//    func didBegin(_ contact: SKPhysicsContact) {
//        guard startTime > 0 else { return }
//        
//        let contactA = contact.bodyA.node
//        let contactB = contact.bodyB.node
//
//        // Determine if a ball made contact with the square
//        if let ball = contactA as? Ball, contactB == square || contactB == square {
//            handleBallContact(ball: ball)
//        } else if let ball = contactB as? Ball, contactA == square || contactA == square {
//            handleBallContact(ball: ball)
//        }
//    }
//
//    func handleBallContact(ball: Ball) {
//        // Remove the ball if it has the aimBallColor
//        if ball.color == aimBallColor {
//            ball.boom()
//            if let index = balls.firstIndex(of: ball) {
//                balls.remove(at: index)
//            }
//            collectedBalls += 1
//            collectedLabel.text = "\(aimedBallsLeft)"
//            
//            ActionManager.shared.performAction(.ball2)
//        }
//        
//        // Check if the game is over (all aim color balls collected)
//        if balls.filter({ $0.color == aimBallColor }).isEmpty {
//            gameOver()
//            print("Game Over")
//        }
//    }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else { return }
//        let location = touch.location(in: self)
//        let nodesArray = nodes(at: location)
//
//        if let backButtonNode = nodesArray.first(where: { $0.name == "backButton" }) {
//            transitionBackToMenu()
//        }
//        
//        if instructionNode.parent != nil {
//            tapToStartLabel.fontColor = .green
//            instructionNode.physicsBody?.affectedByGravity = true
//            motionManager.startAccelerometerUpdates()
//            return
//        }
//    }
//}
//
//
//class BaseGameScene: SKScene {
//    
//    var totalBalls: Int
//    var aimBalls: Int
//    var isCustom = false
//    var aimBallColor = UIColor.red
//    
//    var aimedBallsLeft: Int {
//        return balls.filter { $0.color == aimBallColor }.count
//    }
//    
//    required override init(size: CGSize) {
//        self.totalBalls = 50
//        self.aimBalls = 12
//        super.init(size: size)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        self.totalBalls = 50
//        self.aimBalls = 12
//        super.init(coder: aDecoder)
//    }
//    
//    var colorsNumber = 4
//    var collectedBalls = 0
//    var mistakes = 0
//    var startTime: TimeInterval = 0
//    var balls = [Ball]()
//    var recordedReactionTimes: [TimeInterval] = []
//    var lastTap = CACurrentMediaTime()
//
//    let appearanceDuration: Double = 2.5
//    let navBarHeight: CGFloat = 48
//
//    var collectedLabel = AppLabelNode(text: "0")
//    var tapToStartLabel = AppLabelNode(text: "Tap to Start")
//        
//    override func didMove(to view: SKView) {
//        self.backgroundColor = .black
//        setupNavBar()
//    }
//    
//    private func setupNavBar() {
//        let navBar = SKShapeNode(rect: CGRect(x: 0, y: frame.height - navBarHeight, width: frame.width, height: navBarHeight))
//        navBar.fillColor = .black
//        navBar.strokeColor = .clear
//        navBar.zPosition = 100
//        addChild(navBar)
//        
//        let ball = Ball(color: aimBallColor, width: 32)
////        ball.isUserInteractionEnabled = false
//        ball.position = CGPoint(x: frame.maxX - 36, y: frame.height - navBarHeight / 2)
//        navBar.addChild(ball)
//        
//        let backButton = SKShapeNode(rectOf: CGSize(width: 40, height: 30), cornerRadius: 5)
//        backButton.fillColor = .clear
//        backButton.strokeColor = .clear
//        backButton.name = "backButton"
//        backButton.position = CGPoint(x: 36, y: frame.height - navBarHeight / 2)
//        let backArrow = AppLabelNode(text: "<")
//        backArrow.fontColor = .white
//        backArrow.fontSize = 32
//        backArrow.position = CGPoint(x: 0, y: -10)
//        backArrow.verticalAlignmentMode = .center
//        backButton.addChild(backArrow)
//        navBar.addChild(backButton)
//        
//        collectedLabel.fontSize = 32
//        collectedLabel.horizontalAlignmentMode = .right
//        collectedLabel.position = CGPoint(x: ball.frame.minX - 20, y: frame.height - navBarHeight / 2)
//        navBar.addChild(collectedLabel)
//    }
//    
//    func setupTapToStartLabel() {
//        tapToStartLabel.fontSize = 32
//        tapToStartLabel.verticalAlignmentMode = .top
//        tapToStartLabel.position = CGPoint(x: frame.midX, y: frame.midY - 8)
//        addChild(tapToStartLabel)
//        tapToStartLabel.run(.repeatForever(.sequence([.scale(by: 1.2, duration: 0.8), .scale(to: 1, duration: 0.7)])))
//    }
//    
//    func colorBalls() {
//        let colorsToUse = Array(colors.filter { $0 != aimBallColor }.prefix(colorsNumber - 1))
//        
//        // Check that there are enough colors to distribute
//        guard colorsToUse.count + 1 == colorsNumber else {
//            print("Error: Insufficient unique colors available.")
//            return
//        }
//        
//        // Distribute aimBalls first
//        var colorAssignments = Array(repeating: aimBallColor, count: aimBalls)
//        
//        // Calculate remaining balls that need to be colored
//        let remainingBallsCount = totalBalls - aimBalls
//        let ballCountPerRestColor = remainingBallsCount / colorsToUse.count
//        let remainingBallsAfterDistribution = remainingBallsCount % colorsToUse.count
//        
//        // Assign even distribution for the remaining colors
//        for color in colorsToUse {
//            let count = ballCountPerRestColor
//            colorAssignments.append(contentsOf: Array(repeating: color, count: count))
//        }
//        
//        // Assign remaining balls to random colors from the rest
//        let remainingColorAssignments = colorsToUse.shuffled().prefix(remainingBallsAfterDistribution)
//        colorAssignments.append(contentsOf: remainingColorAssignments)
//        
//        // Shuffle the color assignments for a more random distribution
//        colorAssignments.shuffle()
//        
//        // Apply the color assignments to the balls
//        for (index, ball) in balls.enumerated() {
//            let color = colorAssignments[index]
//            ball.color = color
//        }
//        
//        collectedLabel.text = "\(aimedBallsLeft)"
//    }
//    
//    func calculateBallSize(numberOfBalls: Int) -> CGFloat {
//        let screenArea = self.size.width * self.size.height
//        let totalBallArea = screenArea * 0.5
//        let ballArea = totalBallArea / CGFloat(numberOfBalls)
//        return sqrt(ballArea / .pi) * 2
//    }
//    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else { return }
//        let location = touch.location(in: self)
//        let nodesArray = nodes(at: location)
//
//        if let backButtonNode = nodesArray.first(where: { $0.name == "backButton" }) {
//            ActionManager.shared.performAction(.backButtonTap)
//            transitionBackToMenu()
//            return
//        }
//
//        if tapToStartLabel.parent != nil {
//            tapToStartLabel.removeFromParent()
//            startGame()
//            return
//        }
//        
//        guard startTime > 0 else { return }
//
//        if let ballNode = nodesArray.first(where: { $0 is Ball }) as? Ball {
//            if ballNode.color == aimBallColor {
//                ballNode.boom()
//                balls.removeAll { $0 == ballNode }
//                collectedBalls += 1
//                collectedLabel.text = "\(aimedBallsLeft)"
//                
//                let reactionTime = CACurrentMediaTime() - lastTap
//                recordedReactionTimes.append(reactionTime)
//                ActionManager.shared.performAction(.itemTap)
//            } else {
//                backgroundColor = .red
//                run(.wait(forDuration: 0.25)) { self.backgroundColor = .black }
//                mistakes += 1
//                ActionManager.shared.performAction(.lose)
//            }
//            lastTap = CACurrentMediaTime()
//            if balls.filter({ $0.color == aimBallColor }).isEmpty {
//                gameOver()
//            }
//        }
//    }
//    
//    func startGame() {
//        // Override this in subclasses to implement game-specific behavior.
//    }
//    
//    func transitionBackToMenu() {
//        let sc = MenuScene(size: self.size)
//        self.view?.presentScene(sc)
//    }
//    
//    func gameOver() {
//        // Override this in subclasses to implement game-specific behavior.
//    }
//}
