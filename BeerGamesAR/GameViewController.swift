//  Created by Brian Vo on 2018-05-25.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.

import UIKit
import ARKit
import Firebase
import ARCore
import ModelIO
import SceneKit

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


class GameViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, GARSessionDelegate, UIGestureRecognizerDelegate {
    
    // OUTLETS
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var hostButton: UIButton!
    @IBOutlet weak var resolveButton: UIButton!
    @IBOutlet weak var roomCodeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var menuWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuBarView: UIView!
    
    // API VARIABLES
    var firebaseReference: DatabaseReference?
    var gSession: GARSession?
    var arAnchor: ARAnchor?
    var garAnchor: GARAnchor?
    
    // ENUM VARIABLES
    var state: ARState?
    
    // NORMAL VARIABLES
    var message: String?
    var roomCode: String?
    var hostButton2: UIButton!
    var resolveButton2: UIButton!
    var ballNode: SCNNode!
    var cameraOrientation: SCNVector3!
    var cameraPosition: SCNVector3!
    var panGesture: UIPanGestureRecognizer!
    var timer = Timer()
    var isGestureEnabled = true
    var camera: SCNNode!
    
    // MARK - Overriding UIViewController
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firebaseReference = Database.database().reference()
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        do {
            gSession = try GARSession.init(apiKey: ARCoreAPIKey, bundleIdentifier: nil)
        } catch {
            print("Couldn't initialize GAR session")
        }
        if let gSession = gSession {
            gSession.delegate = self
            gSession.delegateQueue = DispatchQueue.main
            enterState(state: .Default)
        }
        
        self.setupButtons()
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)
        createBall()
    }
    
    @objc private func didPan(_ gesture: UIPanGestureRecognizer){
        let touchLocation = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
        guard let resultPoint = hitTestResults.first else {return}
        
        if isGestureEnabled == true{
            switch gesture.state {
            case .changed:
                let position = SCNVector3Make(
                    resultPoint.worldTransform.columns.3.x,
                    resultPoint.worldTransform.columns.3.y,
                    resultPoint.worldTransform.columns.3.z
                )
                ballNode.position = position
            case .ended:
                let velocity = gesture.velocity(in: sceneView)
                let transform = sceneView.transform
                velocity.applying(transform)
                
                let velocityX: Float = Float(velocity.x / 100)
                let velocityY: Float = Float(abs(velocity.y / 400))
                let velocityZ: Float = Float(velocity.y / 300)
                let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                let direction = SCNVector3(
                    velocityX,
                    velocityY,
                    velocityZ
                )
                physicsBody.applyForce(direction, asImpulse: true)
                ballNode.physicsBody = physicsBody
                
                isGestureEnabled = false
            default:
                print(" ")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count < 1 || state != ARState.RoomCreated {
            return
        }
        let touch = touches.first!
        let touchLocation = touch.location(in: sceneView)
        
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlane, .existingPlaneUsingExtent, .estimatedHorizontalPlane])
        guard let result = hitTestResult.first else { return }
        self.addAnchorWithTransform(transform: result.worldTransform)
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
                        //                        print(anchorId)
                        strongSelf.resolveAnchorWithIdentifier(identifier: anchorId)
                    }
                    strongSelf.firebaseReference?.child("hotspot_list").child(roomCode).removeAllObservers()
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
        //        sceneView.pointOfView?.addChildNode(createBall())
        
        // To share an anchor, we call host anchor here on the ARCore session.
        // session:didHostAnchor: session:didFailToHostAnchor: will get called appropriately.
        do {
            garAnchor = try gSession?.hostCloudAnchor(arAnchor!)
            enterState(state: .Hosting)
        } catch {
            print("Error while trying to add new anchor")
        }
    }
    
    // MARK: Actions
    
    @IBAction func hostButtonPressed(_ sender: UIButton) {
        if state == ARState.Default {
            enterState(state: .CreatingRoom)
            createRoom()
        } else {
            enterState(state: .Default)
        }
    }
    
    @IBAction func resolveButtonPressed(_ sender: UIButton) {
        if state == ARState.Default {
            enterState(state: .EnterRoomCode)
        } else {
            enterState(state: .Default)
        }
    }
    
    @IBAction func menuButtonPressed(_ sender: UIButton) {
        self.menuWidthConstraint.constant = self.menuWidthConstraint.constant == 200 ? 20 : 200
        UIView.animate(withDuration: 1.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 3, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.hostButton2.isHidden = false
            self.resolveButton2.isHidden = false
        }, completion: nil)
    }
    
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
    
    // MARK - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //  capture camera position and orientation
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        guard let frame = sceneView.session.currentFrame else {return}
        cameraOrientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        cameraPosition = SCNVector3(transform.m41,
                                    transform.m42, transform.m43)
        
        if ballNode.presentation.position.y <= -50{
            ballNode.removeFromParentNode()
            createBall()
            isGestureEnabled = true
        }
        
        // Forward ARKit's update to ARCore session
        do {
            try gSession?.update(frame)
        }catch let error{
            print("fail to update ARKit frame to ARCore session: \(error)")
        }
    }
    
    // MARK: Helper Methods
    
    func setupButtons() {
        hostButton2 = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        hostButton2.setTitle("HOST", for: .normal)
        hostButton2.addTarget(self, action: #selector(hostButtonPressed(_:)), for: .touchUpInside)
        menuBarView.addSubview(hostButton2)
        hostButton2.translatesAutoresizingMaskIntoConstraints = false
        
        resolveButton2 = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        resolveButton2.setTitle("RESOLVE", for: .normal)
        resolveButton2.addTarget(self, action: #selector(resolveButtonPressed(_:)), for: .touchUpInside)
        menuBarView.addSubview(resolveButton2)
        resolveButton2.translatesAutoresizingMaskIntoConstraints = false
        
        self.hostButton2.centerYAnchor.constraint(equalTo: self.menuBarView.centerYAnchor, constant: 0).isActive = true
        self.resolveButton2.rightAnchor.constraint(equalTo: self.menuBarView.rightAnchor, constant: -50).isActive = true
        self.resolveButton2.centerYAnchor.constraint(equalTo: self.menuBarView.centerYAnchor, constant: 0).isActive = true
        self.hostButton2.rightAnchor.constraint(equalTo: self.resolveButton2.leftAnchor, constant: -10).isActive = true
        
        hostButton2.isHidden = true
        resolveButton2.isHidden = true
        
        hostButton.isHidden = true
        resolveButton.isHidden = true
    }
    
    func updateMessageLabel() {
        self.messageLabel.text = self.message
        self.roomCodeLabel.text = "Room: \(roomCode ?? "0000")"
    }
    
    func toggleButton(button: UIButton?, enabled: Bool, title: String?) {
        guard let button = button, let title = title else { return }
        button.isEnabled = enabled
        button.setTitle(title, for: UIControlState.normal)
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
            
            // pass room number, anchor count, and timestamp into newRoom dictionary
            let newRoom = ["display_name" : newRoomNumber.stringValue,
                           "hosted_anchor_count" : 0,
                           "updated_at_timestamp" : timestamp] as [String : Any]
            
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
    }
    
    func createRedCup(position: SCNVector3) -> SCNNode {
        let redCupScene = SCNScene(named: "cup.scnassets/RedSoloCup.scn")
        let redCupNode = redCupScene?.rootNode.childNode(withName: "redCup", recursively: false)
        redCupNode?.name = "cup"
        redCupNode?.position = position
        return redCupNode!
    }
    
    func setupGameScene() -> SCNNode {
        let scene = SCNScene(named: "example.scnassets/andy.scn")
        guard let anchorNode = scene?.rootNode.childNode(withName: "andy", recursively: false) else {
            return SCNNode()
        }
        
        // add Table Top
        let tableScene = SCNScene(named: "table.scnassets/Table.scn")
        guard let tableNode = tableScene?.rootNode.childNode(withName: "table", recursively: false),
            let tableTopNode = tableScene?.rootNode.childNode(withName: "tableTopCenter", recursively: false) else {
                return SCNNode()
        }
        tableNode.name = "table"
        tableTopNode.name = "tableTop"
        tableTopNode.addChildNode(anchorNode)
        
        // setup my red cups
        let myRedCup1 = createRedCup(position: SCNVector3(0.0, 0.01, 2.38))
        tableTopNode.addChildNode(myRedCup1)
        let myRedCup2 = createRedCup(position: SCNVector3(0.18, 0.01, 2.69))
        tableTopNode.addChildNode(myRedCup2)
        let myRedCup3 = createRedCup(position: SCNVector3(-0.18, 0.01, 2.69))
        tableTopNode.addChildNode(myRedCup3)
        let myRedCup4 = createRedCup(position: SCNVector3(0.37, 0.01, 3.0))
        tableTopNode.addChildNode(myRedCup4)
        let myRedCup5 = createRedCup(position: SCNVector3(0.0, 0.01, 3.0))
        tableTopNode.addChildNode(myRedCup5)
        let myRedCup6 = createRedCup(position: SCNVector3(-0.37, 0.01, 3.0))
        tableTopNode.addChildNode(myRedCup6)
        
        // setup opponents red cups
        let yourRedCup1 = createRedCup(position: SCNVector3(0.0, 0.01, -2.38))
        tableTopNode.addChildNode(yourRedCup1)
        let yourRedCup2 = createRedCup(position: SCNVector3(0.18, 0.01, -2.69))
        tableTopNode.addChildNode(yourRedCup2)
        let yourRedCup3 = createRedCup(position: SCNVector3(-0.18, 0.01, -2.69))
        tableTopNode.addChildNode(yourRedCup3)
        let yourRedCup4 = createRedCup(position: SCNVector3(0.37, 0.01, -3.0))
        tableTopNode.addChildNode(yourRedCup4)
        let yourRedCup5 = createRedCup(position: SCNVector3(0.0, 0.01, -3.0))
        tableTopNode.addChildNode(yourRedCup5)
        let yourRedCup6 = createRedCup(position: SCNVector3(-0.37, 0.01, -3.0))
        tableTopNode.addChildNode(yourRedCup6)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.nodeResize()
        }
        tableNode.addChildNode(tableTopNode)
        return tableNode
    }
    
    @objc func createBall(){
        let ballGeo = SCNSphere(radius: 0.15)
        ballNode = SCNNode(geometry: ballGeo)
        let ballMaterial = SCNMaterial()
        ballMaterial.diffuse.contents = UIImage(named: "ball.scnassets/ballTextDirty.png")
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: ballGeo, options: nil))
        ballGeo.materials = [ballMaterial]
        ballNode.physicsBody?.isAffectedByGravity = false
        ballNode.position = SCNVector3(0, -0.5, -1)
        
        sceneView.scene.rootNode.addChildNode(ballNode)

    }
    
    func nodeResize() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            if node.name == "cup" {
                node.scale = SCNVector3(x: 1.2, y: 1.2, z: 1.2)
            }
            if node.name == "table" {
                node.scale = SCNVector3(x: 0.2, y: 0.4, z: 0.3)
            }
            if node.name == "tableTop" {
                node.position = SCNVector3(0, 1.65, 0)
            }
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
    
    // NOTE: use this method to show where the cup placements on the table will go
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
        if anchor.isMember(of: ARPlaneAnchor.self){
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
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

