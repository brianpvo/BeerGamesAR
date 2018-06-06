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
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.table.rawValue | BitMaskCategory.ball.rawValue //| BitMaskCategory.plane.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue | BitMaskCategory.plane.rawValue | BitMaskCategory.tube.rawValue
        Node.physicsBody?.restitution = 0.9
        Node.physicsBody?.damping = 0.2
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
    
    func applyPhysics() {
        scene.rootNode.enumerateChildNodes { (node, stop) in
            if node.name == "table" {
                self.tableBitMaskAndPhysicsBody(_to: node)
            }
//            if node.name?.range(of: "yourRedCup") != nil {
//                node.scale = SCNVector3(x: 0.375, y: 0.468, z: 0.375)
//                //node.physicsBody = nil
//            }
//            else if node.name?.range(of: "myCup") != nil {
////                node.physicsBody = nil
////                node.scale = SCNVector3(x: 0.375, y: 0.468, z: 0.375)
//            }
            if node.name?.range(of: "Tube") != nil {
                self.tubeBitMaskAndPhysicsBody(node: node)
            }
            if  node.name?.range(of: "Plane") != nil {
                self.planeBitMaskAndPhysicsBody(node: node)
            }
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        DispatchQueue.global(qos: .background).async {
            
            if nodeA.name == "ball" && nodeB.name?.range(of: "Plane") != nil {
                print("ball touched \(nodeB.name!)")
                self.removeCupAndPhysics(contactNode: nodeB)
            }
            if (nodeA.name?.contains("Plane"))! && nodeB.name == "ball" {
                print("\(nodeA.name!) touched ball")
                self.removeCupAndPhysics(contactNode: nodeA)
            }
        }
    }
    
    private func removeCupAndPhysics(contactNode: SCNNode) {
        self.scene.rootNode.enumerateChildNodes({ (node, _) in
            guard let nodeNumber = contactNode.name?.suffix(1) else { return }
            if node.name == "yourCup" + nodeNumber ||
                node.name == "yourTube" + nodeNumber ||
                node.name == "yourPlane" + nodeNumber ||
                node.name == "ball" {
                node.removeFromParentNode()
            }
        })
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
