//
//  Settings.swift
//  TempAqua
//

import SwiftUI

struct Settings: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exportManager: ExportManager
    @EnvironmentObject var importManager: ImportManager
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Catchments")) {
                    List {
                        ForEach(userData.catchments, id: \.id) { catchment in
                            HStack {
                                Text(catchment.name)
                                Spacer()
                                if self.userData.displayCatchments.contains(catchment) {
                                    Button(action: {
                                        self.userData.displayCatchments.remove(catchment)
                                        db.update_catchment(catchment_id: catchment.id, display: false)
                                        arcgisGeometry = [] // will force rerendering catchments and streams on the map
                                        self.userData.renderMapStreams = true
                                    }) {
                                        Image(systemName: "eye")
                                    }
                                } else {
                                    Button(action: {
                                        self.userData.displayCatchments.insert(catchment)
                                        db.update_catchment(catchment_id: catchment.id, display: true)
                                        arcgisGeometry = [] // will force rerendering catchments and streams on the map
                                        self.userData.renderMapStreams = true
                                    }) {
                                        Image(systemName: "eye.slash")
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Past surveys")) {
                    NavigationLink(destination: SettingsSurveys()) {
                        Text("View")
                    }
                }
            
                if self.exportManager.multimediaToExport.count > 0 {
                    Section(header: Text("Exporting")) {
                        NavigationLink(destination: SettingsExporting(), isActive: $userData.isExportView) {
                            Text("Multimedia export status")
                            Spacer()
                            Text("\(self.exportManager.multimediaToExport.count)")
                        }
                    }
                }
                
                Section(header: Text("Debuging")) {
                    NavigationLink(destination: SettingsLogs()) {
                        Text("Logs")
                    }
                    Button(action: {
                        showingAlert = true;
                    }) {
                        Text("Remove all data")
                    }
                    .foregroundColor(.red)
                    .alert(isPresented:$showingAlert) {
                            Alert(title: Text("Are you sure you want to remove all data?"),
                                  message: Text("Just make sure you have exported the current survey. The rest can be synced from the server."),
                                  primaryButton: .destructive(Text("Delete")) {
                                        db.deleteNewSurvey()
                                        self.userData.observations = []
                                        self.userData.surveyExportObservations = []
                                        self.userData.surveyExportEmployees = Set()
                                        db.remove_catchments()
                                        userData.catchments = []
                                        userData.displayCatchments = []
                                        db.remove_surveys()
                                        userData.surveys = []
                                        userData.displaySurveys = []
                                        db.removeAllMultimediaToExport()
                                        self.exportManager.multimediaToExport = Set()
                                        userData.renderMapObservations = true
                                  }, secondaryButton: .cancel())
                    }
                }
                
                Section() {
                    Button(action: {
                        db.delete_auth();
                        userData.authenticationCredentials = nil;
                        userData.selection = 0;
                    }) {
                        Text("Log out")
                    }
                    
                }
            }.navigationBarTitle("\(userData.authenticationCredentials?.email ?? "")", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.importManager.sync(userData: self.userData)
                }, label: {
                    Text("Sync")
                    Image(systemName: "arrow.clockwise")
                }))
        }
        
    }
}
