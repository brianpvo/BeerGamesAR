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
    case tube = 3
    case table = 4
    case plane = 5
}

class NodePhysics: NSObject {
    
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
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.table.rawValue | BitMaskCategory.ball.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue | BitMaskCategory.plane.rawValue
        Node.physicsBody?.restitution = 0.2
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
    
    func tubeBitMaskAndPhysicsBody(node: SCNNode) {
        let physicsShape = SCNPhysicsShape(node: node,
                                           options: [//SCNPhysicsShape.Option.keepAsCompound : true,
                                                     SCNPhysicsShape.Option.scale:
                                                        SCNVector3(0.057,
                                                                   0.138,
                                                                   0.061),
                                                     SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron
            ])
        let body = SCNPhysicsBody(type: .static,
                                  shape: physicsShape)
        node.physicsBody = body
        node.physicsBody?.categoryBitMask = BitMaskCategory.tube.rawValue
        node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue
    }
    
    func planeBitMaskAndPhysicsBody(node: SCNNode) {
        let physicsShape = SCNPhysicsShape(node: node,
                                            options: [//SCNPhysicsShape.Option.keepAsCompound : true,
                                                SCNPhysicsShape.Option.scale:
                                                    SCNVector3(0.03,
                                                               0.03,
                                                               0.1),
                                                SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron
            ])
        let body = SCNPhysicsBody(type: .static,
                                  shape: physicsShape)
        node.physicsBody = body
        node.physicsBody?.categoryBitMask = BitMaskCategory.plane.rawValue
        node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue
    }
    
    func tableBitMaskAndPhysicsBody(_to Node: SCNNode) {
        Node.physicsBody = SCNPhysicsBody.static()
        Node.physicsBody?.categoryBitMask = BitMaskCategory.table.rawValue
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
    }
    
    func apply() {
        scene.rootNode.enumerateChildNodes { (node, stop) in
            if node.name == "table" {
                self.tableBitMaskAndPhysicsBody(_to: node)
            }
            if node.name?.range(of: "tube") != nil {
                self.tubeBitMaskAndPhysicsBody(node: node)
            }
            if  node.name?.range(of: "plane") != nil {
                self.planeBitMaskAndPhysicsBody(node: node)
            }
        }
    }

//    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
//        let nodeA = contact.nodeA
//        let nodeB = contact.nodeB
//
//        DispatchQueue.global(qos: .background).async {
//
//            if nodeA.name == "ball" && nodeB.name?.range(of: "plane") != nil {
//                print("ball touched \(nodeB.name!)")
//                self.removeCupAndPhysics(contactNode: nodeB)
//            }
//            if (nodeA.name?.contains("plane"))! && nodeB.name == "ball" {
//                print("\(nodeA.name!) touched ball")
//                self.removeCupAndPhysics(contactNode: nodeA)
//            }
//        }
//    }
//
//    private func removeCupAndPhysics(contactNode: SCNNode) {
//        self.scene.rootNode.enumerateChildNodes({ (node, _) in
//            guard let nodeNumber = contactNode.name?.suffix(1) else { return }
//            if node.name == "cup" + nodeNumber ||
//                node.name == "tube" + nodeNumber ||
//                node.name == "plane" + nodeNumber ||
//                node.name == "ball" {
//                node.removeFromParentNode()
//            }
//        })
//    }
//
//    private func updateCupState() {
//        guard let roomCode = roomCode else { return }
//        firebaseReference?.child("hotspot_list").child(roomCode)
//            .child("game_state")
//    }

}
