//
//  ImageViewController.swift
//  TattooScaner
//
//  Created by macbook pro max on 15/05/2023.
//

import UIKit
import Alamofire

class ImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    var imageData: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let imageData = imageData {
            imageView.image = imageData
        }
    }
}
