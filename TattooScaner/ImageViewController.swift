//
//  ImageViewController.swift
//  TattooScaner
//
//  Created by macbook pro max on 15/05/2023.
//

import UIKit
import Alamofire

class ImageViewController: UIViewController {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var hudView: UIView!
    @IBOutlet private weak var hudTitle: UILabel!
    
    var imageData: UIImage?
    
    private var shapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hudView.layer.cornerRadius = 10
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        imageView.image = imageData
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let jpegImage = imageData?.jpegData(compressionQuality: 0.8) else {
            // Handle error when the image data cannot be created
            return
        }
        ImageService.sendImageToCloudVision(imageData: jpegImage) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                
                switch result {
                case .success(let data):
//                    if let logoAnnotation = data.responses.first?.logoAnnotations.first {
//                        self.hudTitle.text = "Logo: \(logoAnnotation.description), Score: \(logoAnnotation.score)"
//                        self.drawBoundingBox(on: self.imageView, with: logoAnnotation.boundingPoly)
//                    } else {
//                        // Handle the case when no logo annotations are found
//                        self.hudTitle.text = "Nothing was found. Scan again"
//                    }
                    if let first = data.first?.name {
                        self.hudTitle.text = first
                    }
                    else {
                        self.hudTitle.text = "Nothing was found. Scan again"
                    }
                case .failure(let error):
                    print(error)
                    self.hudTitle.text = "Nothing was found. Scan again. \(error)"
                }
                
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction private func rescanButtonDidPress(_ sender: Any) {
        dismiss(animated: true)
    }
}

// MARK: - Helpers
extension ImageViewController {
    private func drawBoundingBox(on imageView: UIImageView, with boundingPoly: BoundingPoly) {
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
