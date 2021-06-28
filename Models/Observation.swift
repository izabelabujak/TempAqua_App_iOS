//
//  Observation.swift
//  TempAqua
//

import SwiftUI
import CoreLocation

struct Observation: Hashable, Codable, Identifiable {
    var id: Int
    var observedAt: Date
    var category: ObservationCategory
    var comment: String?
    var latitude: Int
    var longitude: Int
    var accuracy: Int
    var gpsDevice: String
    var direction: Int?
    var elevation: Int?
    var anchorPoint: String?
    var waterLevel: Int?
    var discharge: Int?
    var marker: ObservationMarker = .red
    var multimedia: [ObservationMultimedia]
    var parent: Int?
    
    init() {
        self.id = 0
        self.observedAt = Date()
        self.category = ObservationCategory.flowing
        self.comment = ""
        self.latitude = 0
        self.longitude = 0
        self.accuracy = 0
        self.gpsDevice = ""
        self.direction = nil
        self.elevation = nil
        self.waterLevel = nil
        self.discharge = nil
        self.anchorPoint = nil
        self.marker = ObservationMarker.red
        self.multimedia = []
        self.parent = nil
    }

    func location() -> CLLocationCoordinate2D {
        return locationFromCH1903(longitude: Double(self.longitude), latitude: Double(self.latitude))
    }
}
