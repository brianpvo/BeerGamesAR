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
        guard let tableNode = tableScene?.rootNode.childNode(withName: "table", recursively: false) else { return SCNNode() }
        tableNode.name = "table"
        
        DispatchQueue.global(qos: .default).async {
            // add Table Top
           
            let beerPongText = self.createText(text: "BEER PONG")
            tableNode.addChildNode(beerPongText)
            
            
            
            self.nodePhysics.tableBitMaskAndPhysicsBody(_to: tableNode)
            tableNode.physicsBody?.categoryBitMask = BitMaskCategory.table.rawValue
            tableNode.physicsBody?.contactTestBitMask =
                BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
            tableNode.physicsBody?.collisionBitMask =
                BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
            self.applyPhysics()
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
    
    
    func applyPhysics() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            if node.name?.range(of: "yourRedCup") != nil {
                node.scale = SCNVector3(x: 0.375, y: 0.468, z: 0.375)
                node.physicsBody = nil
            }
            else if node.name?.range(of: "myCup") != nil {
                node.physicsBody = nil
                node.scale = SCNVector3(x: 0.375, y: 0.468, z: 0.375)
            }
            if node.name?.range(of: "Tube") != nil {
                print("resizing tube physics")
                let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: node,
                                                                                options: [SCNPhysicsShape.Option.keepAsCompound : true,
                                                                                          SCNPhysicsShape.Option.scale: SCNVector3(0.057, 0.138, 0.061),
                                                                                          SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron
                    ]))
                node.physicsBody = body
                node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue
            }
            if  node.name?.range(of: "Plane") != nil {
                node.physicsBody = SCNPhysicsBody.static()
                node.physicsBody?.categoryBitMask = BitMaskCategory.plane.rawValue
            }
        }
    }
}
