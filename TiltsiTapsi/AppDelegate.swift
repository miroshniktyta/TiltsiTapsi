//
//  AppDelegate.swift
//  TiltsiTapsi
//
//  Created by pc on 24.10.24.
//

import UIKit
import SpriteKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

}

enum GameType: String {
    case gravity, jump, spot, run
}

let colors: [UIColor] = [.red, .green, .blue, .orange]


extension SKNode {
    func boom() {
        if let particles = SKEmitterNode(fileNamed: "Explosion") {
            particles.position = self.position
            particles.zPosition = 1
            particles.setScale(self.frame.size.width / 56)
            self.parent?.addChild(particles)
            
            let removeAfterDead = SKAction.sequence([SKAction.wait(forDuration: 3), SKAction.removeFromParent()])
            particles.run(removeAfterDead)
        }
        self.removeFromParent()
    }
}

extension SKScene {
    func viewController() -> UIViewController? {
        return self.view?.window?.rootViewController
    }
}

extension SKTexture {
    static func fromSymbol(systemName: String, pointSize: CGFloat, weight: UIImage.SymbolWeight = .regular) -> SKTexture? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        if let symbolImage = UIImage(systemName: systemName, withConfiguration: config) {
            return SKTexture(image: symbolImage)
        }
        return nil
    }
}

extension SKLabelNode {
   func addStroke(color: UIColor, width: CGFloat = 2) {

        guard let labelText = self.text else { return }

        let font = UIFont(name: self.fontName!, size: self.fontSize)

        let attributedString:NSMutableAttributedString
        if let labelAttributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelAttributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }

       let attributes:[NSAttributedString.Key:Any] = [.strokeColor: color, .strokeWidth: -width, .font: font!, .foregroundColor: self.fontColor!]
        attributedString.addAttributes(attributes, range: NSMakeRange(0, attributedString.length))
       
        self.attributedText = attributedString
   }
}

class AppLabelNode: SKLabelNode {
    init(text: String) {
        super.init()
        self.text = text
        self.fontName = "Baloo-Regular"
        self.fontSize = 24
        self.fontColor = .white  // Set your custom font color
        self.verticalAlignmentMode = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's background color to black
        self.view.backgroundColor = .black
        
        // Create an SKView
        let skView = SKView()
        skView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add SKView to the ViewController's view
        self.view.addSubview(skView)
        
        // Constrain SKView to fill the safe area
        NSLayoutConstraint.activate([
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            skView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
        
        // Store reference to skView for later use
        self.skView = skView
    }
    
    private var skView: SKView?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let skView = self.skView else { return }
        
        if skView.scene == nil {
            let scene = MenuScene(size: skView.frame.size)
            scene.scaleMode = .resizeFill
//            skView.showsPhysics = false
            skView.presentScene(scene)
//            skView.showsPhysics = true
        }
        
        GameCenterManager.shared.authenticatePlayer(from: self)
    }
}
