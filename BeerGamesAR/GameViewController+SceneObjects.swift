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
            beerPongText.runAction(self.rotateAnimation())
            //tableTopNode.addChildNode(beerPongText)
            tableNode.addChildNode(beerPongText)
            
            self.nodePhysics.tableBitMaskAndPhysicsBody(_to: tableNode)
            tableNode.physicsBody?.categoryBitMask = BitMaskCategory.table.rawValue
            tableNode.physicsBody?.contactTestBitMask =
                BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
            tableNode.physicsBody?.collisionBitMask =
                BitMaskCategory.ball.rawValue | BitMaskCategory.table.rawValue
            
//            // setup my cups
//            let myRedCup1 = self.createRedCup(position: SCNVector3(0.004, 0.534, 1.027), name: "myCup1")
//            tableNode.addChildNode(myRedCup1)
//            let myRedCup2 = self.createRedCup(position: SCNVector3(-0.055, 0.534, 1.125), name: "myCup2")
//            tableNode.addChildNode(myRedCup2)
//            let myRedCup3 = self.createRedCup(position: SCNVector3(0.06, 0.534, 1.125), name: "myCup3")
//            tableNode.addChildNode(myRedCup3)
//            let myRedCup4 = self.createRedCup(position: SCNVector3(0.117, 0.534, 1.222), name: "myCup4")
//            tableNode.addChildNode(myRedCup4)
//            let myRedCup5 = self.createRedCup(position: SCNVector3(0.004, 0.534, 1.222), name: "myCup5")
//            tableNode.addChildNode(myRedCup5)
//            let myRedCup6 = self.createRedCup(position: SCNVector3(-0.11, 0.534, 1.222), name: "myCup6")
//            tableNode.addChildNode(myRedCup6)
//
//            // setup opponents red cups
//            let yourRedCup1 = self.createRedCup(position: SCNVector3(0.004, 0.534, -0.944), name: "yourRedCup1")
//            tableNode.addChildNode(yourRedCup1)
//            let yourRedCup2 = self.createRedCup(position: SCNVector3(-0.055, 0.534, -1.042), name: "yourRedCup2")
//            tableNode.addChildNode(yourRedCup2)
//            let yourRedCup3 = self.createRedCup(position: SCNVector3(0.06, 0.534, -1.042), name: "yourRedCup3")
//            tableNode.addChildNode(yourRedCup3)
//            let yourRedCup4 = self.createRedCup(position: SCNVector3(0.117, 0.534, -1.139), name: "yourRedCup4")
//            tableNode.addChildNode(yourRedCup4)
//            let yourRedCup5 = self.createRedCup(position: SCNVector3(0.004, 0.534, -1.139), name: "yourRedCup5")
//            tableNode.addChildNode(yourRedCup5)
//            let yourRedCup6 = self.createRedCup(position: SCNVector3(-0.11, 0.534, -1.139), name: "yourRedCup6")
//            tableNode.addChildNode(yourRedCup6)
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
