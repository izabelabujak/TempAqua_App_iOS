import Combine
import SwiftUI
import MapKit

final class UserData: UIViewController, CLLocationManagerDelegate, ObservableObject {
    // objects read from the database, to be displayed on the map
    @Published var surveys: [Survey] = []
    @Published var displaySurveys = Set<Survey>()
    @Published var catchments: [Catchment] = []
    @Published var displayCatchments = Set<Catchment>()
    @Published var employees: [Employee] = []
    
    // observations
    @Published var observations = db.read()
    @Published var selection = 3
    @Published var isExportView = false
    
    // data to export
    @Published var catchment: Catchment? = nil
    @Published var surveyExportObservations = Set<Observation>()
    @Published var surveyExportEmployees = Set<Employee>()
    
    // authenticated user
    @Published var authenticationCredentials: AuthenticationCredential?
    
    //
    @Published var alertItem : AlertItem?
    @Published var renderMapStreams = true
    @Published var renderMapObservations = true

    func surveyDuration() -> String {
        let observations = Array(self.surveyExportObservations)
        if observations.count < 2 {
            return ""
        }
        
        let min = observations.reduce(observations[0]){$0.observedAt > $1.observedAt ? $1 : $0}
        let max = observations.reduce(observations[0]){$0.observedAt > $1.observedAt ? $0 : $1}
        let seconds = max.observedAt.timeIntervalSince(min.observedAt)
        let hours = Int(floor(seconds / 3600))
        let minutes = Int(floor((seconds - Double(hours)*3600) / 60))
        return "\(hours)h \(minutes)min"
    }
    
    func surveyDate() -> String {
        if !self.surveyExportObservations.isEmpty {
            let observations = Array(self.surveyExportObservations)
            let min = observations.reduce(observations[0]){$0.observedAt > $1.observedAt ? $1 : $0}
            let date = min.observedAt
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return "Unknown"
    }
    
    func surveyDates() -> String {
        let observations = Array(self.surveyExportObservations)
        if observations.count == 1 {
            let min = observations.reduce(observations[0]){$0.observedAt > $1.observedAt ? $1 : $0}
            return getFullDateFormatter().string(from: min.observedAt)
        } else if observations.count > 1 {
            let min = observations.reduce(observations[0]){$0.observedAt > $1.observedAt ? $1 : $0}
            let max = observations.reduce(observations[0]){$0.observedAt > $1.observedAt ? $0 : $1}
            return "\(getFullDateFormatter().string(from: min.observedAt)) - \(getTimeHourMinutesFormatter().string(from: max.observedAt))"
        }
        return "Unknown"
    }

}

