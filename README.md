# "Beer Pong AR" (Lighthouse Labs - FINAL)
### Main Contributers: [Brian Vo](https://github.com/brianpvo), [Ray Lin](https://github.com/rayjialin), [Raman Singh](https://github.com/singhraman4282), [Tyler Boudreau](https://github.com/thebestboudreau)

## Overview
For this final project, we created augmented reality version of beer pong game which allows users to play with their friends and have others watch the game when players are playing.

We used Blender to create the 3D objects(table, red solo cup).  ARKit to setup the virtual world where we set the anochor to place the table and cups.  For the multiplayer functionality, we utilized the recently released framework Google has released to store AR anchors on Firebase, so that other players can get the table,cups and ping pong ball positions through Firebase.  

Currently our app is only avaiable on App store.

## Pre-Requisites
* iOS version 11.0 or later
* Xcode version 9.3 or later
* iPhone SE to current
* Cocoapods

## Getting Started
1. Fork this repository and clone your forked repository
2. Install pod dependencies using ```pod install``` 
3. Create and setup Google's Cloud Anchor and get the API key. Follow these instructions [here](https://developers.google.com/ar/develop/ios/cloud-anchors-quickstart-ios)
4. Place the API key in the code where it says "CloudAnchorAPIKey"
5. Build and run the app

## Tech Stack
* ARCore
* ARKit
* SceneKit
* Firebase

## Beer Pong AR Rules

Beer Pong AR is played by two players in which each player takes turn throwing a table tennis ball into the other player cups. Once a ball lands in a cup, the cup is taken away and the opponent then drinks the contents of the cup. If the player hits the cup, the ball is rolled back and the player gets to shoot again. The player that successfully hits all of the opponent’s cups wins the game.

## Beer Pong AR Flow
When users open the app, one user needs to host the game, which would create a new room automatically.   Another player can join the game by entering the room number.   The Player who hosts the game will start the turn first.  The floating label in the middle of the table will indicate the score and number of attempts for each player.  When one of the players hits all the cups, the game will end and players can start another game or leave the game.



