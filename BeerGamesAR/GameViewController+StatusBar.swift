//
//  GameViewController+StatusBar.swift
//  BeerGamesAR
//
//  Created by ruijia lin on 6/9/18.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import UIKit
import ARKit

extension GameViewController {
    
    // update message and remove it after 6 seconds
    func scheduleMessage() {
        updateMessageLabel()
        
        let _ = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.messagePanel.isHidden = true
            }
        }
    }
    
    @objc func updateMessageLabel() {
        DispatchQueue.main.async {
            self.messagePanel.isHidden = false
            self.messageLabel.text = self.message
            self.roomCodePanel.isHidden = false
            self.roomCodeLabel.text = self.roomCode != "" ? "Room: \(self.roomCode ?? "0000")" : ""
        }
    }
}

extension ARCamera.TrackingState {
    var presentationStr: String {
        switch self {
        case .notAvailable:
            return "TRACKING UNAVAILABLE"
        case .normal:
            return "TRACKING NORMAL\nFind horizontal surface\nTap on HOST or JOIN to start game"
        case .limited(.excessiveMotion):
            return "TRACKING LIMITED\nExcessive motion"
        case .limited(.insufficientFeatures):
            return "TRACKING LIMITED\nLow detail"
        case .limited(.initializing):
            return "Initializing"
        case .limited(.relocalizing):
            return "Recovering from interruption"
        }
    }
    
    var recommendStr: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface."
        case .limited(.relocalizing):
            return "Return to the location where you left off."
        default:
            return nil
        }
    }
}
