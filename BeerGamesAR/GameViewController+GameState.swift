//
//  GameViewController+GameState.swift
//  BeerGamesAR
//
//  Created by Brian Vo on 2018-06-07.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import Foundation
import ARKit
//import AudioToolbox

extension GameViewController {
    
    func observeGameState() {
        self.inGame = true;
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
                    print("returning on ball state")
                    return
                }
                guard let cup_state = gameState["cup_state"] as? [Int] else {
                    print("returning on cup state")
                    return
                }
                let p = ball_position
                let ballTransform = SCNMatrix4(m11: p[0].floatValue, m12: p[1].floatValue,
                                               m13: p[2].floatValue, m14: p[3].floatValue,
                                               m21: p[4].floatValue, m22: p[5].floatValue,
                                               m23: p[6].floatValue, m24: p[7].floatValue,
                                               m31: p[8].floatValue, m32: p[9].floatValue,
                                               m33: p[10].floatValue, m34: p[11].floatValue,
                                               m41: p[12].floatValue, m42: p[13].floatValue,
                                               m43: p[14].floatValue, m44: p[15].floatValue)
                
                if self.isBallInPlay != ball_in_play {
                    if ball_in_play {
                        if self.ballNode == nil {
                            // add a ball
                            print("creating ball")
                            self.ballNode = self.createBall(transform: ballTransform)
                            self.tableNode.addChildNode(self.ballNode)
                        }
                        else {
                            self.ballNode.transform = ballTransform
                            
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
                            if node.name == "cup_\(i)" {
                                node.isHidden = true
//                                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                            }
                            if node.name == "tube_\(i)" ||
                                node.name == "plane_\(i)" {
                                //node.removeFromParentNode()
                                node.isHidden = true
                                node.physicsBody?.collisionBitMask = 0
                            }
                        })
                    }
                    
                }
                
                // Switch turns for each round
                if self.playerTurn != player_turn {
                    // opponent unhides button
                    if player_turn == self.myPlayerNumber {
                        DispatchQueue.main.async {
                            self.shootButton.isHidden = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.shootButton.isHidden = true
                            self.slider.isHidden = true
                        }
                        self.ballNode = nil
                    }
                    self.isBallInPlay = false
                }
                self.playerTurn = player_turn
                
                // Check if the game is over
                self.checkForWinner(cupArray: cup_state,
                                    leftBound: 0, rightBound: 5,
                                    player: 1)
                self.checkForWinner(cupArray: cup_state,
                                    leftBound: 6, rightBound: 11,
                                    player: 2)
            })
    }
    
    private func checkForWinner(cupArray: [Int], leftBound: Int, rightBound: Int, player: Int) {
        let range = leftBound...rightBound
        let player1Cups = cupArray[range].filter{ $0 == 0 }
        if player1Cups.count == range.count {
            let winner = self.createText(text: "GAME OVER!",
                textColor: .orange,
                position: SCNVector3(0.0, 1.2, 0.0),
                scale: SCNVector3(0.02, 0.015, 0.01))
            winner.runAction(self.rotateAnimation())
            self.tableNode.addChildNode(winner)
            self.removeGameStateObserver()
            Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self]_ in
                DispatchQueue.main.async {
                    self?.showResetGameDialog()
                }
            }
        }
    }
    
    private func checkResetGameState(reset_status: [Int]) {
        let bothPlayerAccept = reset_status.filter { $0 == 1 }
        let onePlayerReject = reset_status.filter { $0 == 0 }
        if onePlayerReject.count > 0 {
            self.enterState(state: .Default)
        }
        if bothPlayerAccept.count == 2 {
            self.resetGame()
        }
    }
    
    private func showResetGameDialog() {
        let alertController = UIAlertController(title: "RESET GAME?", message: "", preferredStyle: .alert)
        guard let roomCode = self.roomCode, let myPlayerNumber = self.myPlayerNumber else { return }
        let yesAction = UIAlertAction(title: "YES", style: .default) { (action) in
            self.firebaseReference?.child("hotspot_list").child(roomCode)
                .child("game_state").child("reset_game").updateChildValues(["\(myPlayerNumber)" : 1])
        }
        let noAction = UIAlertAction(title: "NO", style: .default) { (action) in
            self.firebaseReference?.child("hotspot_list").child(roomCode)
                .child("game_state").child("reset_game").updateChildValues(["\(myPlayerNumber)" : 0])
        }
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        self.present(alertController, animated: false, completion: nil)
        
        self.firebaseReference?.child("hotspot_list").child(roomCode).child("game_state")
            .child("reset_game").observe(.value, with: { (snapshot) in
                guard let resetGameStatus = snapshot.value as? [Int] else { return }
                self.checkResetGameState(reset_status: resetGameStatus)
            })
    }
    
    private func resetGame() {
        self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
            node.isHidden = false
            if node.name?.range(of: "tube") != nil ||
                node.name?.range(of: "plane") != nil {
                node.physicsBody?.collisionBitMask = BitMaskCategory.ball.rawValue
            }
            if node.name == "scoreNode" {
                node.removeFromParentNode()
            }
        })
        
        // Reset firebase data
        let ballState = NSArray(array: [0.0, 0.0, 0.0, 0.0,
                                        0.0, 0.0, 0.0, 0.0,
                                        0.0, 0.0, 0.0, 0.0,
                                        0.0, 0.0, 0.0, 0.0])
        let cupState = NSArray(array: [1, 1, 1, 1, 1, 1,
                                       1, 1, 1, 1, 1, 1])
        let gameState = [
            "ball_state" : ballState,
            "ball_in_play" : false,
            "cup_state": cupState,
            "player_joined" : false,
            "player_turn" : 1, // switch player
            "reset_game" : NSArray(array: [2, 2])
            ] as [String: Any]
        guard let roomCode = roomCode, roomCode.count != 0 else { return }
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("game_state").setValue(gameState)
        self.observeGameState()
    }
    
    func removeGameStateObserver() {
        DispatchQueue.main.async {
            self.shootButton.isHidden = true
            self.slider.isHidden = true
        }
        guard let roomCode = roomCode, roomCode.count != 0 else { return }
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("game_state").removeAllObservers()
        self.inGame = false;
    }
    
    func startBallTimer(){
        DispatchQueue.main.async {
            self.dismissBallTimer = Timer.scheduledTimer(timeInterval: 3,
                                                         target: self,
                                                         selector: #selector(self.dismissBall),
                                                         userInfo: nil,
                                                         repeats: false)
        }
    }
    
    @objc func dismissBall(){
        ballNode.removeFromParentNode()
        ballNode = nil
        updatePlayerTurn()
        updateBallInPlay(bool: false)
        dismissBallTimer.invalidate()
    }
    
    func updateCupState(nodeNumber: String) {
        guard let roomCode = roomCode else { return }
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("game_state").child("cup_state").updateChildValues([nodeNumber : 0])
    }
    
    func updatePlayerTurn() {
        guard let roomCode = roomCode else { return }
        let nextPlayer = myPlayerNumber == 1 ? 0 : 1
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("game_state").child("player_turn").setValue(nextPlayer)
    }
    
    func updateBallInPlay(bool: Bool) {
        guard let roomCode = roomCode else { return }
        firebaseReference?.child("hotspot_list").child(roomCode)
            .child("game_state").child("ball_in_play").setValue(bool)
    }
    
    func toggleShootButton() {
        DispatchQueue.main.async {
            self.shootButton.isUserInteractionEnabled = self.shouldAllowPlayerInteraction
            self.shootButton.imageView?.image = self.shouldAllowPlayerInteraction ? self.interactiveColor : self.nonInteractiveColor
            self.slider.isHidden = !self.shouldAllowPlayerInteraction
        }
    }
    
    var shouldAllowPlayerInteraction: Bool {
        get {
            return (playerTurn == myPlayerNumber) && !isBallInPlay && inGame
        }
    }
    
    var nonInteractiveColor: UIImage {
        get {
            return #imageLiteral(resourceName: "oval-grey")
        }
    }
    var interactiveColor: UIImage {
        get {
            return #imageLiteral(resourceName: "oval-white")
        }
    }
}
