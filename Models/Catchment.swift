//
//  Catchment.swift
//  TempAqua
//

import Foundation
import SwiftUI
import CoreLocation

struct Catchment: Hashable, Codable {
    var id: String
    var name: String
    var locations: [CatchmentLocation]
    
    init(id: String, name: String, locations: [CatchmentLocation]) {
        self.id = id
        self.name = name
        self.locations = locations
    }
}

struct CatchmentLocation: Hashable, Codable {
    var id: String
    var longitude: Int
    var latitude: Int
    var equipment: String
    
    func wgs() -> CLLocationCoordinate2D {
        return locationFromCH1903(longitude: Double(self.longitude), latitude: Double(self.latitude))
    }
}

struct NearCatchmentLocation: Hashable, Codable, Comparable {
    static func < (lhs: NearCatchmentLocation, rhs: NearCatchmentLocation) -> Bool {
        lhs.distance < rhs.distance
    }
    
    var id: String
    var distance: Int
}
