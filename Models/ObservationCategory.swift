//
//  Category.swift
//  TempAqua
//

import SwiftUI

enum ObservationCategory: String, CaseIterable, Codable, Hashable {
    case dryStreambed = "D"
    case wetStreambed = "WS"
//    case isolatedPool = "IP"
    case standingWater = "S"
    case weaklyTrickling = "WT"
    case trickling = "T"
    case weaklyFlowing = "WF"
    case flowing = "F"
    case wetland = "W"
    case routeMark = "M"
    case other = "O"
    
    func description() -> String {
        if self == ObservationCategory.dryStreambed {
            return "Dry streambed"
        } else if self == ObservationCategory.wetStreambed {
            return "Wet streambed"
//        } else if self == ObservationCategory.isolatedPool {
//            return "Isolated pool"
        } else if self == ObservationCategory.standingWater {
            return "Standing water"
        } else if self == ObservationCategory.weaklyTrickling {
            return "Weakly trickling (<1 L/min)"
        } else if self == ObservationCategory.trickling {
            return "Trickling (1-2 L/min)"
        } else if self == ObservationCategory.weaklyFlowing {
            return "Weakly flowing (2-5 L/min)"
        } else if self == ObservationCategory.flowing {
           return "Flowing (>5 L/min)"
        } else if self == ObservationCategory.routeMark {
            return "Route mark"
        } else if self == ObservationCategory.wetland {
            return "Wetland"
        }
       return "Other"
    }
}
