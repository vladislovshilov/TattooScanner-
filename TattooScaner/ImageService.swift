//
//  ImageService.swift
//  TattooScaner
//
//  Created by macbook pro max on 22/05/2023.
//

import Foundation
import Alamofire

struct ImageService {
    static func sendImageToCloudVision(imageData: Data, completion: @escaping (Result<[DetectedObject], Error>) -> Void) {
        let url = "http://192.168.100.33:3000/analyze-image"
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        let parameters: [String: Any] = [
            "imageBase64": imageData.base64EncodedString()
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseDecodable(of: [DetectedObject].self) { response in
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
}
