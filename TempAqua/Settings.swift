//
//  Settings.swift
//  TempAqua
//

import SwiftUI

struct Settings: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exportManager: ExportManager
    @EnvironmentObject var importManager: ImportManager
    @State var isExportView = false
    
    var body: some View {
        NavigationView {
            Form {
                if exportManager.multimediaToExport.count > 0 {
                    HStack {
                        VStack {
                            Text("Uploading: \(exportManager.transferInMb())")
                            ProgressBar(value: exportManager.progress())
                        }
                        Spacer()
                        if exportManager.isExportingNow {
                            Button(action: {
                                self.exportManager.exportToggle()
                            }, label: {
                                Image(systemName: "pause.circle")
                            })
                        } else {
                            Button(action: {
                                self.exportManager.exportToggle()
                            }, label: {
                                Image(systemName: "play.circle")
                            })
                        }
                    }
                }
                NavigationLink(destination: SettingsCatchments()) {
                    Text("Display catchments")
                    Spacer()
                    Text("\(self.userData.displayCatchments.count)/\(self.userData.catchments.count)")
                }
                
                NavigationLink(destination: SettingsSurveys()) {
                    Text("Display surveys")
                    Spacer()
                    Text("\(self.userData.displaySurveys.count)/\(self.userData.surveys.count)")
                }
            }.navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                self.importManager.sync(userData: self.userData)
                }, label: {
                    Text("Sync")
                    Image(systemName: "arrow.clockwise")
                }))
        }
        
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
