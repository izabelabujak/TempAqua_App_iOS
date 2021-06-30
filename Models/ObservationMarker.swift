//
//  ObservationMarker.swift
//  TempAqua
//

import SwiftUI

enum ObservationMarker: String, CaseIterable, Codable, Hashable {
    case red = "red"
    case blue = "blue"
    case yellow = "yellow"
    case green = "green"
    case orange = "orange"
    
    func description() -> String {
        if self == ObservationMarker.red {
            return "Red - default"
        } else if self == ObservationMarker.green {
            return "Green - Flow sensor"
        } else if self == ObservationMarker.blue {
            return "Blue - Water level"
        } else if self == ObservationMarker.yellow {
            return "Yellow"
        }
       return "Orange"
    }
    
    func color() -> Color {
         if self == ObservationMarker.red {
            return Color.red
         } else if self == ObservationMarker.green {
            return Color.green
         } else if self == ObservationMarker.blue {
            return Color.blue
         } else if self == ObservationMarker.yellow {
            return Color.yellow
         }
        return Color.orange
    }
    
    func uiColor() -> UIColor {
         if self == ObservationMarker.red {
            return UIColor.red
         } else if self == ObservationMarker.green {
            return UIColor.green
         } else if self == ObservationMarker.blue {
            return UIColor.blue
         } else if self == ObservationMarker.yellow {
            return UIColor.yellow
         }
        return UIColor.orange
    }
}
