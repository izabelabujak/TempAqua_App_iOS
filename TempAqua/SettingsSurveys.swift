//
//  Settings.swift
//  TempAqua
//

import SwiftUI

struct SettingsSurveys: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exportManager: ExportManager
    @EnvironmentObject var importManager: ImportManager
    @State var isExportView = false
    
    var body: some View {
        List {
            ForEach(userData.surveys, id: \.id) { survey in
                HStack {
                    Text(getFullDateFormatter().string(from: survey.createdAt))
                    if survey.observations?.isEmpty ?? true {
                        Spacer()
                        Button(action: {
                            self.importManager.fetchSurvey(userData: self.userData, survey_id: survey.id)
                            self.userData.renderMapStreams = true
                        }, label: {
                            Image(systemName: "icloud.and.arrow.down")
                        })
                    } else {
                        Spacer()
                        NavigationLink(destination: SettingsSurveysDetails(survey: survey)) {
                        }
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle("Past surveys", displayMode: .inline)
    }
}

struct SettingsSurveysDetails: View {
    @EnvironmentObject var userData: UserData
    var survey: Survey
    
    var body: some View {
        List {
            ForEach(survey.observations ?? [], id: \.id) { observation in
                VStack(alignment: .leading) {
                    HStack {
                        Text(getTimeHourMinutesFormatter().string(from: observation.observedAt))
                        Text(observation.anchorPoint ?? "")
                    }
                    VStack(alignment: .leading) {
                        Text(observation.category.description()).font(.footnote)
                        if let wl = observation.waterLevel {
                            Text("Water level: \(wl, specifier: "%.2f") cm").font(.footnote)
                        }
                        if let d = observation.discharge {
                            Text("Discharge: \(d, specifier: "%.2f") L/min").font(.footnote)
                        }
                        Text(observation.comment ?? "").font(.footnote)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .navigationBarTitle("Survey \(getDayFormatter().string(from: survey.createdAt))", displayMode: .inline)
    }
    
}
