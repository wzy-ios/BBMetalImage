//
//  VisionCameraFilterVC.swift
//  BBMetalImageDemo
//
//  Created by Zuying Wo on 6/5/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import AVFoundation
import BBMetalImage
import CropView

//define IS_DEBUG

class VisionCameraFilterVC: UIViewController {
    private var camera: BBMetalCamera!
    private var metalView: BBMetalView!
    private var metalPartView: BBMetalView!
    private var autoDetect : Bool!
    
    @IBOutlet weak var testView: UIImageView!
    
    @IBOutlet weak var autoDetectSw: UISwitch!
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var regionalView: UIView!
    @IBOutlet weak var floatingView: UIImageView!
    
    internal let captureInterval = 0.1
    internal let motion = MotionObservable()

    @IBOutlet weak var resolution: UILabel!
    @IBOutlet weak var gyroX: UILabel!
    @IBOutlet weak var gyroY: UILabel!
    @IBOutlet weak var gyroZ: UILabel!
    
    @IBOutlet weak var acceX: UILabel!
    @IBOutlet weak var acceY: UILabel!
    @IBOutlet weak var acceZ: UILabel!
    
    @IBOutlet weak var lockImageView: UIImageView!
    let cropView = SECropView()

    private var dragging : Bool!
    private var locked : Bool!
    private var cameraViewHeight : float_t!
    private var areaViewHeight : float_t!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let point = touch.location(in: self.view)

        if (locked){
            return
        }
        
        if (!self.floatingView.frame.contains(point)) {
            self.dragging = true
            
            self.floatingView.layer.shadowOffset = CGSize(width: 5, height: 5);
            self.floatingView.layer.shadowOpacity = 0.8; // 影の透明度
        }else{
            self.dragging = false
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let point = touch.location(in: self.view)
        
        if (!self.dragging) {
            return
        }
        
        if (point.y < regionalView.frame.origin.y){
            self.floatingView.frame = CGRect(
                origin: CGPoint(x:0, y:point.y),
                size: self.floatingView.frame.size
            )
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.floatingView.layer.shadowOffset = CGSize(width: 0, height: 0);
        self.floatingView.layer.shadowOpacity = 1.0; // 影の透明度
        
        if self.dragging {
            camera.remove(consumer: camera.consumers.last!)
            if let filter = self.filter {
                camera.add(consumer: filter)
                    .add(consumer: metalPartView)
            }
            self.dragging = false;
        }
    }
    
    func config() -> Void {
        self.locked = false
        self.dragging = false
        
        floatingView.image = UIImage.colorImage(color: UIColor.clear, size: floatingView.bounds.size)
        cropView.configureWithCorners(
            corners: [CGPoint(x: 5, y:50),
                      CGPoint(x: 270, y: 5),
                      CGPoint(x: 280, y: 60),
                      CGPoint(x: 5, y: 60)],
            on: floatingView)

        metalView = BBMetalView(frame: cameraView.bounds,
                                device: BBMetalDevice.sharedDevice)
        cameraView.addSubview(metalView)
        cameraView.sendSubviewToBack(metalView)
        cameraViewHeight = Float(cameraView.frame.height)
        
        metalPartView = BBMetalView(frame: regionalView.bounds,
                                device: BBMetalDevice.sharedDevice)
        regionalView.addSubview(metalPartView)
        regionalView.sendSubviewToBack(metalPartView)
        areaViewHeight = Float(regionalView.frame.height)
        
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
        camera.willTransmitTexture = transmitTexture
        
        camera.add(consumer: BBMetalLookupFilter(lookupTable: UIImage(named: "test_lookup")!.bb_metalTexture!))
            .add(consumer: metalView)

        if let filter = self.filter {
            camera.add(consumer: filter)
                .add(consumer: metalPartView)
        }
        autoDetect = false
    }
    
    private var filter : BBMetalBaseFilter? {
        
        return BBMetalCropFilter(rect: BBMetalRect(
            x: 0.0,
            y: Float(floatingView.frame.origin.y) / cameraViewHeight,
            width: 1.0,
            height: Float(regionalView.frame.height) / cameraViewHeight
            )
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        config()
        
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
    func transmitTexture(_ texture:MTLTexture) -> Void {
        if !self.autoDetect{
            return
        }
        // Do your work
        
        return
    }
    
    @objc private func clickPhotoButton(_ button: UIButton) {
        camera.takePhoto()
    }

    @IBAction func autoDetectPressed(_ sender: Any) {
        autoDetect = self.autoDetectSw.isOn
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
    
    @IBAction func lockPressed(_ sender: Any) {
        self.locked = !self.locked
        if self.locked {
            print("Crop area : \(cropView.cornerLocations as Any)")
            lockImageView.image =  UIImage(named: "Lock")
        }else{
            lockImageView.image =  UIImage(named: "Unlock")
        }
        cropView.isUserInteractionEnabled = !locked
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
extension Date {
    func toMillis() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}
extension VisionCameraFilterVC: BBMetalCameraPhotoDelegate {
    func showTime() -> Void{
        
        print(Date().toMillis() as Any)
        
    }
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

//        DispatchQueue.main.asyncAfter(deadline: .now() + captureInterval) {
//            if self.autoDetectSw.isOn{
//                camera.takePhoto()
//            }
//        }
        return
    }
    
    func camera(_ camera: BBMetalCamera, didFail error: Error) {
        // In main thread
        print("Fail taking photo. Error: \(error)")
    }
}
