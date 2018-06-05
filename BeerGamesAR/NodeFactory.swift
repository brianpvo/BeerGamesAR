//
//  File.swift
//  BeerGamesAR
//
//  Created by Brian Vo on 2018-06-03.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import UIKit
import SceneKit

class NodeFactory {
    var scene: SCNScene!
    
    let nodePhysics = NodePhysics(scene: SCNScene())
    let invisibleNodePositions = ["yourCup1invisibleNode" : SCNVector3(0.02,
                                                                       0.668,
                                                                       -0.792),
                                  "yourCup2invisibleNode" : SCNVector3(-0.11,
                                                                       0.668,
                                                                       0.92),
                                  
    ]
    
    func createInvisibleNode(table:SCNNode, _with name:String)->SCNNode {
        
        let invisbleNode = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.001))
        invisbleNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        
        if name == "yourCup1invisibleNode" {
            
            invisbleNode.position = SCNVector3(table.position.x + 0.004,
                                               table.position.y + 0.534,
                                               table.position.z - 0.944)
            
        }
        
        if name == "yourCup2invisibleNode" {
            
            invisbleNode.position = SCNVector3(table.position.x - 0.11,
                                               table.position.y + 0.668,
                                               table.position.z - 0.92)
            
        }
        
        
        if name == "yourCup3invisibleNode" {
            
            invisbleNode.position = SCNVector3(table.position.x + 0.015,
                                               table.position.y + 0.668,
                                               table.position.z - 0.92)
            
        }
        
        if name == "yourCup4invisibleNode" {
            
            invisbleNode.position = SCNVector3(table.position.x + 0.135,
                                               table.position.y + 0.668,
                                               table.position.z - 0.92)
            
        }
        
        if name == "yourCup5invisibleNode" {
            
            invisbleNode.position = SCNVector3(table.position.x - 0.23,
                                               table.position.y + 0.668,
                                               table.position.z - 1.045)
            
        }
        
        if name == "yourCup6invisibleNode" {
            invisbleNode.position = SCNVector3(table.position.x - 0.11,
                                               table.position.y + 0.668,
                                               table.position.z - 1.045)
            
        }
        
        if name == "yourCup7invisibleNode" {
            
            invisbleNode.position = SCNVector3(table.position.x + 0.01,
                                               table.position.y + 0.668,
                                               table.position.z - 1.045)
            
        }
        
        if name == "yourCup8invisibleNode" {
            
            invisbleNode.position = SCNVector3(table.position.x + 0.135,
                                               table.position.y + 0.668,
                                               table.position.z - 1.045)
            
        }
        
        if name == "yourCup9invisibleNode" {
            
            invisbleNode.position = SCNVector3(table.position.x + 0.25,
                                               table.position.y + 0.09,
                                               table.position.z - 1.045)
            
        }
        
        setMyCupPositions(node: invisbleNode, name: name, tablePosition: table.position)
        
        invisbleNode.name = name
        
        //       physicsManager.invisibleNodeBitMaskAndPhysicsBody(_to:
        
        return invisbleNode
    }
    
    func setMyCupPositions(node: SCNNode, name: String, tablePosition: SCNVector3) {
        let myCupPositions: [String : SCNVector3] =
            ["myCup1invisibleNode": SCNVector3(tablePosition.x,
                                               tablePosition.y + 0.668,
                                               tablePosition.z + 1.027),
             "myCup2invisibleNode" : SCNVector3(tablePosition.x - 0.02,
                                                tablePosition.y + 0.668,
                                                tablePosition.z + 1.125),
             "myCup3invisibleNode" : SCNVector3(tablePosition.x + 0.055,
                                                tablePosition.y + 0.668,
                                                tablePosition.z + 1.125),
             "myCup4invisibleNode" : SCNVector3(tablePosition.x + 0.117,
                                                tablePosition.y + 0.668,
                                                tablePosition.z + 1.222)]
        guard let position = myCupPositions[name] else {
            print("no such position for name")
            return
        }
        node.position = position
    }
    
    func createBall(_with position:SCNVector3) -> SCNNode {
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.02))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        ball.position = position
        ball.name = "ball"
        
        return ball
    }

}
