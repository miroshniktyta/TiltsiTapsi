//
//  CustomGameSettingNode.swift
//  game
//
//  Created by pc on 09.09.24.
//

import SpriteKit

class CustomGameSettingNode: SKNode {
    
    let size: CGSize
    var totalBalls: Int = 50 {
        didSet {
            aimBallsPickerNode.maxNumber = totalBalls - 1
        }
    }
    var aimBalls: Int = 12 {
        didSet {
            totalBallsPickerNode.minNumber = aimBalls + 1
        }
    }
    var colorsNumber: Int = 4
    
    private var totalBallsPickerNode: NumberPickerNode!
    private var aimBallsPickerNode: NumberPickerNode!
    private var colorsPickerNode: NumberPickerNode!

    // Row title labels
    var totalBallsLabel: AppLabelNode!
    var aimBallsLabel: AppLabelNode!
    var colorsNumberLabel: AppLabelNode!

    init(size: CGSize) {
        self.size = size
        super.init()
        setupUI()
        setupClosures() // Add this line to set up the closures
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupClosures() {
        // For Total Balls
        totalBallsPickerNode.onNumberChanged = { [weak self] newTotalBalls in
            self?.totalBalls = newTotalBalls
        }

        // For Aim Balls
        aimBallsPickerNode.onNumberChanged = { [weak self] newAimBalls in
            self?.aimBalls = newAimBalls
        }

        // For Colors Number
        colorsPickerNode.onNumberChanged = { [weak self] newColorsNumber in
            self?.colorsNumber = newColorsNumber
        }
    }
    
    private func setupUI() {
        let lowMargine: CGFloat = 40
        let topMargine: CGFloat = 30
        let spacing: CGFloat = 10

        let container = SKShapeNode(rectOf: size, cornerRadius: 20)
        container.fillColor = .black.withAlphaComponent(0.5)
        container.strokeColor = .black
        container.position = CGPoint(x: 0, y: 0)
        container.zPosition = 1
        addChild(container)

        let rowHeight: CGFloat = size.height / 6 - lowMargine / 3 - spacing / 3
        let totalBallsY = size.height / 2 - rowHeight - topMargine
        let aimBallsY = totalBallsY - 2 * rowHeight - spacing
        let colorsNumberY = aimBallsY - 2 * rowHeight - spacing

        setupNumberPicker(in: container, title: "Total Balls", min: 0, max: 1000, initial: totalBalls, yPosition: totalBallsY, labelHeight: rowHeight, picker: &totalBallsPickerNode)
        
        setupNumberPicker(in: container, title: "Aim Balls", min: 1, max: totalBalls - 1, initial: aimBalls, yPosition: aimBallsY, labelHeight: rowHeight, picker: &aimBallsPickerNode)
        
        setupNumberPicker(in: container, title: "Colors Number", min: 2, max: 4, initial: colorsNumber, yPosition: colorsNumberY, labelHeight: rowHeight, picker: &colorsPickerNode)
    }

    private func setupNumberPicker(in container: SKNode, title: String, min: Int, max: Int, initial: Int, yPosition: CGFloat, labelHeight: CGFloat, picker: inout NumberPickerNode?) {
        // Row Title Label
        let label = AppLabelNode(text: title)
        label.fontSize = labelHeight / 2
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: yPosition + labelHeight / 2)
        container.addChild(label)
        
        // Number Picker
        let pickerNode = NumberPickerNode(initialNumber: initial, height: labelHeight, minNumber: min, maxNumber: max)
        pickerNode.position = CGPoint(x: 0, y: yPosition - labelHeight / 2)
        container.addChild(pickerNode)
        
        // Assign picker node to the appropriate reference
        picker = pickerNode
    }

    func getTotalBalls() -> Int {
        return totalBallsPickerNode.number
    }

    func getAimBalls() -> Int {
        return aimBallsPickerNode.number
    }

    func getColorsNumber() -> Int {
        return colorsPickerNode.number
    }
}
