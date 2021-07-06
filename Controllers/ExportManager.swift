//
//  DataExporter.swift
//  TempAqua
//

import Combine
import SwiftUI
import os

let multimediaEndoint = "/api/multimedia.php"
let multimediaVerifyEndoint = "/api/verify_multimedia.php"
let surveyEndpoint = "/api/survey.php"

final class ExportManager: UIViewController, ObservableObject {
    @Published var multimediaToExport = Set<ObservationMultimedia>()
    @Published var isExportingNow = false
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @Published var transferredInMb = 0.0
    @Published var toTransferInMb = 0.0
       
    func progress() -> Float {
        if self.toTransferInMb > 0 {
            return Float(self.transferredInMb / self.toTransferInMb)
        } else {
            return 1
        }
    }
    
    func setMultimediaToExport(multimediaToExport: Set<ObservationMultimedia>) {
        self.toTransferInMb = 0
        self.transferredInMb = 0
        self.multimediaToExport = multimediaToExport
        for multimedia in self.multimediaToExport {
            self.toTransferInMb += multimedia.sizeInMb()
        }
    }
    
    func export(userData: UserData) {
        // make sure no exporting is taking place now
        self.pauseUploading()
        // reset the current export stats because there is no active export
        if self.multimediaToExport.count == 0 {
            self.toTransferInMb = 0
            self.transferredInMb = 0
        }
        // at this moment we generate a unique ID for the survey
        let survey = Survey(catchment: userData.catchment!, participants: Array(userData.surveyExportParticipants), observations: Array(userData.surveyExportObservations))
        // first export the survey
        exportSurvey(survey: survey)
        
        var newMultimediaToExport = Set<ObservationMultimedia>()
        if var unwrapped = survey.observations {
            for (oindex, observation) in unwrapped.enumerated() {
                for (index, _) in unwrapped[oindex].multimedia.enumerated() {
                    unwrapped[oindex].multimedia[index].surveyId = survey.id
                    unwrapped[oindex].multimedia[index].observationId = observation.id
                    self.toTransferInMb += unwrapped[oindex].multimedia[index].sizeInMb()
                    newMultimediaToExport.insert(unwrapped[oindex].multimedia[index])
                }
            }
        }
        if !db.insert_media_to_export(multimediaList: Array(newMultimediaToExport)) {
            db.insert_log(message: "Could not insert multimedia into export tables", status: "ERROR")
            // throw an error
            return
        }
        // place all multimedia to a cache
        self.multimediaToExport = self.multimediaToExport.union(newMultimediaToExport)
        
        // remove all observations
        //db.deleteNewSurvey()
        //userData.observations = []
        //userData.surveyExportObservations = Set()
        //userData.surveyExportParticipants = Set()
        
        // start the process that will upload multimedia to the server
        resumeUploading()
    }
    
    func resumeUploading() {
        self.isExportingNow = true
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Uploading survey photos") { [weak self] in
            self?.pauseUploading()
        }
        let session = URLSession(configuration: .default)
        DispatchQueue.global(qos: .background).async {
            while true {
                guard self.isExportingNow else { return }
                if let multimedia = self.multimediaToExport.first {
                    self.exportMultimedia(session: session, multimedia: multimedia)
                    usleep(2500000) // sleep 2.5 sec to make sure we do not ddos the server
                    self.verifyAndRemoveMultimedia(session: session, multimedia: multimedia)
                } else {
                    // finish exporting because there is no more multimedia to export in the database
                    break
                }
            }
        }
        
        if self.multimediaToExport.count == 0 {
            self.pauseUploading()
        }
    }
    
    func pauseUploading() {
        DispatchQueue.main.async {
            self.isExportingNow = false
        }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    func exportToggle() {
        if !self.isExportingNow {
            resumeUploading()
        } else {
            pauseUploading()
        }
    }
    
    func exportSurvey(survey: Survey) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData: Data
        do {
            jsonData = try encoder.encode(survey)
        } catch {
            db.insert_log(message: "Could not convert sruvey into JSON during exporting", status: "ERROR")
            return
        }
        if let url = URL(string: "\(serverEndpoint)\(surveyEndpoint)") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    db.insert_log(message: "Server returned an error when exporting survey", status: "ERROR")
                    return
                }
                let response: RestStatus
                do {
                    response = try JSONDecoder().decode(RestStatus.self, from: data)
                } catch {
                    db.insert_log(message: "Server returned an error when exporting survey: could not convert data from JSON)", status: "ERROR")
                    return
                }
                if response.status == "error" {
                    db.insert_log(message: "Server returned an error when exporting survey: \(response.details ?? "")", status: "ERROR")
                } else {
                    db.insert_log(message: "New survey \(survey.id) exported to the database.", status: "ERROR")
                }
            }.resume()
        } else {
            db.insert_log(message: "Could not export the survey. Invalid export survey URL: \(serverEndpoint)\(surveyEndpoint)", status: "ERROR")
        }
        resumeUploading()
    }
    
    func exportMultimedia(session: URLSession, multimedia: ObservationMultimedia) {
        let content = """
                        {
                            "survey_id": "\(multimedia.surveyId)",
                            "observation_id": \(multimedia.observationId),
                            "taken_at": "\(ISO8601DateFormatter().string(from: multimedia.takenAt))",
                            "format": "\(multimedia.format)",
                            "data": "\(multimedia.base64encoded())"
                        }
                      """
        if let url = URL(string: "\(serverEndpoint)\(multimediaEndoint)") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = content.data(using: .utf8)!
            
            session.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    db.insert_log(message: "Server returned an error when exporting multimedia", status: "ERROR")
                    return
                }
                let response: RestStatus
                do {
                    response = try JSONDecoder().decode(RestStatus.self, from: data)
                } catch {
                    db.insert_log(message: "Server returned an error when exporting survey: Could not convert data from JSON", status: "ERROR")
                    return
                }
                if response.status == "error" {
                    db.insert_log(message: "Server returned an error when exporting survey: \(response.details ?? "")", status: "ERROR")
                }
            }.resume()
        } else {
            db.insert_log(message: "Could not export the multimedia. Invalid export multimedia URL: \(multimediaEndoint)", status: "ERROR")
        }
    }
    
    func verifyAndRemoveMultimedia(session: URLSession, multimedia: ObservationMultimedia) {
        let content = """
                        {
                            "survey_id": "\(multimedia.surveyId)",
                            "observation_id": \(multimedia.observationId),
                            "taken_at": "\(ISO8601DateFormatter().string(from: multimedia.takenAt))",
                            "format": "\(multimedia.format)"
                        }
                      """
        let surveyId = multimedia.surveyId
        let observationId = multimedia.observationId
        let takenAt = getDateTimeFormatter().string(from: multimedia.takenAt)
        if let url = URL(string: "\(serverEndpoint)\(multimediaVerifyEndoint)") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = content.data(using: .utf8)!
            session.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    db.insert_log(message: "Server returned an error when verifying exported multimedia (survey: \(surveyId), observation: \(observationId), taken at: \(takenAt)", status: "ERROR")
                    return
                }
                let response: RestStatus
                do {
                    response = try JSONDecoder().decode(RestStatus.self, from: data)
                } catch {
                    db.insert_log(message: "Server returned an error when verifying exported multimedia (survey: \(surveyId), observation: \(observationId), taken at: \(takenAt): Could not convert data from JSON", status: "ERROR")
                    return
                }
                if response.status == "error" {
                    db.insert_log(message: "Verification of exported multimedia failed (survey: \(surveyId), observation: \(observationId), taken at: \(takenAt)", status: "ERROR")
                } else {
                    DispatchQueue.main.async {
                        self.transferredInMb += multimedia.sizeInMb()
                        db.removeFromMediaToExport(multimedia: multimedia)
                        self.multimediaToExport = self.multimediaToExport.filter { $0.surveyId != multimedia.surveyId || $0.observationId != multimedia.observationId || $0.takenAt != multimedia.takenAt }
                    }
                }
            }.resume()
        } else {
            db.insert_log(message: "Could not verify that the multimedia was exported correctly. Invalid verify data URL: \(multimediaVerifyEndoint)", status: "ERROR")
        }
    }
}
