//
//  DataExporter.swift
//  TempAqua
//

import Combine
import SwiftUI
import os

let multimediaEndoint = "https://izabelabujak.com/tempaqua/api/multimedia.php"
let surveyEndpoint = "https://izabelabujak.com/tempaqua/api/survey.php"

final class ExportManager: UIViewController, ObservableObject {
    @Published var multimediaToExport = Set<ObservationMultimedia>()
    @Published var isExportingNow = false
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var transferredInMb = 0.0
    var toTransferInMb = 0.0
    
    func transferInMb() -> String {
        return String(format: "%.1f MB", self.toTransferInMb)
    }
    
    func progress() -> Float {
        if self.toTransferInMb > 0 {
            return Float(self.transferredInMb / self.toTransferInMb)
        } else {
            return 1
        }
    }
    
    func export(userData: UserData) {
        if userData.catchment == nil || userData.surveyExportParticipants.count == 0 || userData.surveyExportObservations.count == 0 {
            print("Cannot export the data. Not enough information")
            return
        }
        let confirmationEmail = true
        let removeAfterExporting = false
        
        // at this moment we generate unique ID for survey
        let survey = Survey(catchment: userData.catchment!, participants: Array(userData.surveyExportParticipants), observations: Array(userData.surveyExportObservations))
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        var multimediaToExport = Set<ObservationMultimedia>()
        if var unwrapped = survey.observations {
            for (oindex, _) in unwrapped.enumerated() {
                for (index, _) in unwrapped[oindex].multimedia.enumerated() {
                    unwrapped[oindex].multimedia[index].surveyId = survey.id
                    self.toTransferInMb += unwrapped[oindex].multimedia[index].sizeInMb()
                    multimediaToExport.insert(unwrapped[oindex].multimedia[index])
                }
            }
        }

//        db.insert_media_to_export(multimediaList: Array(multimediaToExport))
        self.multimediaToExport = self.multimediaToExport.union(multimediaToExport)
        
        let jsonData: Data
        do {
            jsonData = try encoder.encode(survey)
        } catch {
            os_log("Could not convert survey into JSON", type: .error)
            return
        }
        let url = URL(string: "\(surveyEndpoint)?confirmationEmail=\(confirmationEmail)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                //os_log("Server returned an error when exporting survey %@", type: .error, error?.localizedDescription ?? "Unknown error")
                return
            }
            let response = try? JSONDecoder().decode(RestStatus.self, from: data)
            var errorMessage: String?
            if let response = response {
                if response.status == "error" {
                    errorMessage = response.details ?? ""
                    //os_log("%@", type: .error, errorMessage ?? "")
                } else {
                    // survey exported correctly, time to clean up
                    DispatchQueue.main.async {
                        if removeAfterExporting {
                            db.storeNewSurvey(newSurveyId: survey.id)
                            userData.surveys.insert(survey, at: 0)
                            userData.observations = []
                        }
                    }
                }
            } else {
                errorMessage = "Could not convert data from JSON: \(String(decoding: data, as: UTF8.self))"
                os_log("Error from TempAqua server %@", type: .error, errorMessage ?? "")
            }
        }.resume()
        resumeUploading()
    }
    
    func resumeUploading() {
        os_log("Uploading photos resumed", type: .debug)
        self.isExportingNow = true
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Uploading survey photos") { [weak self] in
            self?.pauseUploading()
        }
        let session = URLSession(configuration: .default)
        DispatchQueue.global(qos: .background).async {
            for multimedia in self.multimediaToExport {
                guard self.isExportingNow else { return }
                self.exportMultimedia(session: session, multimedia: multimedia)
            }
            if self.multimediaToExport.capacity == 0 {
                self.toTransferInMb = 0
                self.transferredInMb = 0
                self.pauseUploading()
            }
        }
    }
    
    func pauseUploading() {
        DispatchQueue.main.async {
            self.isExportingNow = false
        }
        os_log("Uploading photos paused", type: .debug)
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
    
    func exportMultimedia(session: URLSession, multimedia: ObservationMultimedia) {
        //os_log("Exporting Photo %@ %@", type: .debug, multimedia.surveyId, multimedia.observationId)
        let dataBase64 = multimedia.base64encoded()        
        let content = """
                        {
                            "survey_id": "\(multimedia.surveyId)",
                            "observation_id": \(multimedia.observationId),
                            "taken_at": "\(ISO8601DateFormatter().string(from: multimedia.takenAt))",
                            "format": "\(multimedia.format)",
                            "data": "\(dataBase64)"
                        }
                      """
        var request = URLRequest(url: URL(string: multimediaEndoint)!)
        request.httpMethod = "POST"
        request.httpBody = content.data(using: .utf8)!
//        self.removeFromMultimedia(multimedia: multimedia)

        session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                os_log("Server returned an error when exporting survey %@", type: .error, error?.localizedDescription ?? "Unknown error")
                return
            }
            usleep(10000000)
            let response = try? JSONDecoder().decode(RestStatus.self, from: data)
            var errorMessage: String?
            if let response = response {
                if response.status == "error" {
                    errorMessage = response.details ?? ""
                    os_log("%@", type: .error, errorMessage ?? "")
                } else {
                    DispatchQueue.main.async {
                        self.transferredInMb += multimedia.sizeInMb()
                        self.removeFromMultimedia(multimedia: multimedia)
                    }
                }
            } else {
                errorMessage = "Could not convert data from JSON: \(String(decoding: data, as: UTF8.self))"
                os_log("%@", type: .error, errorMessage ?? "")
            }
        }.resume()
    }
    
    func removeFromMultimedia(multimedia: ObservationMultimedia) {
        db.removeFromMediaToExport(multimedia: multimedia)
        self.multimediaToExport.remove(multimedia)
    }
}
