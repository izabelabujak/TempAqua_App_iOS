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
                    Text(getDayFormatter().string(from: survey.createdAt))
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
                        if self.userData.displaySurveys.contains(survey) {
                            Button(action: {
                                self.userData.displaySurveys.remove(survey)
                                self.userData.renderMapStreams = true
                            }) {
                                Image(systemName: "eye")
                            }
                        } else {
                            Button(action: {
                                self.userData.displaySurveys.insert(survey)
                                self.userData.renderMapStreams = true
                            }) {
                                Image(systemName: "eye.slash")
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Display surveys", displayMode: .inline)
    }
}
