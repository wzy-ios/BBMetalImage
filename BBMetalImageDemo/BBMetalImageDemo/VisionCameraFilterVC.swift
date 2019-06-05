//
//  VisionCameraFilterVC.swift
//  BBMetalImageDemo
//
//  Created by Zuying Wo on 6/5/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit
import AVFoundation
import BBMetalImage

//define IS_DEBUG

class VisionCameraFilterVC: UIViewController {
    private var camera: BBMetalCamera!
    private var metalView: BBMetalView!
    private var metalPartView: BBMetalView!
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var regionalView: UIView!

    internal let motion = MotionObservable()

    @IBOutlet weak var gyroX: UILabel!
    @IBOutlet weak var gyroY: UILabel!
    @IBOutlet weak var gyroZ: UILabel!
    
    @IBOutlet weak var acceX: UILabel!
    @IBOutlet weak var acceY: UILabel!
    @IBOutlet weak var acceZ: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .gray
        
//        let x: CGFloat = 10
//        let width: CGFloat = view.bounds.width - 20
        metalView = BBMetalView(frame: cameraView.bounds,
                                device: BBMetalDevice.sharedDevice)
        cameraView.addSubview(metalView)
        
        metalPartView = BBMetalView(frame: regionalView.bounds,
                                device: BBMetalDevice.sharedDevice)
        regionalView.addSubview(metalPartView)
        
//        let photoButton = UIButton(frame: CGRect(x: x, y: metalView.frame.maxY + 10, width: width, height: 30))
//        photoButton.backgroundColor = .blue
//        photoButton.setTitle("Take photo", for: .normal)
//        photoButton.addTarget(self, action: #selector(clickPhotoButton(_:)), for: .touchUpInside)
//        view.addSubview(photoButton)
        
        camera = BBMetalCamera(sessionPreset: .hd1920x1080)
        camera.canTakePhoto = true
        camera.photoDelegate = self
        camera.add(consumer: BBMetalLookupFilter(lookupTable: UIImage(named: "test_lookup")!.bb_metalTexture!))
            .add(consumer: metalView)
        
        camera.add(consumer: BBMetalLookupFilter(lookupTable: UIImage(named: "test_lookup")!.bb_metalTexture!))
            .add(consumer: metalPartView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        camera.start()
        
        motion.addGyroObserver(observer: {(x: Double, y: Double, z: Double) -> Void in
//            let summary = Int(abs(x) + abs(y) + abs(z))
//            print("Gyro: \(summary)")
            self.gyroX.text = "\(x)"
            self.gyroY.text = "\(y)"
            self.gyroZ.text = "\(z)"
        })
        motion.addAccelerometerObserver(observer: {(x: Double, y: Double, z: Double) -> Void in
//            let summary = Int(abs(x) + abs(y) + abs(z))
            self.acceX.text = "\(x)"
            self.acceY.text = "\(y)"
            self.acceZ.text = "\(z)"
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        camera.stop()
        
        motion.clearObservers()
    }
    
    @objc private func clickPhotoButton(_ button: UIButton) {
        camera.takePhoto()
    }
    
}
extension VisionCameraFilterVC: BBMetalCameraPhotoDelegate {
    func camera(_ camera: BBMetalCamera, didOutput texture: MTLTexture) {
//        // In main thread
//        let filter = BBMetalLookupFilter(lookupTable: UIImage(named: "test_lookup")!.bb_metalTexture!)
//        let imageView = UIImageView(frame: metalView.frame)
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.image = filter.filteredImage(with: texture.bb_image!)
//        view.addSubview(imageView)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            imageView.removeFromSuperview()
//        }
        return
    }
    
    func camera(_ camera: BBMetalCamera, didFail error: Error) {
        // In main thread
        print("Fail taking photo. Error: \(error)")
    }
}
