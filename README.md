# "Beer Pong AR" (Lighthouse Labs - FINAL)
### Main Contributers: [Brian Vo](https://github.com/brianpvo), [Ray Lin](https://github.com/rayjialin), [Raman Singh](https://github.com/singhraman4282), [Tyler Boudreau](https://github.com/thebestboudreau)

## Overview
For this final project, we created an augmented reality version of beer pong which allows users to play with their friends (and soon to allow spectators).

Beer Pong AR is played by two people in which each player takes turn throwing a ping pong ball into the other player cups. Once a ball lands in a cup, the cup is taken away and the player gets to shoot again. If the ball thrown bounces off the table and sinks into a cup, the player is rewarded with an extra cup taken away. The player that successfully hits all of the opponent’s cups wins the game.

## Screenshots
<img src="/docs/assets/images/screenshot/ss04.png" width="250"><img src="/docs/assets/images/screenshot/ss06.png" width="250"><img src="/docs/assets/images/screenshot/ss07.png" width="250">

## Pre-Requisites
* iOS version 11.3 or later
* Xcode version 9.3 or later
* iPhone SE to current
* Cocoapods
* WiFi or Mobile Data

## Getting Started
1. Fork this repository and clone your forked repository
2. Install pod dependencies using ```pod install``` 
3. Create and setup Google's Cloud Anchor and get the API key. Follow these instructions [here](https://developers.google.com/ar/develop/ios/cloud-anchors-quickstart-ios).
4. Place the API key in the code where it says "ARCoreAPIKey"
5. Build and run the app

## Tech Stack
* ARCore
* ARKit
* SceneKit
* Firebase

## 3D Models - Made using Blender
* Red Solo Cup
* Table

## Game Instructions

Open the app and find a non-shiny and non-white horizontal surface. Wait till you see a blue plane on the surface and then press host, which would create a new room and room number automatically. Proceed to tap anywhere on the detected surface for the desired table setup. Wait till you see the label on the screen that says the game is set up. Another user running the app needs to stand beside the host user while detecting a similar horizontal surface. Once the surface is detected, they can join the game by entering the same room number. You should both see the beer pong set up on each screen. Proceed to stand on either side of the table where the game will begin. The player who is hosting the game will have the first throw. 

There is a floating label that will indicate the score and number of attempts for each player. When one of the players hits all the cups, the game will end and players can start another game or leave the game.
