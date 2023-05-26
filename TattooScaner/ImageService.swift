//
//  ImageService.swift
//  TattooScaner
//
//  Created by macbook pro max on 22/05/2023.
//

import Foundation
import Alamofire

struct ImageService {
    private static let baseURL = "http://192.168.100.33:3000"
    
    static func sendImageToCloudVision(imageData: Data, completion: @escaping (Result<[DetectedObject], Error>) -> Void) {
        let url = baseURL + "/analyze-image"
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        let parameters: [String: Any] = ["image": imageData.base64EncodedString()]
        
        AF.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers)
        .responseDecodable(of: [DetectedObject].self) { response in
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
    
    static func sendTags(_ tags: [String], completion: @escaping (Result<TattooDefinition, Error>) -> Void) {
        let url = baseURL + "/result"
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        let parameters: [String: Any] = ["names": tags]
        
        AF.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers)
        .responseDecodable(of: TattooDefinition.self) { response in
            switch response.result {
            case .success(let data):
                print("new description:")
                print(data)
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
