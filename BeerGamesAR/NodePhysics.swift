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
    case plane = 5
}

class NodePhysics: NSObject, SCNPhysicsContactDelegate {
    
    var scene: SCNScene
    var scoreManager = ScoreManager()
    
    init(scene: SCNScene) {
        self.scene = scene
        scoreManager.scene = scene
    }
    
    func ballBitMaskAndPhysicsBody(_to Node: SCNNode) {
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.02), options: [:]))
        
        Node.physicsBody = body
        body.isAffectedByGravity = true
        Node.physicsBody?.categoryBitMask = BitMaskCategory.ball.rawValue
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.emptyNode.rawValue | BitMaskCategory.table.rawValue | BitMaskCategory.ball.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue | BitMaskCategory.plane.rawValue
        Node.physicsBody?.restitution = 0.0
        Node.physicsBody?.damping = 0.1
        Node.physicsBody?.friction = 0.8
        Node.physicsBody?.mass = 0.65
    }
    
    func cupBitMaskAndPhysicsBody(_to Node: SCNNode, scale: SCNVector3) {
        let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: Node, options: [SCNPhysicsShape.Option.keepAsCompound : true,
            SCNPhysicsShape.Option.scale: scale,
            SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron
            ]))
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
        
        DispatchQueue.global(qos: .background).async {
            
            if nodeA.name == "ball" && nodeB.name?.range(of: "Plane") != nil {
                print("ball touched \(nodeB.name!)")
            }
            if (nodeA.name?.contains("Plane"))! && nodeB.name == "ball" {
                print("\(nodeA.name!) touched ball")
            }
        }
    }
    
    
    
   
}
