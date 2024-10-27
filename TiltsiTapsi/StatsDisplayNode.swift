
import SpriteKit

struct StatsData {
    var overage: Double
    var mistakes: Int
    var fastest: Double
    var time: Double
}

class StatsDisplayNode: SKNode {
    
    private let horizontalMargin: CGFloat = 24
    private let verticalMargin: CGFloat = 20
    private let verticalSpacing: CGFloat = 8
    private let labelHeightRatio: CGFloat = 0.3 // Label height as 30% of row height
    private let resultDescription: String?
    private var statsData: StatsData
    
    init(size: CGSize, statsData: StatsData, resultDescription: String?) {
        self.statsData = statsData
        self.resultDescription = resultDescription
        super.init()
        setupUI(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(size: CGSize) {
        // Background container
        let container = SKShapeNode(rectOf: size, cornerRadius: 20)
        container.fillColor = .black.withAlphaComponent(0.6)
        container.strokeColor = .clear
        container.position = CGPoint(x: 0, y: 0)
        addChild(container)
        
        // Calculate row height based on total height, margins, and spacing
        let availableHeight = size.height - 2 * verticalMargin - 3 * verticalSpacing
        let rowHeight = availableHeight / 3.5 // 3 full rows + 1 half row
        let labelHeight = rowHeight * labelHeightRatio
        let iconSize = CGSize(width: rowHeight * 0.6, height: rowHeight * 0.6)
        
        var currentY = size.height / 2 - verticalMargin - rowHeight / 2
        
        // Top Row - Red Circle Icon
        let colorBall = Ball(color: .red, width: rowHeight, shapeType: .circle)
        colorBall.position = CGPoint(x: 0, y: currentY)
        addChild(colorBall)
        
        let leftWidth = size.width - horizontalMargin
        currentY -= (rowHeight + verticalSpacing)
        let averageLabel = String(format: "Average: %.2f s", statsData.overage)
        let mistakesLabel = String(format: "Mistakes: %d", statsData.mistakes)
        layoutStat(iconName: "bolt.circle", labelText: averageLabel, yPosition: currentY, xOffset: -leftWidth / 4, iconSize: iconSize, labelHeight: labelHeight)
        layoutStat(iconName: "target", labelText: mistakesLabel, yPosition: currentY, xOffset: leftWidth / 4, iconSize: iconSize, labelHeight: labelHeight)
        
        // Second Row - Fastest and Time
        currentY -= (rowHeight + verticalSpacing)
        let fastestLabel = String(format: "Fastest: %.2f s", statsData.fastest)
        let timeLabel = String(format: "Time: %.1f s", statsData.time)
        layoutStat(iconName: "hare", labelText: fastestLabel, yPosition: currentY, xOffset: -leftWidth / 4, iconSize: iconSize, labelHeight: labelHeight)
        layoutStat(iconName: "clock", labelText: timeLabel, yPosition: currentY, xOffset: leftWidth / 4, iconSize: iconSize, labelHeight: labelHeight)
        
        // Bottom Half Row - Result Description Label
        currentY -= (rowHeight + verticalSpacing)
        let descriptionLabel = AppLabelNode(text: resultDescription ?? "(Custom game mode)")
        descriptionLabel.fontSize = labelHeight
        descriptionLabel.position = CGPoint(x: 0, y: currentY)
        addChild(descriptionLabel)
    }
    
    // Helper method to layout a single icon-label pair
    private func layoutStat(iconName: String, labelText: String, yPosition: CGFloat, xOffset: CGFloat, iconSize: CGSize, labelHeight: CGFloat) {
        let iconNode = createIconNode(iconName: iconName, size: iconSize)
        iconNode.position = CGPoint(x: xOffset, y: yPosition + labelHeight / 2)
        addChild(iconNode)
        
        let labelNode = AppLabelNode(text: labelText)
        labelNode.fontSize = labelHeight
        labelNode.position = CGPoint(x: xOffset, y: yPosition - iconSize.height / 2 - labelHeight / 2)
        addChild(labelNode)
    }
    
    private func createIconNode(iconName: String, size: CGSize) -> SKSpriteNode {
        let iconNode = SKSpriteNode()
        if let image = UIImage(systemName: iconName) {
            let data = image.withTintColor(.white).pngData()
            let newImage = UIImage(data: data!)
            let texture = SKTexture(image: newImage!)
            iconNode.texture = texture
            iconNode.size = size
        }
        return iconNode
    }
}
