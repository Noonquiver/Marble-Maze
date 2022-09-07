//
//  GameScene.swift
//  Marble Maze
//
//  Created by Camilo Hernández Guerrero on 5/09/22.
//
import CoreMotion
import SpriteKit

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case teleport = 16
    case finish = 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var initialPosition = CGPoint(x: 96, y: 672)
    var lastTouchPosition: CGPoint?
    var motionManager: CMMotionManager?
    var scoreLabel: SKLabelNode!
    var isGameOver = false
    var teleports = [SKSpriteNode]()
    
    var level = 1 {
        didSet {
            if level > 2 {
                level = 1
            }
        }
    }
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        background.name = "background"
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        loadLevel(number: level)
        createPlayer(in: initialPosition)
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    
    func readTxt(_ number: Int) -> [String] {
        guard let levelURL = Bundle.main.url(forResource: "level\(number)", withExtension: "txt") else { fatalError("Could not find level\(number).txt in the app bundle.") }
        guard let levelString = try? String(contentsOf: levelURL) else { fatalError("Could not find level\(number).txt in the app bundle.") }
        let lines = levelString.components(separatedBy: "\n")
        return lines
    }
    
    func createWall(in position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "block")
        node.position = position
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
    
    func createVortex(in position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0 //It bounces off nothing.
        addChild(node)
    }
    
    func createStar(in position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "star")
        node.name = "star"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func createTeleport(in position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "teleport")
        node.name = "teleport"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        teleports.append(node)
        addChild(node)
    }
    
    func createFinish(in position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "finish")
        node.name = "finish"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func createCorrespondingSprite(of letter: String.Element, in position: CGPoint) {
        if letter == "x" { //Wall
            createWall(in: position)
        } else if letter == "v" { //Vortex
            createVortex(in: position)
        } else if letter == "s" { //Star
            createStar(in: position)
        } else if letter == "t" {
            createTeleport(in: position)
        } else if letter == "f" { //Finish
            createFinish(in: position)
        } else if letter == " " { //Empty space
            return
        } else {
            fatalError("Unknown level letter: \(letter).")
        }
    }
    
    func loadLevel(number: Int) {
        let lines = readTxt(number)
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                createCorrespondingSprite(of: letter, in: position)
            }
        }
    }
    
    func createPlayer(in position: CGPoint) {
        player = SKSpriteNode(imageNamed: "player")
        player.position = position
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.teleport.rawValue | CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let lastTouchPosition = lastTouchPosition {
            let difference = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: difference.x / 100, dy: difference.y / 100)
        }
        #else
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            score -= 1
            reappear(node: node, in: initialPosition)
        } else if node.name == "star" {
            node.removeFromParent()
            score += 1
        } else if node.name == "teleport" {
            var teleport = teleports.randomElement()
            
            while node.position == teleport!.position {
                teleport = teleports.randomElement()
            }
            
            teleport!.name = ""
            
            reappear(node: node, in: teleport!.position)
        } else if node.name == "finish" {
            eraseLevel()
            level += 1
            createPlayer(in: initialPosition)
            loadLevel(number: level)
        }
    }
    
    func reappear(node: SKNode, in position: CGPoint) {
        player.physicsBody?.isDynamic = false
        isGameOver = true
        
        let move = SKAction.move(to: node.position, duration: 0.25)
        let scale = SKAction.scaleX(to: 0.0001, duration: 0.25)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([move, scale, remove])
        
        player.run(sequence) {
            [weak self] in
            self?.createPlayer(in: position)
            self?.isGameOver = false
        }
    }
    
    func eraseLevel() {
        teleports = [SKSpriteNode]()
        
        for case let child as SKSpriteNode in children {
            if child.name == "background" {
                continue
            }
            
            child.removeFromParent()
        }
    }
}
