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
    
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var regionalView: UIView!

    internal let motion = MotionObservable()

    @IBOutlet weak var resolution: UILabel!
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
        
//        camera = BBMetalCamera(sessionPreset: .hd1920x1080)
        var resolution = AVCaptureSession.Preset.cif352x288
        self.resolution.text = "cif352x288"

        switch UIDevice.modelName {
        case "iPhone 5s":
            resolution = .hd1280x720
            self.resolution.text = "hd1280x720"
            break
        case "iPhone SE":
            resolution = .hd1280x720
            self.resolution.text = "hd1280x720"
            break
        case "iPhone 6":
            resolution = .hd1920x1080
            self.resolution.text = "hd1920x1080"
            break;
        case "iPhone 6 Plus":
            resolution = .hd1920x1080
            self.resolution.text = "hd1920x1080"
            break;
        case "iPhone 6s":
            resolution = .hd1920x1080
            self.resolution.text = "hd1920x1080"
            break;
        case "iPhone 6s Plus":
            resolution = .hd1920x1080
            self.resolution.text = "hd1920x1080"
            break;
        case "iPhone 7":
            resolution = .hd1920x1080
            self.resolution.text = "hd1920x1080"
            break;
        case "iPhone 7 Plus":
            resolution = .hd1920x1080
            self.resolution.text = "hd1920x1080"
            break;
        case "iPhone 8":
            resolution = .hd1920x1080
            self.resolution.text = "hd1920x1080"
            break;
        case "iPhone 8 Plus":
            resolution = .hd1920x1080
            self.resolution.text = "hd1920x1080"
            break;
        case "iPhone X":
            resolution = .hd4K3840x2160
            self.resolution.text = "hd4K3840x2160"
            break
        case "iPhone XR":
            resolution = .hd4K3840x2160
            self.resolution.text = "hd4K3840x2160"
            break
        case "iPhone XS":
            resolution = .hd4K3840x2160
            self.resolution.text = "hd4K3840x2160"
            break
        case "iPhone XS Max":
            resolution = .hd4K3840x2160
            self.resolution.text = "hd4K3840x2160"
            break
        default:
            break
        }
        camera = BBMetalCamera(sessionPreset: resolution)
        camera.canTakePhoto = true
        camera.photoDelegate = self
        camera.add(consumer: BBMetalLookupFilter(lookupTable: UIImage(named: "test_lookup")!.bb_metalTexture!))
            .add(consumer: metalView)
        
//        camera.add(consumer: BBMetalLookupFilter(lookupTable: UIImage(named: "test_lookup")!.bb_metalTexture!))
        camera.add(consumer: metalPartView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        camera.start()
        
        observerConfig()
    }
    
    func toggleTorch() -> Void {
        let avDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        if  avDevice!.hasTorch {
            do{
                try avDevice!.lockForConfiguration()
                avDevice!.torchMode = (AVCaptureDevice.TorchMode.off == avDevice?.torchMode)
                    ? AVCaptureDevice.TorchMode.on : AVCaptureDevice.TorchMode.off
                avDevice!.unlockForConfiguration()
            }
            catch{
            
            }
        }
    }
    
    func observerConfig() -> Void {
        motion.addGyroObserver(observer: {(x: Double, y: Double, z: Double) -> Void in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.gyroX.text = "\(x)"
                self.gyroY.text = "\(y)"
                self.gyroZ.text = "\(z)"
            }
        })
        motion.addAccelerometerObserver(observer: {(x: Double, y: Double, z: Double) -> Void in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.acceX.text = "\(x)"
                self.acceY.text = "\(y)"
                self.acceZ.text = "\(z)"
            }
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
    
    @IBAction func showDetailPressed(_ sender: Any) {
        self.detailsView.isHidden = !(sender as! UISwitch).isOn
        
        if(self.detailsView.isHidden){
            motion.clearObservers()
        }else{
            observerConfig()
        }
        toggleTorch()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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
