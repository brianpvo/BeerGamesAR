//
//  scoreManager.swift
//  BeerGamesAR
//
//  Created by Raman Singh on 2018-06-05.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class ScoreManager {

    var numberOfThrows = 0
    var numberOfSuccesfulThrows = 0
    var pongsThrowsRatio = 0.0
    var scene:SCNScene!
    
    func updateScoreLabel() {
        scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "scoreNode" {
                let text = SCNText(string: "\(numberOfSuccesfulThrows) cups in \(numberOfThrows) tries", extrusionDepth: 2)
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.red
                text.materials = [material]
                node.geometry = nil
                node.geometry = text
            }
        }
    }

}



