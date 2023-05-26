//
//  NetworkManager.swift
//  TattooScaner
//
//  Created by macbook pro max on 24/05/2023.
//

import Foundation
import Alamofire

private let API_BASE_URL = "http://169.254.105.159:3000"

actor NetworkManager: GlobalActor {
    static let shared = NetworkManager()
    private init() {}

    private let maxWaitTime = 15.0
    var commonHeaders: HTTPHeaders = []

    func get(path: String, parameters: Parameters?) async throws -> Data {
       // You must resume the continuation exactly once
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                API_BASE_URL + path,
                parameters: parameters,
                headers: commonHeaders,
                requestModifier: { $0.timeoutInterval = self.maxWaitTime }
            )
            .responseData { response in
                switch(response.result) {
                case let .success(data):
                    continuation.resume(returning: data)
                case let .failure(error):
                    continuation.resume(throwing: self.handleError(error: error))
                }
            }
        }
    }
    
    func post<T: Decodable>(path: String, parameters: Parameters?) async throws -> T {
        return try await withCheckedThrowingContinuation({ continuation in
            AF.request(
                API_BASE_URL + path,
                method: .post,
                parameters: parameters,
                headers: commonHeaders,
                requestModifier: { $0.timeoutInterval = self.maxWaitTime }
            )
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let data):
                    print("async SCAN:")
                    print(data)
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: self.handleError(error: error))
                }
            }
        })
    }

    private func handleError(error: AFError) -> Error {
        if let underlyingError = error.underlyingError {
            let nserror = underlyingError as NSError
            let code = nserror.code
            if code == NSURLErrorNotConnectedToInternet ||
                code == NSURLErrorTimedOut ||
                code == NSURLErrorInternationalRoamingOff ||
                code == NSURLErrorDataNotAllowed ||
                code == NSURLErrorCannotFindHost ||
                code == NSURLErrorCannotConnectToHost ||
                code == NSURLErrorNetworkConnectionLost
            {
                var userInfo = nserror.userInfo
                userInfo[NSLocalizedDescriptionKey] = "Unable to connect to the server"
                let currentError = NSError(
                    domain: nserror.domain,
                    code: code,
                    userInfo: userInfo
                )
                return currentError
            }
        }
        return error
    }
}
