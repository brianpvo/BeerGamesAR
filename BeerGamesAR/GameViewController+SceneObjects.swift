//
//  GameViewController+SceneObjects.swift
//  BeerGamesAR
//
//  Created by Brian Vo on 2018-06-02.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import ARKit

// Scene Objects
extension GameViewController: SCNPhysicsContactDelegate {
    
    // MARK: Setup Scene
    
    func createBall(position:SCNVector3) -> SCNNode {
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.02)) // 0.02
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        ball.position = position
        ball.name = "ball"
        
        return ball
    }
    
    func createRedCup(position: SCNVector3, name: String) -> SCNNode {
        let redCupScene = SCNScene(named: "cup.scnassets/RedSoloCup.scn")
        //let redCupScene = SCNScene(named: "customTableAndCups.scnassets/lowerPolyCup.scn")
        let redCupNode = redCupScene?.rootNode.childNode(withName: "redCup", recursively: false)
        redCupNode?.name = name
        redCupNode?.position = position
        return redCupNode!
    }
    
    func setupGameScene() -> SCNNode {
        
        // add Table Top
        let tableScene = SCNScene(named: "customTableAndCups.scnassets/Table.scn")
        guard let tableNode = tableScene?.rootNode else { return SCNNode() } //.childNode(withName: "table", recursively: false) else { return SCNNode() }
        
        DispatchQueue.global(qos: .default).async {
            let beerPongText = self.createText(text: "BEER PONG")
            tableNode.addChildNode(beerPongText)
            self.nodePhysics.apply()
        }
        return tableNode
    }
    
    func createText(text: String) -> SCNNode {
        let text = SCNText(string: text, extrusionDepth: 2)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        text.materials = [material]
        
        let node = SCNNode(geometry: text)
        node.scale = SCNVector3(0.01, 0.01, 0.01)
        node.position = SCNVector3(0,2,-2)
        node.name = "scoreNode"
        
        return node
    }
    
    func rotateAnimation() -> SCNAction {
        
        let rotateAction = SCNAction.rotate(by: CGFloat.pi, around: SCNVector3(0, 1, 0), duration: 1)
        
        return rotateAction
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        DispatchQueue.global(qos: .background).async {
            
            if nodeA.name == "ball" && nodeB.name?.range(of: "plane") != nil {
                print("ball touched \(nodeB.name!)")
                self.removeCupAndPhysics(contactNode: nodeB)
            }
            if (nodeA.name?.contains("plane"))! && nodeB.name == "ball" {
                print("\(nodeA.name!) touched ball")
                self.removeCupAndPhysics(contactNode: nodeA)
            }
        }
    }
    
    func removeCupAndPhysics(contactNode: SCNNode) {
        self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
            guard let nodeName = contactNode.name,
                let rangeIndex = nodeName.range(of: "_") else { return }
            let nodeNumber = nodeName[rangeIndex.upperBound...]
            if node.name == "cup_" + nodeNumber {
                node.removeFromParentNode()
                self.updateCupState(nodeNumber: String(nodeNumber))
                self.updateBallInPlay(bool: false)
                disableShootButton()
            }
            if node.name == "tube_" + nodeNumber ||
                node.name == "plane_" + nodeNumber ||
                node.name == "ball" {
                node.removeFromParentNode()
                
                // invalidate ball dismissal timer
                dismissBallTimer.invalidate()
            }
        })
    }
}
