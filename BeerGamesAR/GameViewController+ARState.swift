//
//  GameViewController+ARState.swift
//  BeerGamesAR
//
//  Created by Brian Vo on 2018-06-03.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import UIKit
import ARKit
import Firebase
import ARCore

enum ARState {
    case Default,
    CreatingRoom,
    RoomCreated,
    Hosting,
    HostingFinished,
    EnterRoomCode,
    Resolving,
    ResolvingFinished
};

extension GameViewController {
    
    // MARK: Actions
    
    @objc func hostButtonPressed(_ sender: UIButton) {
        myPlayerNumber = 0
        if state == ARState.Default {
            enterState(state: .CreatingRoom)
            createRoom()
        } else {
            enterState(state: .Default)
        }
    }
    
    @objc func resolveButtonPressed(_ sender: UIButton) {
        myPlayerNumber = 1
        if state == ARState.Default {
            enterState(state: .EnterRoomCode)
        } else {
            enterState(state: .Default)
        }
    }
    
    // MARK: Anchor Hosting / Resolving
    
    func resolveAnchorWithRoomCode(roomCode: String) {
        self.roomCode = roomCode
        enterState(state: .Resolving)
        weak var weakSelf = self
        
        // Observe any changes in the room
        firebaseReference?.child("hotspot_list").child(roomCode)
            .observe(.value, with: { (snapshot) in
                DispatchQueue.main.async {
                    guard let strongSelf = weakSelf, let value = snapshot.value as? NSDictionary else { return }
                    if strongSelf.state != ARState.Resolving || !(strongSelf.roomCode == roomCode) {
                        return
                    }
                    guard let anchors = value["hosted_anchor_id"] as? [String] else { return }
                    for anchorId in anchors {
                        strongSelf.resolveAnchorWithIdentifier(identifier: anchorId)
                    }
                    strongSelf.firebaseReference?.child("hotspot_list")
                        .child(roomCode).removeAllObservers()
                }
            })
    }
    
    // Now that we have the anchor ID from firebase, we resolve the anchor.
    // Success and failure of this call is handled by the delegate methods
    // session:didResolveAnchor and session:didFailToResolveAnchor appropriately.
    func resolveAnchorWithIdentifier(identifier: String) {
        guard let gSession = gSession else { return }
        do {
            self.garAnchor = try gSession.resolveCloudAnchor(withIdentifier: identifier)
        } catch {
            print("Couldn't resolve cloud anchor")
        }
    }
    
    func addAnchorWithTransform(transform: matrix_float4x4) {
        arAnchor = ARAnchor(transform: transform)
        sceneView.session.add(anchor: arAnchor!)
        
        // To share an anchor, we call host anchor here on the ARCore session.
        // session:didHostAnchor: session:didFailToHostAnchor: will get called appropriately.
        do {
            garAnchor = try gSession?.hostCloudAnchor(arAnchor!)
            enterState(state: .Hosting)
        } catch {
            print("Error while trying to add new anchor")
        }
    }
    func cloudStateString(cloudState: GARCloudAnchorState) -> String {
        switch (cloudState) {
        case .none:
            return "None";
        case .success:
            return "Success";
        case .errorInternal:
            return "ErrorInternal";
        case .taskInProgress:
            return "TaskInProgress";
        case .errorNotAuthorized:
            return "ErrorNotAuthorized";
        case .errorResourceExhausted:
            return "ErrorResourceExhausted";
        case .errorServiceUnavailable:
            return "ErrorServiceUnavailable";
        case .errorHostingDatasetProcessingFailed:
            return "ErrorHostingDatasetProcessingFailed";
        case .errorCloudIdNotFound:
            return "ErrorCloudIdNotFound";
        case .errorResolvingSdkVersionTooNew:
            return "ErrorResolvingSdkVersionTooNew";
        case .errorResolvingSdkVersionTooOld:
            return "ErrorResolvingSdkVersfionTooOld";
        case .errorResolvingLocalizationNoMatch:
            return "ErrorResolvingLocalizationNoMatch";
        }
    }
    
    func showRoomCodeDialog() {
        let alertController = UIAlertController(title: "ENTER ROOM CODE", message: "", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            guard let alertControllerTextFields = alertController.textFields else { return }
            guard let roomCode = alertControllerTextFields[0].text else { return }
            if roomCode.count == 0 {
                self.enterState(state: .Default)
            } else {
                self.resolveAnchorWithRoomCode(roomCode: roomCode)
            }
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .default) { (action) in
            self.enterState(state: .Default)
        }
        alertController.addTextField { (textField) in
            textField.keyboardType = UIKeyboardType.numberPad
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: false, completion: nil)
    }
    
    func enterState(state: ARState) {
        switch (state) {
        case .Default:
            if let arAnchor = arAnchor {
                sceneView.session.remove(anchor: arAnchor)
                
                // REMOVES ALL NODES FROM SCENE
                sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                    node.removeFromParentNode()
                }
                self.arAnchor = nil;
            }
            if let gSession = gSession, let garAnchor = garAnchor {
                gSession.remove(garAnchor)
                self.garAnchor = nil;
            }
            if (self.state == .CreatingRoom) {
                self.message = "Failed to create room. Tap HOST or RESOLVE to begin.";
            } else {
                self.message = "Tap HOST or RESOLVE to begin.";
            }
            if (self.state == .EnterRoomCode) {
                self.dismiss(animated: false, completion: nil)
            } else if (self.state == .Resolving) {
                if let firebaseReference = firebaseReference, let roomCode = roomCode {
                    firebaseReference.child("hotspot_list").child(roomCode).removeAllObservers()
                }
            }
            toggleButton(button: hostButton, enabled: true, title: "HOST")
            toggleButton(button: resolveButton, enabled: true, title: "RESOLVE")
            roomCode = "";
            break;
        case .CreatingRoom:
            self.message = "Creating room...";
            toggleButton(button: hostButton, enabled: false, title: "HOST")
            toggleButton(button: resolveButton, enabled: false, title: "RESOLVE")
            break;
        case .RoomCreated:
            self.message = "Tap on a plane to create anchor and host.";
            toggleButton(button: hostButton, enabled: true, title: "CANCEL")
            toggleButton(button: resolveButton, enabled: false, title: "RESOLVE")
            break;
        case .Hosting:
            self.message = "Hosting anchor...";
            break;
        case .HostingFinished:
            guard let garAnchor = self.garAnchor else { return }
            self.message = "Finished hosting: \(garAnchor.cloudState)"
            break;
        case .EnterRoomCode:
            self.showRoomCodeDialog()
            break;
        case .Resolving:
            self.dismiss(animated: false, completion: nil)
            self.message = "Resolving anchor...";
            toggleButton(button: hostButton, enabled: false, title: "HOST")
            toggleButton(button: resolveButton, enabled: true, title: "CANCEL")
            break;
        case .ResolvingFinished:
            guard let garAnchor = self.garAnchor else { return }
            self.message = "Finished resolving \(self.cloudStateString(cloudState: garAnchor.cloudState))"
            break;
        }
        self.state = state;
        self.updateMessageLabel()
    }
    
    func createRoom() {
        weak var weakSelf = self
        var roomNumber = 0
        firebaseReference?.child("last_room_code").runTransactionBlock({ (currentData) -> TransactionResult in
            let strongSelf = weakSelf
            
            // cast last room number from firebase database to variable "lastRoomNumber", if unwrapping fails, set lastRoomNumber to 0, which mean there is no last room number documented in firebase database
            if let lastRoomNumber = currentData.value as? Int{
                roomNumber = lastRoomNumber
            } else {
                roomNumber = 0
            }
            
            // Increment the room number and set it as new room number
            roomNumber += 1
            let newRoomNumber = NSNumber(value: roomNumber)
            
            // create timestamp for the room number
            let currentTimestamp = Date()
            let timestampeInt = Int(currentTimestamp.timeIntervalSince1970 * 1000)
            let timestamp = NSNumber(value: timestampeInt)
            
            // create gameState for multiplayer
            let ballState = NSArray(array: [0.0, 0.0, 0.0])
            let cupState = NSArray(array: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
            let gameState = [
                "ball_state" : ballState,
                "ball_in_play" : false,
                "cup_state": cupState,
                "player_joined" : false,
                "player_turn" : 0 // 0 - host, 1 - new player
            ] as [String: Any]
            
            // pass room number, anchor count, and timestamp into newRoom dictionary
            let newRoom = ["display_name" : newRoomNumber.stringValue,
                           "hosted_anchor_count" : 0,
                           "updated_at_timestamp" : timestamp,
                           "game_state" : gameState] as [String : Any]
            
            // create a new node in firebase under hotspot_list to document the new room info with newRoom variable
            strongSelf?.firebaseReference?.child("hotspot_list")
                .child(newRoomNumber.stringValue).setValue(newRoom)
            
            // update node "last_room_code" as reference for next room creation
            currentData.value = newRoomNumber
            return TransactionResult.success(withValue: currentData)
            
        },andCompletionBlock: { (error, committed, snapshot) in
            DispatchQueue.main.async {
                if error != nil{
                    weakSelf?.enterState(state: .Default)
                }else {
                    if let roomCodeValue = snapshot?.value as? NSNumber{
                        weakSelf?.roomCreated(roomCode: roomCodeValue.stringValue)
                    }
                }
            }
        })
    }
    
    private func roomCreated(roomCode: String){
        self.roomCode = roomCode
        self.enterState(state: .RoomCreated)
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("game_state").child("player_joined").observe(.value, with: { (snapshot) in
                guard let player_joined = snapshot.value as? Bool else { return }
                if player_joined {
                    self.observeGameState()
                }
            })
    }
    
    func observeGameState() {
        guard let roomCode = roomCode else { return }
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("game_state").observe(.value, with: { (snapshot) in
                guard let gameState = snapshot.value as? NSDictionary else {
                    print("returning on gameState")
                    return
                }
                guard let player_turn = gameState["player_turn"] as? Int else {
                    print("returning on player turn")
                    return
                }
                guard let ball_in_play = gameState["ball_in_play"] as? Bool else {
                    print("returning on ball in play")
                    return
                }
                guard let ball_position = gameState["ball_state"] as? [NSNumber] else {
                    print("returning on ballposition")
                    return
                }
                guard let cup_state = gameState["cup_state"] as? [Int] else {
                    print("returning on cupstate")
                    return
                }
                self.ballPosition = SCNVector3(ball_position[0].floatValue,
                                               ball_position[1].floatValue,
                                               ball_position[2].floatValue)
                
                if self.isBallInPlay != ball_in_play {
                    if ball_in_play {
                        if self.ballNode == nil {
                            // add a ball
                            print("creating ball")
                            self.ballNode = self.createBall(position: self.ballPosition)
                            self.sceneView.scene.rootNode.addChildNode(self.ballNode)
                        }
                        else {
                            print("translating ball \(self.ballNode.position)")
                            self.sceneView.scene.rootNode.addChildNode(self.ballNode)
                            self.ballNode.position = self.ballPosition
                        }
                    } else {
                        // remove the ball
                        if self.ballNode != nil {
                            self.ballNode.removeFromParentNode()
                        }
                    }
                }
                
                for i in 0..<cup_state.count {
                    if cup_state[i] == 0 {
                        self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                            if (node.name?.range(of: "\(i)")) != nil {
                                node.removeFromParentNode()
                            }
                        })
                    }
                }
                
                if self.playerTurn != player_turn {
                    // opponent unhides button
                    if player_turn == self.myPlayerNumber {
                        self.shootButton.isHidden = false
                        self.slider.isHidden = false
                        
                    } else {
                        self.shootButton.isHidden = true
                        self.slider.isHidden = true
                        self.isBallInPlay = false
                    }
                }
                
                 self.playerTurn = player_turn
            })
    }
}
