//
//  ViewController.swift
//  TattooScaner
//
//  Created by macbook pro max on 15/05/2023.
//

import UIKit
import AVFoundation
import Alamofire

protocol HomeViewControllerRepresentable {
    var subscriptionButtonTapCallback: (() -> Void)? { get set }
    var settingsButtonTapCallback: (() -> Void)? { get set }
    var newAnalysisButtonTapCallback: (() -> Void)? { get set }
    var scanTapCallback: (() -> Void)? { get set }
}

class ViewController: UIViewController, HomeViewControllerRepresentable {
    @IBOutlet private weak var scanButton: UIButton!
    
    var subscriptionButtonTapCallback: (() -> Void)?
    var settingsButtonTapCallback: (() -> Void)?
    var newAnalysisButtonTapCallback: (() -> Void)?
    var scanTapCallback: (() -> Void)?
    
    private let session = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: session)
    
    private let photoOutput = AVCapturePhotoOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("home loaded")

        guard let device = AVCaptureDevice.default(for: .video) else {
            print("Camera not available.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error setting camera input: \(error.localizedDescription)")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        if !session.isRunning {
            DispatchQueue.global().async { [weak self] in
                self?.session.startRunning()
            }
        }
        
        print("home will wappera")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if session.isRunning {
            session.stopRunning()
        }
        
        previewLayer.removeFromSuperlayer()
    }
    
    @IBAction func scanButtonDidPress(_ sender: Any) {
//        let photoSettings = AVCapturePhotoSettings()
//        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        newAnalysisButtonTapCallback?()
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process the captured video frame here
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        // Access the captured photo data
        guard let imageData = photo.fileDataRepresentation() else {
            print("Unable to retrieve photo data.")
            return
        }
        let capturedImage = UIImage(data: imageData)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController else {
            print("can't create ImageViewController")
            return
        }
        
        viewController.imageData = capturedImage
        viewController.modalPresentationStyle = .currentContext
        present(viewController, animated: true)
    }
}

