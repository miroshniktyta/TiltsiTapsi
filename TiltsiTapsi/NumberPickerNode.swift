import SpriteKit

class NumberPickerNode: SKNode {
    
    var number: Int = 40 {
        didSet {
            updateNumberLabel()
            onNumberChanged?(number) // Trigger closure when number changes
        }
    }
    private let numberLabel = AppLabelNode(text: "0")
    private var increment: Int = 0
    
    var minNumber: Int
    var maxNumber: Int
    var onNumberChanged: ((Int) -> Void)? // Closure property
    
    init(initialNumber: Int = 40, height: CGFloat = 40, minNumber: Int = 40, maxNumber: Int = 100) {
        self.minNumber = minNumber
        self.maxNumber = maxNumber
        super.init()
        self.number = initialNumber
        setupUI(height: height)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(height: CGFloat) {
        let containerWidth = height * 3
        let radius = height / 2
        let numberContainer = SKShapeNode()
        numberContainer.path = UIBezierPath(roundedRect: CGRect(x: -containerWidth / 2, y: -height / 2, width: containerWidth, height: height), cornerRadius: radius).cgPath
        numberContainer.fillColor = .white
        numberContainer.strokeColor = .clear
        addChild(numberContainer)

        numberLabel.fontSize = height / 3 * 2
        numberLabel.fontColor = .black
        numberContainer.addChild(numberLabel)
        updateNumberLabel()

        // Set up plus and minus labels inside square containers
        let containerSize = CGSize(width: height, height: height)
        
        let plusContainer = SKSpriteNode(texture: nil, color: .clear, size: containerSize)
        plusContainer.position = CGPoint(x: containerWidth / 2 + containerSize.width / 2, y: 0)
        plusContainer.name = "plusContainer"
        addChild(plusContainer)
        
        let plusLabel = AppLabelNode(text: "+")
        plusLabel.fontSize = height
        plusLabel.fontColor = .white
        plusLabel.name = "plusLabel"
        plusContainer.addChild(plusLabel)
        
        let minusContainer = SKSpriteNode(texture: nil, color: .clear, size: containerSize)
        minusContainer.position = CGPoint(x: -(containerWidth / 2 + containerSize.width / 2), y: 0)
        minusContainer.name = "minusContainer"
        addChild(minusContainer)

        let minusLabel = AppLabelNode(text: "-")
        minusLabel.fontSize = height
        minusLabel.fontColor = .white
        minusLabel.name = "minusLabel"
        minusContainer.addChild(minusLabel)
    }
    
    private func updateNumberLabel() {
        numberLabel.text = "\(number)"
    }
    
    private func startChangingNumber(by amount: Int) {
        increment = amount
        changeNumber()
        
        let waitAction = SKAction.wait(forDuration: 0.1)
        let changeAction = SKAction.run { [weak self] in
            self?.changeNumber()
        }
        let sequence = SKAction.sequence([waitAction, changeAction])
        let holdAction = SKAction.repeatForever(sequence)
        
        run(.sequence([.wait(forDuration: 0.3), holdAction]), withKey: "holdAction")
    }
    
    private func stopChangingNumber() {
        removeAction(forKey: "holdAction")
    }
    
    private func changeNumber() {
        // Update logic to respect minNumber and maxNumber boundaries
        let newNumber = number + increment
        if newNumber >= minNumber && newNumber <= maxNumber {
            number = newNumber
        }
        updateNumberLabel()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        
        if node.name == "plusContainer" || node.name == "plusLabel" {
            startChangingNumber(by: 1)
        } else if node.name == "minusContainer" || node.name == "minusLabel" {
            startChangingNumber(by: -1)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopChangingNumber()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopChangingNumber()
    }
}
