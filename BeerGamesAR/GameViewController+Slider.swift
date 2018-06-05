//
//  GameViewController+Slider.swift
//  BeerGamesAR
//
//  Created by Raman Singh on 2018-06-05.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import Firebase
import ARCore

extension GameViewController {

    @objc func sliderChanged(sender: UISlider) {
        print(slider.value)
    }
    
    func createSlider() {
        slider = CustomSlider(frame: CGRect.zero)
        slider.transform = CGAffineTransform.init(rotationAngle:-.pi/2)
        slider.minimumValue = 0.5
        slider.maximumValue = 5.0
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.isContinuous = false
        let xPos = view.frame.maxX - view.frame.width * 0.1
        let yPos:CGFloat = 200.0
        let width = view.frame.width * 0.1
        let height = view.frame.height * 0.5
        let sliderFrame = CGRect(x: xPos, y: yPos, width: width, height: height)
        slider.frame = sliderFrame
        view.addSubview(slider)
        slider.maximumTrackTintColor = UIColor.clear
        slider.thumbTintColor = UIColor.clear
        slider.trackWidth = 5.0
    }
    
    
    @objc func runTimer() {
        
        if (slider.value != 5.0 && sliderGoingUp) || slider.value == 0.5 {
            power += 0.1
            powerGoingUp()
        }
        
        if (slider.value != 0.5 && sliderGoingDown) || slider.value == 5.0 {
            power -= 0.1
            powerGoingDown()
        }
        
        slider.value = power
        
        changeMinTrackColor()
        
        
    }
    
    func powerGoingUp() {
        sliderGoingUp = true
        sliderGoingDown = false
    }
    
    func powerGoingDown() {
        sliderGoingUp = false
        sliderGoingDown = true
    }
    
    func changeMinTrackColor() {
        
        if power <= 1.7 {
            slider.minimumTrackTintColor = UIColor.orange
        }
        
        if power > 1.7 && power <= 3.4 {
            slider.minimumTrackTintColor = UIColor.green
        }
        
        if power > 3.4 {
            slider.minimumTrackTintColor = UIColor.red
        }
        
    }
    
   @objc func setupSlider() {
    print("setupSlider called")
        createSlider()
        slider.value = 1.0
        sliderTimer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(runTimer), userInfo: nil, repeats: true)
        slider.isUserInteractionEnabled = false
    }

    
    @objc func testFunc() {
        print("test")
    }





}
