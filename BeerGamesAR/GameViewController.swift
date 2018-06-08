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
    var shootButton: UIButton!
    var nodePhysics: NodePhysics!
    var ballNode: SCNNode!
    var scoreManager: ScoreManager!
    var tableNode: SCNNode!
    
    // Game State
    var ballPosition: SCNVector3!
    var myPlayerNumber: Int!
    var playerTurn: Int = 2
    var isBallInPlay = false
    var dismissBallTimer = Timer()
    
    // SLIDER VARIABLES
    var slider: CustomSlider!
    var sliderTimer = Timer()
    var power:Float = 0.5
    var sliderGoingUp = true
    var sliderGoingDown = false
    
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
        scoreManager = ScoreManager(scene: self.sceneView.scene)
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
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
        self.setupSlider()
        
        self.shootButton.isHidden = true
        self.slider.isHidden = true

//        self.sceneView.debugOptions = SCNDebugOptions.showPhysicsShapes
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
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
        
        self.shootButton = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        self.shootButton.backgroundColor = UIColor.gray
        self.shootButton.setTitle("Shoot Ball", for: UIControlState.normal)
        self.shootButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(self.shootButton)
        self.shootButton.isUserInteractionEnabled = false
        
        self.shootButton.translatesAutoresizingMaskIntoConstraints = false
        self.shootButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.shootButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -150).isActive = true
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
        DispatchQueue.global(qos: .background).async {
            if self.ballNode != nil {
                self.ballNode.removeFromParentNode()
            }
            self.shootBall()
        }
    }
    
    func shootBall() {
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let tableSpaceTransform = sceneView.scene.rootNode.convertTransform(transform, to: self.tableNode)
        let orientation = SCNVector3(-transform.m31,
                                     -transform.m32,
                                     -transform.m33)
//        let location = SCNVector3(transform.m41,
//                                  transform.m42,
//                                  transform.m43)
        //let position = orientation + location
//        ballNode = createBall(position: position)
        ballNode = createBall(transform: tableSpaceTransform)
        nodePhysics.ballBitMaskAndPhysicsBody(_to: ballNode)
        
        // NOTE: Try using [0, 0, -1] instead of the orientation
        // Alternately maybe try using the tableSpace transform to set the orientation
        ballNode.physicsBody?.applyForce(SCNVector3(orientation.x * power,
                                                    -orientation.y * power,
                                                    orientation.z * power),
                                     asImpulse: true)
        
        isBallInPlay = true
        self.updateBallInPlay(bool: true)
        
        self.tableNode.addChildNode(ballNode)
        
        scoreManager.numberOfThrows += 1
        scoreManager.updateScoreLabel()
        
        startBallTimer()
        disableShootButton()
    }
}

func +(left:SCNVector3, right:SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func -(l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
}


