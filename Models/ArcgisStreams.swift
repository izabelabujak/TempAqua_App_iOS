//
//  ArcgisStreams.swift
//  TempAqua
//

import Foundation
import CoreLocation

struct ArcgisStreamsCRSProjection: Hashable, Codable {
    var name: String
}

struct ArcgisStreamsCRS: Hashable, Codable {
    var type: String
    var properties: ArcgisStreamsCRSProjection
}

struct ArcgisStreams: Hashable, Codable {
    var type: String
    var crs: ArcgisStreamsCRS
    var features: [ArcgisStreamsFeature]
    
    init() {
        self.type = "FeatureCollection"
        self.crs = ArcgisStreamsCRS(type: "name", properties: ArcgisStreamsCRSProjection(name: "EPSG:21781"))
        self.features = []
    }
    
    func convert_to_ch_system(displayType: String) -> ArcgisGeometry {
        var streams: [ArcgisStream] = []
        for feature in features {
            var stream = ArcgisStream()
            for p2 in feature.geometry.coordinates {
                if !p2.isEmpty {
                    let y = p2[0]
                    let x = p2[1]
                    let latitude = CLLocationDegrees(CHtoWGSlat(y: y, x: x))
                    let longitude = CLLocationDegrees(CHtoWGSlng(y: y, x: x))
                    //print("\(latitude) \(longitude) || \(y) \(x)")
                    stream.points.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
            }
            streams.append(stream)
        }
        return ArcgisGeometry(displayType: displayType, features: streams)
    }
}

struct ArcgisGeometry {
    var displayType: String
    var features: [ArcgisStream]
}

struct ArcgisStream {
    var points: [CLLocationCoordinate2D]
    
    init() {
        self.points = []
    }
}

struct ArcgisStreamsFeature: Hashable, Codable {
    var type: String
    var id: Int
    var geometry: ArcgisStreamsFeatureGeometry
}

struct ArcgisStreamsFeatureAttributes: Hashable, Codable {
    var FID: Int?
    var FNODE: Int?
    var TNODE: Int?
    var LPOLY: Int?
    var RPOLY: Int?
    var LENGTH: Double?
    var ERLENGEW: Int?
    var ERLENGEW_I: Int?
    var GEWAESSERT: Int?
    var WASSERFUEH: String?
    var GEWAESSERZ: String?
    var SIGN: Int?
    var SIGN2: Int?
}

struct ArcgisStreamsFeatureGeometry: Hashable, Codable {
    var type: String
    var coordinates: [[Double]]
}
