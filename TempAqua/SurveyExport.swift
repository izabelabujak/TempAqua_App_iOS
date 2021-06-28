//
//  SurveyExport.swift
//  TempAqua
//

import SwiftUI
import MessageUI

struct Participant: Hashable, Codable, Identifiable, SelectableRow {
    var id: Int
    var name: String
    var isSelected: Bool = false
}

struct SurveyExport: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exportManager: ExportManager
    @State var removeAfterExporting: Bool = false
    @State var confirmationEmail: Bool = true
    @Binding var isExportView: Bool
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                HStack {
                    VStack{
                        Text("Catchment: \(self.userData.catchment?.name ?? "none")")
                        ScrollView (.horizontal) {
                            HStack(spacing: 5) {
                                ForEach(self.userData.catchments, id: \.self) { c in
                                    Button(action: {
                                        self.userData.catchment = c
                                    }) {
                                        HStack(spacing: 10) {
                                            if self.userData.catchment == c {
                                                Text("\(c.name)").font(.system(size: 30)).foregroundColor(Color.blue)
                                            } else {
                                                Text("\(c.name)").font(.system(size: 30))
                                            }
                                        }
                                    }.padding(10).buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                NavigationLink(destination: SurveyExportObservations()) {
                    Text("Observations: ")
                    Spacer()
                    Text("\(self.userData.surveyExportObservations.count)")
                }
                NavigationLink(destination: SurveyExportParticipants()) {
                    Text("Participants: ")
                    Spacer()
                    Text("\(self.userData.surveyExportParticipants.count)")
                }
                if userData.surveyExportObservations.count > 2 {
                    HStack {
                        Text("Start/End: ")
                        Spacer()
                        Text(self.userData.surveyDates())
                    }
                    HStack {
                        Text("Duration: ")
                        Spacer()
                        Text(self.userData.surveyDuration())
                    }
                }
                Spacer()
                Button(action: {
                    self.exportManager.export(userData: self.userData)
                    self.isExportView = false
                    self.userData.selection = 3
                }) {
                    HStack {
                        Spacer()
                        Text("Export")
                        Spacer()
                    }
                }.disabled(userData.surveyExportObservations.isEmpty || userData.surveyExportParticipants.isEmpty || userData.catchment == nil)
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Survey export")
            .navigationBarItems(
                leading: Button(action: {
                        self.isExportView = false
                    }, label: {
                        Text("Back")
                    }).disabled(userData.observations.isEmpty),
                trailing: Button(action: {
                    self.showingAlert = true
                }, label: {
                    Text("Remove").foregroundColor(.red)
                }).alert(isPresented:$showingAlert) {
                    Alert(title: Text("Are you sure you want to remove the survey?"),
                          message: Text("There is no undo. You probably want to export the survey before deleting it."),
                          primaryButton: .destructive(Text("Delete")) {
                            db.deleteNewSurvey()
                            self.userData.observations = []
                            self.userData.surveyExportObservations = Set()
                            self.userData.surveyExportParticipants = Set()
                            self.isExportView = false
                          }, secondaryButton: .cancel())
                }
            )
            
        }
    }
}
