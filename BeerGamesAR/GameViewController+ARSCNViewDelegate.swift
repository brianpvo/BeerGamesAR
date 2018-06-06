//
//  GameViewController+ARSCNViewDelegate.swift
//  BeerGamesAR
//
//  Created by Brian Vo on 2018-06-02.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import ARKit
import Firebase
import ARCore

extension GameViewController: ARSCNViewDelegate, ARSessionDelegate, GARSessionDelegate {
    
    // MARK: GARSessionDelegate
    
    func session(_ session: GARSession, didHostAnchor anchor: GARAnchor) {
        if state != ARState.Hosting || anchor != garAnchor {
            return
        }
        garAnchor = anchor
        enterState(state: .HostingFinished)
        
        guard let roomCode = roomCode else { return }
        weak var weakSelf = self
        var anchorCount = 0
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("hosted_anchor_count").runTransactionBlock({ (currentData) -> TransactionResult in
                let strongSelf = weakSelf
                if let lastAnchorCount = currentData.value as? Int {
                    anchorCount = lastAnchorCount
                }
                
                anchorCount += 1
                let anchorIndex = anchorCount - 1
                let anchorNumber = NSNumber(value: anchorCount)
                // Set different id # for different objects
                strongSelf?.firebaseReference?.child("hotspot_list").child(roomCode)
                    .child("hosted_anchor_id").child(NSNumber(value: anchorIndex).stringValue)
                    .setValue(anchor.cloudIdentifier)
                
                // create timestamp for the room number
                let timestampeInt = Int(Date().timeIntervalSince1970 * 1000)
                let timestamp = NSNumber(value: timestampeInt)
                strongSelf?.firebaseReference?.child("hotspot_list").child(roomCode)
                    .child("updated_at_timestamp").setValue(timestamp)
                
                currentData.value = anchorNumber
                return TransactionResult.success(withValue: currentData)
            })
    }
    
    func session(_ session: GARSession, didFailToHostAnchor anchor: GARAnchor) {
        if (state != ARState.Hosting || !(anchor.isEqual(garAnchor))){
            return
        }
        
        garAnchor = anchor
        enterState(state: ARState.HostingFinished)
    }
    
    func session(_ session: GARSession, didResolve anchor: GARAnchor) {
        if state != ARState.Resolving || !(anchor.isEqual(garAnchor)) {
            return
        }
        garAnchor = anchor
        arAnchor = ARAnchor(transform: anchor.transform)
        if let arAnchor = arAnchor {
            sceneView.session.add(anchor: arAnchor)
        }
        enterState(state: ARState.ResolvingFinished)
    }
    
    func session(_ session: GARSession, didFailToResolve anchor: GARAnchor) {
        if (state != ARState.Resolving || !(anchor.isEqual(garAnchor))){
            return
        }
        
        garAnchor = anchor
        enterState(state: ARState.ResolvingFinished)
    }
    
    // MARK: ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // Forward ARKit's update to ARCore session
        do {
            try gSession?.update(frame)
        }catch let error{
            print("fail to update ARKit frame to ARCore session: \(error)")
        }
    }
    // MARK: ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // render SCN with objects
        if !(anchor.isMember(of: ARPlaneAnchor.self)) {
            return self.setupGameScene()
        }
        let scnNode = SCNNode()
        return scnNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // determine position and size of the plane anchor
        if anchor.isMember(of: ARPlaneAnchor.self) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            let width = planeAnchor.extent.x
            let height = planeAnchor.extent.z
            let plane = SCNPlane.init(width: CGFloat(width), height: CGFloat(height))
            
            plane.materials.first?.diffuse.contents = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.3)
            
            let planeNode = SCNNode(geometry: plane)
            
            let x = planeAnchor.center.x
            let y = planeAnchor.center.y
            let z = planeAnchor.center.z
            planeNode.position = SCNVector3Make(x, y, z)
            planeNode.eulerAngles = SCNVector3Make(Float(-Double.pi / 2), 0, 0)
            
            node.addChildNode(planeNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update position and size of plane anchor
        if anchor.isMember(of: ARPlaneAnchor.self) {
            let planeAnchor = anchor as? ARPlaneAnchor
            
            let planeNode = node.childNodes.first
            guard let plane = planeNode?.geometry as? SCNPlane else {return}
            
            if let width = planeAnchor?.extent.x {
                plane.width = CGFloat(width)
            }
            if let height = planeAnchor?.extent.z {
                plane.height = CGFloat(height)
            }
            
            if let x = planeAnchor?.center.x, let y = planeAnchor?.center.y, let z = planeAnchor?.center.z {
                planeNode?.position = SCNVector3Make(x, y, z)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // remove plane node from parent node
        if anchor.isMember(of: ARPlaneAnchor.self){
            let planeNode = node.childNodes.first
            planeNode?.removeFromParentNode()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        guard ballNode != nil, myPlayerNumber != nil, myPlayerNumber == playerTurn else { return }
        let relativePosition = ballNode.presentation.position - sceneView.scene.rootNode.position
        let positionArray = NSArray(array: [NSNumber(value: relativePosition.x),
                                            NSNumber(value: relativePosition.y),
                                            NSNumber(value: relativePosition.z)])
        guard let roomCode = roomCode, roomCode != "" else { return }
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("game_state").child("ball_state").setValue(positionArray)
        
//        if relativePosition.y > -20.0 {
//            ballNode.removeFromParentNode()
////            let nextPlayer = myPlayerNumber == 1 ? 0 : 1
////                firebaseReference?.child("hotspot_list").child(roomCode)
////                    .child("game_state").child("player_turn").setValue(nextPlayer)
//        }
    }
}
