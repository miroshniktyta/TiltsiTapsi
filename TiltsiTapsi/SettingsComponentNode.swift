import SpriteKit

class SettingsComponentNode: SKNode {
    
    let size: CGSize
    var soundSwitch: CustomSwitchNode!
    var notificationSwitch: CustomSwitchNode!
    var vibrationSwitch: CustomSwitchNode!
    
    var soundLabel: AppLabelNode!
    var notificationLabel: AppLabelNode!
    var vibrationLabel: AppLabelNode!
    
    private let margin: CGFloat = 20
    private let spacing: CGFloat = 16
    
    init(size: CGSize) {
        self.size = size
        super.init()
        self.isUserInteractionEnabled = true
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Background container
        let container = SKShapeNode(rectOf: size, cornerRadius: 20)
        container.fillColor = .black.withAlphaComponent(0.5)
        container.strokeColor = .black
        container.lineWidth = 1
        container.position = CGPoint(x: 0, y: 0)
        addChild(container)
        
        // Calculate row height based on container size, margin, and spacing
        let availableHeight = size.height - 2 * margin - 2 * spacing
        let rowHeight = availableHeight / 3
        
        // Position Y for each switch row
        let soundSwitchY = size.height / 2 - margin - rowHeight / 2
        let notificationSwitchY = soundSwitchY - rowHeight - spacing
        let vibrationSwitchY = notificationSwitchY - rowHeight - spacing
        
        // Set up each row (Sound, Notification, Vibration)
        let soundIsOn = SoundManager.shared.isSoundEnabled
        soundSwitch = CustomSwitchNode(height: rowHeight * 0.6, isOn: soundIsOn) { isOn in
            SoundManager.shared.isSoundEnabled = isOn
        }
        setupSwitchRow(in: container, title: "Sound", switchNode: soundSwitch, yPosition: soundSwitchY, labelHeight: rowHeight * 0.3)
        
//        let notificationIsOn = SettingsManager.shared.isNotificationEnabled
        notificationSwitch = CustomSwitchNode(height: rowHeight * 0.6, isOn: true) { isOn in
//            SettingsManager.shared.isNotificationEnabled = isOn
        }
        setupSwitchRow(in: container, title: "Notification", switchNode: notificationSwitch, yPosition: notificationSwitchY, labelHeight: rowHeight * 0.3)
        
        let vibrationIsOn = VibrationManager.shared.isVibrationEnabled
        vibrationSwitch = CustomSwitchNode(height: rowHeight * 0.6, isOn: vibrationIsOn) { isOn in
            VibrationManager.shared.isVibrationEnabled = isOn
        }
        setupSwitchRow(in: container, title: "Vibrations", switchNode: vibrationSwitch, yPosition: vibrationSwitchY, labelHeight: rowHeight * 0.3)
    }
    
    private func setupSwitchRow(in container: SKNode, title: String, switchNode: CustomSwitchNode, yPosition: CGFloat, labelHeight: CGFloat) {
        let label = AppLabelNode(text: title)
        label.fontSize = labelHeight
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: yPosition + labelHeight * 1.7)
        container.addChild(label)
        
        let offLabel = AppLabelNode(text: "Off")
        offLabel.horizontalAlignmentMode = .right
        offLabel.fontSize = labelHeight
        offLabel.fontColor = .white
        offLabel.position = CGPoint(x: -switchNode.switchWidth / 2 - 8, y: yPosition)
        container.addChild(offLabel)

        switchNode.position = CGPoint(x: 0, y: yPosition)
        container.addChild(switchNode)
        
        let onLabel = AppLabelNode(text: "On")
        onLabel.horizontalAlignmentMode = .left
        onLabel.fontSize = labelHeight
        onLabel.fontColor = .white
        onLabel.position = CGPoint(x: switchNode.switchWidth / 2 + 8, y: yPosition)
        container.addChild(onLabel)
    }
}

class CustomSwitchNode: SKNode {
    
    var isOn: Bool
    let switchBackground: SKShapeNode
    let switchCircle: SKShapeNode
    let switchHeight: CGFloat
    let switchWidth: CGFloat
    let didSwitch: (Bool) -> ()
    
    init(height: CGFloat, isOn: Bool, didSwitch: @escaping (Bool) -> ()) {
        self.switchHeight = height
        self.switchWidth = height * 2
        self.isOn = isOn
        self.didSwitch = didSwitch

        switchBackground = SKShapeNode(rectOf: CGSize(width: switchWidth, height: switchHeight), cornerRadius: switchHeight / 2)
        switchBackground.fillColor = isOn ? .green : .gray
        
        switchCircle = SKShapeNode(circleOfRadius: switchHeight * 0.4)
        switchCircle.fillColor = .white
        
        super.init()
        setupSwitch()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSwitch() {
        addChild(switchBackground)
        switchCircle.position = CGPoint(x: isOn ? switchWidth / 2 - switchCircle.frame.width / 2 : -switchWidth / 2 + switchCircle.frame.width / 2, y: 0)
        addChild(switchCircle)
        
        isUserInteractionEnabled = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isOn.toggle()
        updateSwitchState()
        didSwitch(isOn)
    }
    
    private func updateSwitchState() {
        switchBackground.fillColor = isOn ? .green : .gray
        let targetX = isOn ? switchWidth / 2 - switchCircle.frame.width / 2 : -switchWidth / 2 + switchCircle.frame.width / 2
        switchCircle.run(SKAction.moveTo(x: targetX, duration: 0.2))
    }
}
