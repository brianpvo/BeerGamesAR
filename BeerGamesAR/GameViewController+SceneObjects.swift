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
    func createBall(transform: SCNMatrix4) -> SCNNode {
        let ball = SCNNode(geometry: SCNSphere(radius: 0.02)) // 0.02
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        ball.transform = transform
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
        guard let tableNode = tableScene?.rootNode.childNode(withName: "table", recursively: false) else { return SCNNode() }
        
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
        var ballDidBounce = false
        
        DispatchQueue.global(qos: .background).async {
            
            if nodeA.name == "ball" && nodeB.name?.range(of: "plane") != nil {
                print("ball touched \(nodeB.name!)")
                self.removeCupAndPhysics(contactNode: nodeB)
            }
            if (nodeA.name?.contains("plane"))! && nodeB.name == "ball" {
                print("\(nodeA.name!) touched ball")
                self.removeCupAndPhysics(contactNode: nodeA)
            }
            if nodeA.name == "ball" && nodeB.name == "table" {
                // might find inconsistant behavior because table is a parent
                ballDidBounce = true
            }
            if ballDidBounce == true && ((nodeA.name?.contains("plane"))! && nodeB.name == "ball") {
                self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                    self.removeAdditionalCup(node: node)
                })
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
    
    func removeAdditionalCup(node: SCNNode){
        let hitPlaneArray = [node.childNode(withName: "plane_0", recursively: true),
                             node.childNode(withName: "plane_1", recursively: true),
                             node.childNode(withName: "plane_2", recursively: true),
                             node.childNode(withName: "plane_3", recursively: true),
                             node.childNode(withName: "plane_4", recursively: true),
                             node.childNode(withName: "plane_5", recursively: true),
                             node.childNode(withName: "plane_6", recursively: true),
                             node.childNode(withName: "plane_7", recursively: true),
                             node.childNode(withName: "plane_8", recursively: true),
                             node.childNode(withName: "plane_9", recursively: true),
                             node.childNode(withName: "plane_10", recursively: true),
                             node.childNode(withName: "plane_11", recursively: true)
                             ]
        let midPoint = hitPlaneArray.count / 2
        let firstHalf = hitPlaneArray[..<midPoint]
        let secondHalf = hitPlaneArray[midPoint...]
        
        guard let index = hitPlaneArray.index(of: node) else {return}
        var latterIndex = index + 1
        var previousIndex = index - 1
        
        func removeSecondCup(){
            let remainingCupArrayFirstHalf = firstHalf.filter {$0?.parent != nil}
            let remainingCupArraySecondHalf = secondHalf.filter {$0?.parent != nil}
            
            guard remainingCupArrayFirstHalf.count > 2, remainingCupArraySecondHalf.count > 2 else {return}
            
            if latterIndex < hitPlaneArray.count {
                if latterIndex == 6 {return}
                if hitPlaneArray[latterIndex]?.parent != nil {
                    hitPlaneArray[latterIndex]?.removeFromParentNode()
                    return
                }
                if previousIndex > 0 {
                    if previousIndex == 5 {return}
                    if hitPlaneArray[previousIndex]?.parent != nil {
                        hitPlaneArray[previousIndex]?.removeFromParentNode()
                        return
                    }
                }
            }
        }
        latterIndex = latterIndex + 1
        previousIndex = previousIndex - 1
        removeSecondCup()
    }
}
