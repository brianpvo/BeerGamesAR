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
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.02))
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
//        tableNode.name = "table"
        
        DispatchQueue.global(qos: .default).async {
            // add Table Top
           
            let beerPongText = self.createText(text: "BEER PONG")
            beerPongText.runAction(self.rotateAnimation())
            //tableTopNode.addChildNode(beerPongText)
            tableNode.addChildNode(beerPongText)
            self.nodePhysics.applyPhysics()
        }
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
        node.position = SCNVector3(0, 0.01, 0)
        node.scale = SCNVector3(0.01, 0.01, 0.01)
        return node
    }
    
    func rotateAnimation() -> SCNAction {
        let rotateAction = SCNAction.rotate(by: 2 * CGFloat.pi, around: SCNVector3(0, 1, 0), duration: 10)
        return SCNAction.repeatForever(rotateAction)
    }
}
