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
    @IBOutlet weak var roomCodePanel: UIVisualEffectView!
    @IBOutlet weak var messagePanel: UIVisualEffectView!
    
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
    var shootButton: UIButton!
    var nodePhysics: NodePhysics!
    var ballNode: SCNNode!
//    var scoreManager: ScoreManager!
    var tableNode: SCNNode!
    var inGame = false;
    
    // GAME STATE VARIABLES
    var myPlayerNumber: Int! {
        didSet { toggleShootButton() }
    }
    var playerTurn: Int = 2 {
        didSet { toggleShootButton() }
    }
    var isBallInPlay = false {
        didSet { toggleShootButton() }
    }
    var dismissBallTimer = Timer()
    
    // SLIDER VARIABLES
    var slider: CustomSlider!
    var sliderTimer = Timer()
    var power:Float = 0.5
    var sliderGoingUp = true
    var sliderGoingDown = false
    
    // POPOVER VARIABLES
    var popover: Popover!
    var popoverText = ["HOST", "JOIN"]
    let popoverMenu: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let image = #imageLiteral(resourceName: "popoverMenu")
        button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = .white
        button.addTarget(self, action: #selector(tappedPopoverMenu), for: .touchUpInside)
        return button
    }()
    
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
//        scoreManager = ScoreManager(scene: self.sceneView.scene)
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
        
        self.setupSlider()
        self.setupShootButton()
        self.sceneView.debugOptions = SCNDebugOptions.showPhysicsShapes
        view.addSubview(popoverMenu)
        setupConstraint()
        
        // Set RoomCodePanel to hidden by default
        roomCodePanel.isHidden = true
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
    
    // MARK: Helper Methods
    func setupShootButton() {
        self.shootButton = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        self.shootButton.setImage(#imageLiteral(resourceName: "oval-grey"), for: .normal)
        self.shootButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(self.shootButton)
        self.shootButton.isUserInteractionEnabled = false
        self.shootButton.translatesAutoresizingMaskIntoConstraints = false
        self.shootButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.shootButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30).isActive = true
        self.shootButton.isHidden = true
    }
    
    func toggleButton(state: ARState){
        if state == .Default || state == .CreatingRoom {
        popoverText[0] = "HOST"
        popoverText[1] = "JOIN"
        }else if state == .RoomCreated{
            popoverText[0] = "CANCEL"
            popoverText[1] = "JOIN"
        }else if state == .Resolving{
            popoverText[0] = "HOST"
            popoverText[1] = "CANCEL"
        }
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
        ballNode = createBall(transform: tableSpaceTransform)
        ballNode.position = SCNVector3(tableSpaceTransform.m41 - tableSpaceTransform.m31,
                                       tableSpaceTransform.m42 - tableSpaceTransform.m32,
                                       tableSpaceTransform.m43 - tableSpaceTransform.m33)
        nodePhysics.ballBitMaskAndPhysicsBody(_to: ballNode)
        
        // Alternately maybe try using the tableSpace transform to set the orientation
        ballNode.physicsBody?.applyForce(SCNVector3(orientation.x * power,
                                                    -orientation.y * power,
                                                    orientation.z * power),
                                         asImpulse: true)
        isBallInPlay = true
        self.updateBallInPlay(bool: true)
        startBallTimer()
        self.tableNode.addChildNode(ballNode)
//        scoreManager.numberOfThrows += 1
//        scoreManager.updateScoreLabel()
    }
}

func +(left:SCNVector3, right:SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func -(l: SCNVector3, r: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(l.x - r.x, l.y - r.y, l.z - r.z)
}


