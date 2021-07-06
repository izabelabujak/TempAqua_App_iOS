//
//  ImportManager.swift
//  TempAqua
//

import Combine
import SwiftUI
import os
import OSLog

let getCatchmentsEndpoint = "/api/get_catchments.php"
let getCatchmentsGeometryEndpoint = "/api/get_catchment_geometry.php"
let getSurveysEndpoint = "/api/get_surveys.php"

final class ImportManager: UIViewController, ObservableObject {
    func sync(userData: UserData) {
        db.remove_catchments()
        userData.catchments = []
        userData.displayCatchments = []
        // sync catchments
        self.fetchCatchments(userData: userData)
        usleep(2000000) // wait 2 sec
        // sync surveys
        self.fetchSurveys(userData: userData)
        
        renderMapStreams = true
    }
    
    func fetchSurvey(userData: UserData, survey_id: String) {
        var request = URLRequest(url: URL(string: "\(serverEndpoint)\(getSurveysEndpoint)?id=\(survey_id)")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            let survey: Survey
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                survey = try decoder.decode(Survey.self, from: data!)
            } catch {
                Logger().warning("Could not parse the result of fetch survey call")
                return
            }
            DispatchQueue.main.async {
                for (index, s) in userData.surveys.enumerated() {
                    if s.id == survey_id {
                        userData.surveys[index].observations = survey.observations
                        userData.displaySurveys.insert(userData.surveys[index])
                    }
                }
                db.insert_survey_observations(survey_id: survey.id, observations: survey.observations ?? [])
            }
        })

        task.resume()
    }
    
    func fetchSurveys(userData: UserData) {
        var request = URLRequest(url: URL(string: "\(serverEndpoint)\(getSurveysEndpoint)")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            var surveys: [Survey]
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                surveys = try decoder.decode([Survey].self, from: data!)
            } catch {
                print("Couldn't parse \(error)")
                return
            }
            DispatchQueue.main.async {
                for survey in surveys {
                    db.insert_survey(survey: survey)
                }
                // some surveys might have already been fetched.
                // reuse the fetched data by reassigning it to the new survey
                for (index, survey) in surveys.enumerated() {
                    if let stored_survey = userData.surveys.first(where: { $0.id == survey.id }) {
                        surveys[index].observations = stored_survey.observations
                    }
                }
                userData.surveys = surveys
            }
        })
        task.resume()
    }
    
    func fetchCatchments(userData: UserData) {
        var request = URLRequest(url: URL(string: "\(serverEndpoint)\(getCatchmentsEndpoint)")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            var catchments: [Catchment]
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                catchments = try decoder.decode([Catchment].self, from: data!)
            } catch {
                print("Couldn't parse \(error)")
                return
            }
            DispatchQueue.main.async {
                userData.catchments = catchments
                for catchment in catchments {
                    if catchment.id == "LAB" || catchment.id == "RAI" {
                        continue
                    }
                    db.insert_catchment(catchment: catchment)
                    userData.displayCatchments.insert(catchment)
                    self.fetchCatchmentStreams(catchment_id: catchment.id)
                    self.fetchCatchmentBorders(catchment_id: catchment.id)
                }
            }
        })
        task.resume()
    }
    
    func fetchCatchmentStreams(catchment_id: String) {
        var request = URLRequest(url: URL(string: "\(serverEndpoint)\(getCatchmentsGeometryEndpoint)?id=\(catchment_id)")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            DispatchQueue.main.async {
                let filename = getDocumentsDirectory().appendingPathComponent("\(catchment_id).geojson")
                do {
                    let str = String(decoding: data!, as: UTF8.self)
                    try str.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Couldn't write geojson to disk \(error)")
                }
            }
        })
        task.resume()
    }
    
    func fetchCatchmentBorders(catchment_id: String) {
        var request = URLRequest(url: URL(string: "\(serverEndpoint)\(getCatchmentsGeometryEndpoint)?type=border&id=\(catchment_id)")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            DispatchQueue.main.async {
                let filename = getDocumentsDirectory().appendingPathComponent("\(catchment_id)_border.geojson")
                do {
                    let str = String(decoding: data!, as: UTF8.self)
                    try str.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                } catch {
                    print("Couldn't write geojson to disk \(error)")
                }
            }
        })
        task.resume()
    }
}
