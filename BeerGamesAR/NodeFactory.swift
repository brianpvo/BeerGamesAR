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
    
    
    func createBall(_with position:SCNVector3) -> SCNNode {
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.02))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        ball.position = position
        ball.name = "ball"
        
        return ball
    }

}
