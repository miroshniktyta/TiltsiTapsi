//
//  Ball.swift
//  TiltsiTapsi
//
//  Created by pc on 26.10.24.
//

import SpriteKit
import SpriteKit

class Ball: SKShapeNode {
    
    enum ShapeType: CaseIterable {
        case circle, square, triangle, pentagon, hexagon
    }
    
    private var shapeType: ShapeType

    var color: UIColor {
        didSet {
            self.fillColor = color.withAlphaComponent(0.5)
            self.strokeColor = color
        }
    }
    
    init(color: UIColor, width: CGFloat, shapeType: ShapeType = .circle) {
        self.shapeType = shapeType
        self.color = color
        super.init()
        
        // Set path based on shape type, with radius being half of width
        let radius = width / 2
        
        switch shapeType {
        case .circle:
            self.path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: width, height: width), transform: nil)
            
        case .square:
            let sideLength = radius * sqrt(2)
            self.path = CGPath(rect: CGRect(x: -sideLength / 2, y: -sideLength / 2, width: sideLength, height: sideLength), transform: nil)
            
        case .triangle:
            let path = CGMutablePath()
            let height = radius * sqrt(3) // Height for equilateral triangle
            path.move(to: CGPoint(x: 0, y: height / 2))
            path.addLine(to: CGPoint(x: -radius, y: -height / 2))
            path.addLine(to: CGPoint(x: radius, y: -height / 2))
            path.closeSubpath()
            self.path = path
            
        case .pentagon:
            let path = CGMutablePath()
            let angleIncrement = CGFloat(2 * CGFloat.pi / 5)
            for i in 0..<5 {
                let angle = angleIncrement * CGFloat(i) - .pi / 2
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
            self.path = path
            
        case .hexagon:
            let path = CGMutablePath()
            let angleIncrement = CGFloat(2 * CGFloat.pi / 6)
            for i in 0..<6 {
                let angle = angleIncrement * CGFloat(i) - .pi / 6
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
            self.path = path
        }
        
        // Apply color and stroke properties
        self.fillColor = color.withAlphaComponent(0.5)
        self.strokeColor = color
        self.lineWidth = 1
    }
    
    func createPhysicsBody() {
        switch shapeType {
        case .circle:
            let radius = self.frame.width / 2
            self.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            
        case .square, .triangle, .pentagon, .hexagon:
            guard let path = self.path else { return }
            self.physicsBody = SKPhysicsBody(polygonFrom: path)
        }
        
        self.physicsBody?.isDynamic = true
        self.physicsBody?.friction = 0.3
        self.physicsBody?.restitution = 0.6
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
