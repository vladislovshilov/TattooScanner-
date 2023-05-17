//
//  Model.swift
//  TattooScaner
//
//  Created by macbook pro max on 15/05/2023.
//

import Foundation

struct APIResponse: Decodable {
    let responses: [Response]
}

struct Response: Decodable {
    let logoAnnotations: [LogoAnnotation]
}

struct LogoAnnotation: Decodable {
    let mid: String
    let description: String
    let score: Double
    let boundingPoly: BoundingPoly
}

struct BoundingPoly: Decodable {
    let vertices: [Vertex]
}

struct Vertex: Decodable {
    let x: Int
    let y: Int
}
