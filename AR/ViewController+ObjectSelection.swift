/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Methods on the main view controller for handling virtual object loading and movement
*/

import UIKit
import ARKit

extension ViewController: VirtualObjectSelectionViewControllerDelegate {
    /**
     Adds the specified virtual object to the scene, placed using
     the focus square's estimate of the world-space position
     currently corresponding to the center of the screen.
     
     - Tag: PlaceVirtualObject
     */
    func placeVirtualObject(_ virtualObject: VirtualObject) {
        guard let cameraTransform = session.currentFrame?.camera.transform,
			let focusSquareAlignment = focusSquare.recentFocusSquareAlignments.last,
			focusSquare.state != .initializing else {
            	statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
				if let controller = objectsViewController {
					virtualObjectSelectionViewController(controller, didDeselectObject: virtualObject)
				}
            return
        }
		
		// The focus square transform may contain a scale component, so reset scale to 1
		let focusSquareScaleInverse = 1.0 / focusSquare.simdScale.x
        let scaleMatrix = float4x4(uniformScale: focusSquareScaleInverse)
		let focusSquareTransformWithoutScale = focusSquare.simdWorldTransform * scaleMatrix
		
        virtualObjectInteraction.selectedObject = virtualObject
		virtualObject.setTransform(focusSquareTransformWithoutScale,
								   relativeTo: cameraTransform,
								   smoothMovement: false,
								   alignment: focusSquareAlignment,
								   allowAnimation: false)
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
			self.sceneView.addOrUpdateAnchor(for: virtualObject)
        }
    }
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObject object: VirtualObject) {
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            DispatchQueue.main.async {
                self.hideObjectLoadingUI()
                self.placeVirtualObject(loadedObject)
            }
        })

        displayObjectLoadingUI()
    }
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didDeselectObject object: VirtualObject) {
        guard let objectIndex = virtualObjectLoader.loadedObjects.index(of: object) else {
            fatalError("Programmer error: Failed to lookup virtual object in scene.")
        }
        virtualObjectLoader.removeVirtualObject(at: objectIndex)
		virtualObjectInteraction.selectedObject = nil
		if let anchor = object.anchor {
			session.remove(anchor: anchor)
		}
    }

    // MARK: Object Loading UI

    func displayObjectLoadingUI() {
        // Show progress indicator.
        spinner.startAnimating()
        
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])

        addObjectButton.isEnabled = false
        isRestartAvailable = false
    }

    func hideObjectLoadingUI() {
        // Hide progress indicator.
        spinner.stopAnimating()

        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])

        addObjectButton.isEnabled = true
        isRestartAvailable = true
    }
}
