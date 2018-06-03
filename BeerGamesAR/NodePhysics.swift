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
}

class NodePhysics: NSObject, SCNPhysicsContactDelegate {
    
    var scene: SCNScene
    
    init(scene: SCNScene) {
        self.scene = scene
    }
    
    func ballBitMaskAndPhysicsBody(_to Node: SCNNode) {
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: Node, options: nil))
        Node.physicsBody = body
        body.isAffectedByGravity = true
        Node.physicsBody?.categoryBitMask = BitMaskCategory.ball.rawValue
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.emptyNode.rawValue | BitMaskCategory.table.rawValue | BitMaskCategory.ball.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
    }
    
    func cupBitMaskAndPhysicsBody(_to Node: SCNNode) {
        let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: Node, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type:SCNPhysicsShape.ShapeType.concavePolyhedron]))
        Node.physicsBody = body
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
        //        print("node A is \(nodeA.name)")
        //        print("node B is \(nodeB.name)")
        if (nodeA.name == "ball" && nodeB.name == "cup1invisbleNode") || (nodeB.name == "ball" && nodeA.name == "cup1invisibleNode") {
            print("contact established")
        }
//        for i in 1...2 {
//            removeCupAndBall(cupName: "cup\(i)", nodeA: nodeA, nodeB: nodeB)
//        }
        
    }
    
    
    
    private func removeCupAndBall(cupName:String, nodeA:SCNNode, nodeB:SCNNode) {
        print(cupName)
        if (nodeA.name == "ball" && nodeB.name == "\(cupName)invisibleNode") || (nodeB.name == "ball" && nodeA.name == "\(cupName)invisibleNode") {
            self.scene.rootNode.enumerateChildNodes { (node, _) in
                if node.name == cupName || node.name == "\(cupName)invisibleNode" || node.name == "ball" {
                    //                    node.removeFromParentNode()
//                    print("node A is \(nodeA.name)")
//                    print("node B is \(nodeB.name)")
                }
            }
        }
        
    }
    
    
    
    
    
}
