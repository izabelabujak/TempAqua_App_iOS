//
//  LandmarkRow.swift
//  TempAqua
//

import SwiftUI

struct ObservationRow: View {
    var observation: Observation
    var longitude: String
    var latitude: String
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text("#\(observation.id)")
                    if let anchorPoint = observation.anchorPoint {
                        Text("\(anchorPoint)").font(.footnote)
                    } else {
                        Text("\(calculateDistance(p1: geolocation, p2: observation.location()))m away").font(.footnote)
                        if let elevation = observation.elevation {
                            if let elevation2 = geolocationAltitude {
                                if elevation > 0 && elevation2 > 0 {
                                    Text("\(elevation-elevation2)m higher").font(.footnote)
                                }
                            }
                        }
                    }
                    Spacer()
                    if let parent_id = observation.parent {
                        Image(systemName: "arrow.right.to.line.alt")
                        Text("#\(parent_id)")
                    }
                }
                HStack {
                    Image(systemName: "smallcircle.fill.circle").foregroundColor(observation.marker.color()).font(.footnote)
                    Text(observation.category.description())
                    Spacer()
                    Text("\(getFullDateFormatter().string(from: observation.observedAt))").font(.footnote)
                }
            }
        }
    }
}
