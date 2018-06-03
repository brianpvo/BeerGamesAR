//
//  GameViewController+SceneObjects.swift
//  BeerGamesAR
//
//  Created by Brian Vo on 2018-06-02.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import ARKit

extension GameViewController {
    
    // MARK: Setup Scene
    
    func createBallShoot(_with position:SCNVector3) -> SCNNode {
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.15))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        ball.position = position
        ball.name = "ball"
        
        return ball
    }
    
    func createRedCup(position: SCNVector3) -> SCNNode {
        let redCupScene = SCNScene(named: "cup.scnassets/RedSoloCup.scn")
        let redCupNode = redCupScene?.rootNode.childNode(withName: "redCup", recursively: false)
        redCupNode?.name = "cup"
        redCupNode?.position = position
        return redCupNode!
    }
    
    func setupGameScene() -> SCNNode {
        let scene = SCNScene(named: "example.scnassets/andy.scn")
        guard let anchorNode = scene?.rootNode.childNode(withName: "andy", recursively: false) else {
            return SCNNode()
        }
        
        // add Table Top
        let tableScene = SCNScene(named: "table.scnassets/Table.scn")
        guard let tableNode = tableScene?.rootNode.childNode(withName: "table", recursively: false),
            let tableTopNode = tableScene?.rootNode.childNode(withName: "tableTopCenter", recursively: false) else {
                return SCNNode()
        }
        tableNode.name = "table"
        tableTopNode.name = "tableTop"
        tableTopNode.addChildNode(anchorNode)
        let beerPongText = createText(text: "BEER PONG")
        beerPongText.runAction(rotateAnimation())
        tableTopNode.addChildNode(beerPongText)
        
        // setup my red cups
        let myRedCup1 = createRedCup(position: SCNVector3(0.0, 0.01, 2.38))
        tableTopNode.addChildNode(myRedCup1)
        let myRedCup2 = createRedCup(position: SCNVector3(0.18, 0.01, 2.69))
        tableTopNode.addChildNode(myRedCup2)
        let myRedCup3 = createRedCup(position: SCNVector3(-0.18, 0.01, 2.69))
        tableTopNode.addChildNode(myRedCup3)
        let myRedCup4 = createRedCup(position: SCNVector3(0.37, 0.01, 3.0))
        tableTopNode.addChildNode(myRedCup4)
        let myRedCup5 = createRedCup(position: SCNVector3(0.0, 0.01, 3.0))
        tableTopNode.addChildNode(myRedCup5)
        let myRedCup6 = createRedCup(position: SCNVector3(-0.37, 0.01, 3.0))
        tableTopNode.addChildNode(myRedCup6)
        
        // setup opponents red cups
        let yourRedCup1 = createRedCup(position: SCNVector3(0.0, 0.01, -2.38))
        tableTopNode.addChildNode(yourRedCup1)
        let yourRedCup2 = createRedCup(position: SCNVector3(0.18, 0.01, -2.69))
        tableTopNode.addChildNode(yourRedCup2)
        let yourRedCup3 = createRedCup(position: SCNVector3(-0.18, 0.01, -2.69))
        tableTopNode.addChildNode(yourRedCup3)
        let yourRedCup4 = createRedCup(position: SCNVector3(0.37, 0.01, -3.0))
        tableTopNode.addChildNode(yourRedCup4)
        let yourRedCup5 = createRedCup(position: SCNVector3(0.0, 0.01, -3.0))
        tableTopNode.addChildNode(yourRedCup5)
        let yourRedCup6 = createRedCup(position: SCNVector3(-0.37, 0.01, -3.0))
        tableTopNode.addChildNode(yourRedCup6)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.nodeResize()
        }
        tableNode.addChildNode(tableTopNode)
        return tableNode
    }
    
    @objc func createBall(position: SCNVector3){
        let ballGeo = SCNSphere(radius: 0.15)
        ballNode = SCNNode(geometry: ballGeo)
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = UIImage(named: "ball.scnassets/ballTextWhite.tif")
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: ballGeo, options: nil))
        ballGeo.materials = [ballMaterial]
        ballNode.physicsBody?.isAffectedByGravity = false
        ballNode.position = position
        
        sceneView.scene.rootNode.addChildNode(ballNode)
    }
    
    func createText(text: String) -> SCNNode {
        let text = SCNText(string: text, extrusionDepth: 2)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        text.materials = [material]
        
        let node = SCNNode(geometry: text)
        node.position = SCNVector3(0, 1, 0)
        node.scale = SCNVector3(0.01, 0.01, 0.01)
        return node
    }
    
    func rotateAnimation() -> SCNAction {
        let rotateAction = SCNAction.rotate(by: 2 * CGFloat.pi, around: SCNVector3(0, 1, 0), duration: 10)
        return SCNAction.repeatForever(rotateAction)
    }
    
    
    func nodeResize() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            if node.name == "cup" {
                node.scale = SCNVector3(x: 1.2, y: 1.2, z: 1.2)
                nodePhysics.cupBitMaskAndPhysicsBody(_to: node)
            }
            if node.name == "table" {
                node.scale = SCNVector3(x: 0.2, y: 0.4, z: 0.3)
            }
            if node.name == "tableTop" {
                node.position = SCNVector3(0, 1.65, 0)
            }
        }
    }
}
