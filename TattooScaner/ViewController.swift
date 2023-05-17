//
//  ViewController.swift
//  TattooScaner
//
//  Created by macbook pro max on 15/05/2023.
//

import UIKit
import AVFoundation
import Alamofire

enum State {
    case scanning, captured
    
    var buttonTitle: String {
        switch self {
        case .scanning: return "Scan"
        case .captured: return  "Re-Scan"
        }
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    private let session = AVCaptureSession()
    lazy var previewLayer = AVCaptureVideoPreviewLayer(session: session)
    
    let photoOutput = AVCapturePhotoOutput()
    
    var state = State.scanning
    
    var shapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraView.isHidden = true
        imageView.isHidden = true
        
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
        
        DispatchQueue.global().async { [weak self] in
            self?.session.startRunning()
        }
        
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if session.isRunning {
            session.stopRunning()
        }
        
        previewLayer.removeFromSuperlayer()
    }
    
    @IBAction func scanButtonDidPress(_ sender: Any) {
        if state == .scanning {
            state = .captured
            shapeLayer.removeFromSuperlayer()
            activityIndicator.isHidden = false
            textLabel.text = "Scanning"
            activityIndicator.startAnimating()
        }
        else if state == .captured {
            state = .scanning
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
        }
        
        let photoSettings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        
        scanButton.setTitle(state.buttonTitle, for: .normal)
        imageView.isHidden = state == .scanning
        cameraView.isHidden = state == .scanning
    }
    
    func sendImageToCloudVision(imageData: Data, completion: @escaping (Result<APIResponse, Error>) -> Void) {
        let url = "https://vision.googleapis.com/v1/images:annotate?key=AIzaSyCVcQvjF4ZpSB2Q9s3AXlYktLC-HJYmJX0"
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        let parameters: [String: Any] = [
            "requests": [
                "image": [
                    "content": imageData.base64EncodedString()
                ],
                "features": [
                    [
                        "type": "LOGO_DETECTION"
                    ]
                ]
            ] as [String : Any]
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseDecodable(of: APIResponse.self) { response in
            switch response.result {
            case .success(let data):
                print("new SCAN:")
                print(data)
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func drawBoundingBox(on imageView: UIImageView, with boundingPoly: BoundingPoly) {
        imageView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Calculate the coordinates of the bounding box based on the image view's dimensions
        let imageViewWidth = imageView.bounds.width
        let imageViewHeight = imageView.bounds.height
        
        let vertices = boundingPoly.vertices
        
        // Create a UIBezierPath for the bounding box
        let boundingBoxPath = UIBezierPath()
        
        for (index, vertex) in vertices.enumerated() {
            let x = CGFloat(vertex.x) * imageViewWidth / 1000.0
            let y = CGFloat(vertex.y) * imageViewHeight / 1000.0
            
            if index == 0 {
                boundingBoxPath.move(to: CGPoint(x: x, y: y))
            } else {
                boundingBoxPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        boundingBoxPath.close()
        
        // Create a CAShapeLayer to draw the bounding box
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.path = boundingBoxPath.cgPath
        
        // Add the shape layer as a sublayer to the image view's layer
        imageView.layer.addSublayer(shapeLayer)
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
        
        // Process the captured image data here
        let capturedImage = UIImage(data: imageData)
        // Use the captured image as needed
        imageView.image = capturedImage
        
        guard let imageData = capturedImage?.jpegData(compressionQuality: 0.8) else {
            // Handle error when the image data cannot be created
            return
        }
        sendImageToCloudVision(imageData: imageData) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
//                    self.textLabel.text = data.responses[0].logoAnnotations[0].description
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    if let logoAnnotation = data.responses.first?.logoAnnotations.first {
                        // Update the label with the logo description and score
                        self.textLabel.text = "Logo: \(logoAnnotation.description), Score: \(logoAnnotation.score)"
                        self.drawBoundingBox(on: self.imageView, with: logoAnnotation.boundingPoly)
                    } else {
                        // Handle the case when no logo annotations are found
                        self.textLabel.text = "No logos found"
                    }
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
}

