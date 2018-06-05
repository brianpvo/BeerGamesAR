//
//  NodePhysics.swift
//  BeerGamesAR
//
//  Created by Brian Vo on 2018-06-02.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum BitMaskCategory:Int {
    case ball = 2
    case emptyNode = 3
    case table = 4
    case cup = 5
}

class NodePhysics: NSObject, SCNPhysicsContactDelegate {
    
    var scene: SCNScene
    
    init(scene: SCNScene) {
        self.scene = scene
    }
    
    func ballBitMaskAndPhysicsBody(_to Node: SCNNode) {
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.02), options: [:]))
        
        Node.physicsBody = body
        body.isAffectedByGravity = true
        Node.physicsBody?.categoryBitMask = BitMaskCategory.ball.rawValue
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.emptyNode.rawValue | BitMaskCategory.table.rawValue | BitMaskCategory.ball.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
        Node.physicsBody?.restitution = 0.2
        Node.physicsBody?.damping = 0.1
        Node.physicsBody?.friction = 0.1
    }
    
    func cupBitMaskAndPhysicsBody(_to Node: SCNNode, scale: SCNVector3) {
        let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: Node, options: [SCNPhysicsShape.Option.keepAsCompound : true,
            SCNPhysicsShape.Option.scale: scale,
            SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron
            ]))
        Node.physicsBody = body
        //Node.physicsBody?.friction = 1
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue
    }
    
    func invisibleNodeBitMaskAndPhysicsBody(_to Node: SCNNode) {
        let body = SCNPhysicsBody.static()
        Node.physicsBody = body
        Node.physicsBody?.categoryBitMask = BitMaskCategory.emptyNode.rawValue
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.ball.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.emptyNode.rawValue
    }
    
    func tableBitMaskAndPhysicsBody(_to Node: SCNNode) {
        Node.physicsBody = SCNPhysicsBody.static()
        Node.physicsBody?.categoryBitMask = BitMaskCategory.table.rawValue
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
//        let contactMask = (contact.nodeA.physicsBody?.categoryBitMask)! |
//            (contact.nodeB.physicsBody?.categoryBitMask)!
//        
//        if (contactMask == (BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue)) {
//            
//        }
        
        DispatchQueue.global(qos: .background).async {
            if (nodeA.name == "ball" && ((nodeB.name?.range(of: "invisibleNode")) != nil)) ||
                (nodeB.name == "ball" && ((nodeA.name?.range(of: "invisibleNode")) != nil)) {
                print("\(nodeA.name!) touched \(nodeB.name!)")
            }
            
            for i in 1...9 {
                if (nodeA.name == "ball" && nodeB.name == "yourCup\(i)invisibleNode") || (nodeB.name == "ball" && nodeA.name == "yourCup\(i)invisibleNode") {
                    nodeA.removeFromParentNode()
                    nodeB.removeFromParentNode()
                    self.scene.rootNode.enumerateChildNodes { (node, _) in
                        if node.name == "yourCup\(i)" {
                            print("removing yourCup\(i)")
                            node.removeFromParentNode()
                            self.updateTableShape()
                        }
                    }
                }
            }
        }
    }
    
    
    
    private func updateTableShape() {
        DispatchQueue.global(qos: .default).async {
            self.scene.rootNode.enumerateChildNodes { (node, _) in
                if node.name == "table" {
                    let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: node, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type:SCNPhysicsShape.ShapeType.concavePolyhedron]))
                    node.physicsBody = nil
                    node.physicsBody = body
                    node.physicsBody?.categoryBitMask = BitMaskCategory.table.rawValue
                    node.physicsBody?.contactTestBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
                    node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
                }
            }
        }
        
    }
}
