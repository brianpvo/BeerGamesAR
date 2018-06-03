//  Created by Brian Vo on 2018-05-25.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.

import UIKit
import ARKit
import Firebase
import ARCore
import ModelIO
import SceneKit

class GameViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // OUTLETS
    @IBOutlet weak var sceneView: ARSCNView!
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
    var hostButton: UIButton!
    var resolveButton: UIButton!
    var nodePhysics: NodePhysics!
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
        
        nodePhysics = NodePhysics(scene: self.sceneView.scene)
        self.sceneView.scene.physicsWorld.contactDelegate = nodePhysics
        
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
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        button.backgroundColor = UIColor.green
        button.setTitle("Shoot Ball", for: UIControlState.normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.view.addSubview(button)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)
        createBall(position: SCNVector3((sceneView.pointOfView?.presentation.position.x)!,
                                        (sceneView.pointOfView?.presentation.position.y)!,
                                        (sceneView.pointOfView?.presentation.position.z)! - 0.5))
    }
    
    @objc private func didPan(_ gesture: UIPanGestureRecognizer){
        let touchLocation = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
        guard let resultPoint = hitTestResults.first else {return}
        
        //if resultPoint.worldTransform.translation
        
        if isGestureEnabled {
            switch gesture.state {
            case .changed:
                let position = SCNVector3Make(
                    resultPoint.worldTransform.translation.x,
                    resultPoint.worldTransform.translation.y,
                    resultPoint.worldTransform.translation.z
                )
                ballNode.position = position
            case .ended:
                let velocity = gesture.velocity(in: sceneView)
                let transform = sceneView.transform
//                guard let pointOfView = sceneView.pointOfView else { return }
//                let transform = pointOfView.transform
                velocity.applying(transform)
                
                let velocityX: Float = Float(velocity.x / 100)
                let velocityY: Float = Float(abs(velocity.y / 400))
                let velocityZ: Float = Float(velocity.y / 300)
                let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                let direction = SCNVector3(
                    0,
                    velocityY,
                    velocityZ
                )
//                let power: Float = 0.5
//                cameraOrientation = SCNVector3(-transform.m31,
//                                               -transform.m32,
//                                               -transform.m33)
                nodePhysics.ballBitMaskAndPhysicsBody(_to: ballNode)
//                ballNode.physicsBody?.applyForce(SCNVector3(cameraOrientation.x*power,
//                                                            cameraOrientation.y*power,
//                                                            cameraOrientation.z*power),
//                                                 asImpulse: true)
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
    
//    @IBAction func testTap(_ sender: Any) {
//        let storyboard = UIStoryboard.init(name: "AR", bundle: nil)
//        let vc = storyboard.instantiateInitialViewController()
//        vc?.modalTransitionStyle = .coverVertical
//        present(vc!, animated: true, completion: nil)
//    }
    
    // MARK: Actions
    
    @IBAction func menuButtonPressed(_ sender: UIButton) {
        self.menuWidthConstraint.constant = self.menuWidthConstraint.constant == 200 ? 20 : 200
        UIView.animate(withDuration: 1.5, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 3, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.hostButton.isHidden = false
            self.resolveButton.isHidden = false
        }, completion: nil)
    }
    
    // MARK: Helper Methods
    
    func setupButtons() {
        hostButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        hostButton.setTitle("HOST", for: .normal)
        hostButton.addTarget(self, action: #selector(hostButtonPressed(_:)), for: .touchUpInside)
        menuBarView.addSubview(hostButton)
        hostButton.translatesAutoresizingMaskIntoConstraints = false
        
        resolveButton = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        resolveButton.setTitle("RESOLVE", for: .normal)
        resolveButton.addTarget(self, action: #selector(resolveButtonPressed(_:)), for: .touchUpInside)
        menuBarView.addSubview(resolveButton)
        resolveButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.hostButton.centerYAnchor.constraint(equalTo: self.menuBarView.centerYAnchor, constant: 0).isActive = true
        self.resolveButton.rightAnchor.constraint(equalTo: self.menuBarView.rightAnchor, constant: -35).isActive = true
        self.resolveButton.centerYAnchor.constraint(equalTo: self.menuBarView.centerYAnchor, constant: 0).isActive = true
        self.hostButton.rightAnchor.constraint(equalTo: self.resolveButton.leftAnchor, constant: -10).isActive = true
        
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
    
    @objc func buttonAction(sender: UIButton!) {
        shootBall()
    }
    
    func shootBall() {
        let power:Float = 20.0
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31,
                                     -transform.m32,
                                     -transform.m33)
        let location = SCNVector3(transform.m41,
                                  transform.m42,
                                  transform.m43)
        let position = orientation + location
        
        let ball = createBallShoot(_with: position)
        
        nodePhysics.ballBitMaskAndPhysicsBody(_to: ball)
        ball.physicsBody?.applyForce(SCNVector3(orientation.x * power,
                                                orientation.y * power,
                                                orientation.z * power),
                                     asImpulse: true)
        self.sceneView.scene.rootNode.addChildNode(ball)
    }
}

func +(left:SCNVector3, right:SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

