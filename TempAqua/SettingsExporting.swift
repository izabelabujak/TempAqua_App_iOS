//
//  Settings.swift
//  TempAqua
//

import SwiftUI

struct SettingsExporting: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var importManager: ImportManager
    @EnvironmentObject var exportManager: ExportManager
    @State private var showingAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            VStack {
                Text("Transferred \(exportManager.transferredInMb, specifier: "%.2f") from \(exportManager.toTransferInMb, specifier: "%.2f") MB").padding(.top, 20)
                ProgressBar(value: exportManager.progress()).padding(.bottom, 20)
                if exportManager.multimediaToExport.count > 0 {
                    if exportManager.isExportingNow {
                        Button(action: {
                            self.exportManager.exportToggle(userData: self.userData, importManager: self.importManager)
                        }, label: {
                            HStack {
                                Text("Pause")
                                Image(systemName: "pause.circle")
                            }
                        }).padding(.bottom, 20)
                    } else {
                        Button(action: {
                            self.exportManager.exportToggle(userData: self.userData, importManager: self.importManager)
                        }, label: {
                            HStack {
                                Text("Resume")
                                Image(systemName: "play.circle")
                            }
                        }).padding(.bottom, 20)
                    }
                }
            }.listRowInsets(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                           
            ForEach(Array(exportManager.multimediaToExport), id: \.self) { multimedia in
                HStack {
                    Text("\(multimedia.surveyId)/\(multimedia.observationId): \(getFullDateFormatter().string(from: multimedia.takenAt)) \(multimedia.format)")
                    Spacer()
                    Text("\(multimedia.sizeInMb(), specifier: "%.2f") MB")
                }
            }
        }.frame(maxHeight: .infinity)
        .navigationBarTitle("Exporting Observations", displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                self.showingAlert = true
            }, label: {
                Text("Remove").foregroundColor(.red)
            }).alert(isPresented: $showingAlert) {
                Alert(title: Text("Are you sure you want to remove all multimedia queued for export?"),
                      message: Text("There is no undo. I hope you know what you are doing."),
                      primaryButton: .destructive(Text("Delete")) {
                            db.removeAllMultimediaToExport()
                            self.exportManager.multimediaToExport = Set()
                            self.presentationMode.wrappedValue.dismiss()
                      }, secondaryButton: .cancel())
            }
        )
    }
}

struct ProgressBar: View {
    var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: 15)
                    .opacity(0.3)
                    .foregroundColor(Color(UIColor.systemTeal))
                
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: 15)
                    .foregroundColor(Color(UIColor.systemBlue))
                    .animation(.linear)
            }.cornerRadius(45.0)
        }
    }
}
