//
//  Model.swift
//  TattooScaner
//
//  Created by macbook pro max on 15/05/2023.
//

import Foundation

struct DetectedObject: Decodable {
    var id: String
    var name: String
    var value: Double
    var app_id: String
}

struct BoundingPoly: Decodable {
    let vertices: [Vertex]
}

struct Vertex: Decodable {
    let x: Int
    let y: Int
}
