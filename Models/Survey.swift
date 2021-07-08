//
//  Survey.swift
//  TempAqua
//

import Foundation

struct Survey: Hashable, Codable {
    var id: String
    var createdAt: Date
    var catchmentId: String
    var employees: [Employee]?
    var observations: [Observation]?
    
    init(id: String, createdAt: Date, catchmentId: String, employees: [Employee]?, observations: [Observation]?) {
        self.id = id
        self.createdAt = createdAt
        self.catchmentId = catchmentId
        self.employees = employees
        self.observations = observations
    }
    
    init(catchment: Catchment, employees: [Employee], observations: [Observation]) {
        var id: String = " "
        if let earliestCreationDate = observations.min(by: { $0.observedAt < $1.observedAt }) {
            let formatter1 = DateFormatter()
            formatter1.dateFormat = "ddMMyy"
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "HHmm"
            id = "S\(formatter1.string(from: earliestCreationDate.observedAt))H\(formatter2.string(from: earliestCreationDate.observedAt))"
        }
        self.id = id
        self.createdAt = Date()
        self.catchmentId = catchment.id
        self.employees = employees
        self.observations = observations
    }
}
