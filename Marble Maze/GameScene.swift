//
//  GameScene.swift
//  Marble Maze
//
//  Created by Camilo Hernández Guerrero on 5/09/22.
//

import SpriteKit

enum CollisiionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
}

class GameScene: SKScene {
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        loadLevel()
    }
    
    func loadLevel() {
        guard let levelURL = Bundle.main.url(forResource: "level1", withExtension: "txt") else { fatalError("Could not find level1.txt in the app bundle.") }
        guard let levelString = try? String(contentsOf: levelURL) else { fatalError("Could not find level1.txt in the app bundle.") }
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                if letter == "x" { //Wall
                    let node = SKSpriteNode(imageNamed: "block")
                    node.position = position
                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.categoryBitMask = CollisiionTypes.wall.rawValue
                    node.physicsBody?.isDynamic = false
                    addChild(node)
                } else if letter == "v" { //Vortex
                    let node = SKSpriteNode(imageNamed: "vortex")
                    node.name = "vortex"
                    node.position = position
                    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    node.physicsBody?.categoryBitMask = CollisiionTypes.vortex.rawValue
                    node.physicsBody?.contactTestBitMask = CollisiionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0 //It bounces off nothing.
                    addChild(node)
                } else if letter == "s" { //Star
                    let node = SKSpriteNode(imageNamed: "star")
                    node.name = "star"
                    node.position = position
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    node.physicsBody?.categoryBitMask = CollisiionTypes.star.rawValue
                    node.physicsBody?.contactTestBitMask = CollisiionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    addChild(node)
                } else if letter == "f" { //Finish
                    let node = SKSpriteNode(imageNamed: "finish")
                    node.name = "finish"
                    node.position = position
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    node.physicsBody?.categoryBitMask = CollisiionTypes.finish.rawValue
                    node.physicsBody?.contactTestBitMask = CollisiionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    addChild(node)
                } else if letter == " " { //Empty space
                    //Do nothing.
                } else {
                    fatalError("Unknown level letter: \(letter).")
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
