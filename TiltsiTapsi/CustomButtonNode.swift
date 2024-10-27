//
//  CustomButtonNode.swift
//  TiltsiTapsi
//
//  Created by pc on 24.10.24.
//

import SpriteKit

class CustomButtonNode: Ball {
    var didTap: (() -> Void)?
    
    init(color: UIColor, text: String, isPhysics: Bool = true, width: CGFloat, shape: ShapeType = .circle, didTap: @escaping () -> Void) {
        super.init(color: color, width: width, shapeType: shape)
        
        self.isUserInteractionEnabled = true
        self.didTap = didTap
        self.name = "menuButton"
        
        // Add text label
        let label = AppLabelNode(text: text)
        label.fontSize = width / 7
        label.fontColor = .white
        label.zPosition = 1
        self.addChild(label)
        
        // Configure physics if needed
        if isPhysics {
            self.createPhysicsBody() // This function is inherited from Ball and sets physics based on the shape type
            self.physicsBody?.restitution = 0.4
            self.run(.run {
                self.physicsBody?.applyAngularImpulse(CGFloat.random(in: -0.08...0.08))
            })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        ActionManager.shared.performAction(.buttonTap)
        didTap?()
    }
}
