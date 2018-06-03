//
//  GameViewController+PlayerState.swift
//  BeerGamesAR
//
//  Created by ruijia lin on 6/3/18.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import UIKit

enum PlayerState{
    case Begin,
    Result,
    End
}

extension GameViewController {
    ///RAY
    
    // Handle different player state
    // - begin: show slider, enable player to shoot the ball
    // - result: determine if ball went in the cup or miss and remove slider
    // - end: back to begining
    func enterPlayerState(state: PlayerState) {
        switch (state) {
        case .Begin:
            UIView.commitAnimations()
            animateToShowBar()
            animateSideBar()
            DispatchQueue.main.async {
                self.button.setTitle("Shoot Ball", for: .normal)
            }
            break;
        case .Result:
            
            // pause animation
            pauseLayer(layer: powerSlider.layer)
            guard let presentationLayer = powerSlider.layer.presentation() else {return}
            let startingPosition = view.frame.size.height * 0.85
            let sliderPosition = Float(presentationLayer.frame.origin.y)
            // calculate the distance between the slider and the stackview color bar to determine the force to be applied to ball
            
            
            sliderValue = Float(startingPosition) / Float(sliderPosition) * 10
            shootBall()
            
            break;
        case .End:
            //reset
            DispatchQueue.main.async {
                self.button.setTitle("Ready", for: .normal)
                self.powerSlider.isHidden = true
                self.gradientStackView.isHidden = true
            }
            
            self.sliderBottomConstraint.isActive = false
            self.sliderBottomConstraint.constant = 0
            self.sliderBottomConstraint.isActive = true
            break;
            
        }
    }
    
    // Pause animation
    func pauseLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    // Resume animation
    func resumeLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
        
        //                    DispatchQueue.main.async {
        //        self.sliderBottomConstraint.isActive = false
        //        self.sliderBottomConstraint.constant = 0
        //        self.sliderBottomConstraint.isActive = true
        //        }
        //        self.enterPlayerState(state: .Begin)
        
    }
    
    private func animateToShowBar(){
        // animate to show side power bar
        UIView.animate(withDuration: 1, delay: 0, options: [.curveEaseInOut], animations: {
            self.powerSlider.isHidden = false
            self.gradientStackView.isHidden = false
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func animateSideBar(){
        UIView.animate(withDuration: 3, delay: 0, options: [.autoreverse, .repeat, .curveLinear], animations: {
            self.sliderBottomConstraint.isActive = false
            self.sliderBottomConstraint.constant = -(self.gradientStackView.frame.size.height * 0.8)
            self.view.layoutIfNeeded()
        }) { (true) in
            UIView.animate(withDuration: 1, delay: 0, options: [.autoreverse, .repeat, .curveEaseIn], animations: {
                self.sliderBottomConstraint.constant = -(self.gradientStackView.frame.size.height)
                self.sliderBottomConstraint.isActive = true
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
}

