//
//  ArcgisStreams.swift
//  TempAqua
//

import Foundation
import CoreLocation

struct ArcgisBorderCRSProjection: Hashable, Codable {
    var name: String
}

struct ArcgisBorderCRS: Hashable, Codable {
    var type: String
    var properties: ArcgisBorderCRSProjection
}

struct ArcgisBorder: Hashable, Codable {
    var type: String
    var crs: ArcgisBorderCRS
    var features: [ArcgisBorderFeature] 
    
    init() {
        self.type = "FeatureCollection"
        self.crs = ArcgisBorderCRS(type: "name", properties: ArcgisBorderCRSProjection(name: "EPSG:21781"))
        self.features = []
    }
    
    func convert_to_ch_system(displayType: String) -> ArcgisGeometry {
        var streams: [ArcgisStream] = []
        for feature in features {
            var stream = ArcgisStream()
            for p1 in feature.geometry.coordinates[0] {
                let y = p1[0]
                let x = p1[1]
                let latitude = CLLocationDegrees(CHtoWGSlat(y: y, x: x))
                let longitude = CLLocationDegrees(CHtoWGSlng(y: y, x: x))
                stream.points.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
            streams.append(stream)
        }
        return ArcgisGeometry(displayType: displayType, features: streams)
    }
}

struct ArcgisBorderFeature: Hashable, Codable {
    var type: String
    var id: Int
    var geometry: ArcgisBorderFeatureGeometry
}

struct ArcgisBorderFeatureGeometry: Hashable, Codable {
    var type: String
    var coordinates: [[[Double]]]
}
