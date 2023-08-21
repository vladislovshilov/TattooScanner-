//
//  Analysis.swift
//  TattooScaner
//
//  Created by macbook pro max on 21/08/2023.
//

import UIKit

struct Analysis {
    var image: UIImage?
    var detectedObject: String
    var meaning: String
    var scanDate: Date
    
    static var mocks: [Analysis] {
        let snake = Analysis(image: nil, detectedObject: "Snake", meaning: "в основном змея значит, что ты пидр", scanDate: Date(timeIntervalSince1970: 1692630282))
        let robot = Analysis(image: nil, detectedObject: "Robot", meaning: "в основном робот значит, что ты пидр", scanDate: Date(timeIntervalSince1970: 1692620282))
        let fly = Analysis(image: nil, detectedObject: "Fly", meaning: "в основном муха значит, что ты пидр", scanDate: Date(timeIntervalSince1970: 1692610282))
        let car = Analysis(image: nil, detectedObject: "Snake", meaning: "в основном машина значит, что ты пидр", scanDate: Date(timeIntervalSince1970: 1692600282))
        
        return [snake, robot, fly, car]
    }
}
