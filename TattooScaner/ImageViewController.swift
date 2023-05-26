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
    
    @IBOutlet private weak var pickResultContainerView: UIView!
    @IBOutlet private weak var pickResultTableView: UITableView!
    @IBOutlet private weak var pickResultsHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var gptActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var submitButton: UIButton!
    
    var imageData: UIImage?
    
    private var shapeLayer = CAShapeLayer()
    
    private var detectedObjects: [DetectedObject]? = [DetectedObject]()
    private var pickedObjects = Set<String>() {
        didSet {
            submitButton.isEnabled = !pickedObjects.isEmpty
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.isEnabled = false
        gptActivityIndicator.startAnimating()
        
        pickResultTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        pickResultTableView.delegate = self
        pickResultTableView.dataSource = self
        pickResultTableView.layer.cornerRadius = 10
        pickResultContainerView.layer.cornerRadius = 10

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
                self.gptActivityIndicator.stopAnimating()
                
                switch result {
                case .success(let data): 
                    if data.filter{ $0.name == "tattoo" }.count > 0 {
                        self.configureResult(withData: data)
                    } else {
                        self.configureEmptyResult()
                    }
                case .failure(let error):
                    print(error)
                    self.configureEmptyResult()
                }
                
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func configureResult(withData data: [DetectedObject]) {
        detectedObjects = data
        UIView.animate(withDuration: 0.3) {
            self.pickResultsHeightConstraint.constant = CGFloat(min(data.count * 44, 352))
            self.pickResultContainerView.layoutIfNeeded()
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.submitButton.isEnabled = true
            self.pickResultTableView.reloadData()
        }
    }
    
    private func configureEmptyResult() {
        self.detectedObjects = nil
        
        UIView.animate(withDuration: 0.3) {
            self.pickResultsHeightConstraint.constant = 44
            self.pickResultContainerView.layoutIfNeeded()
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.submitButton.isEnabled = false
            self.pickResultTableView.reloadData()
        }
    }
    
    @IBAction private func rescanButtonDidPress(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func submitButtonDidPress(_ sender: Any) {
        gptActivityIndicator.isHidden = false
        gptActivityIndicator.startAnimating()
        
        print(pickedObjects)
        let array = Array(pickedObjects)
        
        ImageService.sendTags(array) { [weak self] response in
            let okAction = UIAlertAction(title: "Nice", style: .default)
            var alert: UIAlertController
            
            switch response {
            case .success(let definition):
                alert = UIAlertController(title: "Your tattoo means", message: definition.definition, preferredStyle: .alert)
            case .failure(let error):
                alert = UIAlertController(title: "Failure", message: error.localizedDescription, preferredStyle: .alert)
            }
            
            alert.addAction(okAction)
            
            DispatchQueue.main.async {
                self?.present(alert, animated: true)
                self?.gptActivityIndicator.stopAnimating()
            }
        }
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

// MARK: UITableView

extension ImageViewController: UITableViewDataSource {
    private func numberOfRows() -> Int {
        guard let detectedObjects = detectedObjects else {
            return 1
        }
        return detectedObjects.count == 0 ? 1 : detectedObjects.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.backgroundColor = .clear
        cell.accessoryType = .none
        cell.selectedBackgroundView?.backgroundColor = .clear
        
        guard let detectedObjects = detectedObjects else {
            cell.textLabel?.text = "Tattoo was not found. Please try to re-scan."
            return cell
        }
        if detectedObjects.count == 0 {
            cell.textLabel?.text = "Loading..."
        } else {
            let name = detectedObjects[indexPath.row].name
            cell.textLabel?.text = name
            if pickedObjects.contains(name) || name == "tattoo" {
                pickedObjects.insert(name)
                cell.accessoryType = .checkmark
            }
        }
        
        return cell
    }
}

extension ImageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detectedObjects = detectedObjects else { return }
        
        let choosenObjectID = detectedObjects[indexPath.row].name
        if let cell = tableView.cellForRow(at: indexPath) {
            if pickedObjects.contains(choosenObjectID) {
                pickedObjects.remove(choosenObjectID)
                cell.accessoryType = .none
            } else {
                pickedObjects.insert(choosenObjectID)
                cell.accessoryType = .checkmark
            }
        }
    }
}
