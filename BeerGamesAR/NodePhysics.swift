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
    
    init(scene: SCNScene) {
        self.scene = scene
    }
    
    func ballBitMaskAndPhysicsBody(_to Node: SCNNode) {
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNSphere(radius: 0.02), options: [:]))
        
        Node.physicsBody = body
        body.isAffectedByGravity = true
        Node.physicsBody?.categoryBitMask = BitMaskCategory.ball.rawValue
        Node.physicsBody?.contactTestBitMask = BitMaskCategory.table.rawValue | BitMaskCategory.ball.rawValue
        Node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue | BitMaskCategory.plane.rawValue
        Node.physicsBody?.restitution = 1.45
        Node.physicsBody?.damping = 0.3
        Node.physicsBody?.friction = 0.7
        Node.physicsBody?.mass = 0.6
    }
    
    private func tubeBitMaskAndPhysicsBody(node: SCNNode) {
        let physicsShape = SCNPhysicsShape(node: node,
                                           options: [SCNPhysicsShape.Option.keepAsCompound : true])
        let body = SCNPhysicsBody(type: .static,
                                  shape: physicsShape)
        node.physicsBody = body
        node.physicsBody?.categoryBitMask = BitMaskCategory.tube.rawValue
        node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue
    }
    
    private func planeBitMaskAndPhysicsBody(node: SCNNode) {
        let physicsShape = SCNPhysicsShape(node: node,
                                            options: [SCNPhysicsShape.Option.scale: SCNVector3(0.035, 0.035, 0.1),
                                                SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
        let body = SCNPhysicsBody(type: .static,
                                  shape: physicsShape)
        node.physicsBody = body
        node.physicsBody?.categoryBitMask = BitMaskCategory.plane.rawValue
        node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue
    }
    
    private func tableBitMaskAndPhysicsBody(_to Node: SCNNode) {
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

}
