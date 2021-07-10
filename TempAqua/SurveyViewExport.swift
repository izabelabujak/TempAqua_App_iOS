//
//  SurveyExport.swift
//  TempAqua
//

import SwiftUI
import MessageUI

struct SurveyViewExport: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exportManager: ExportManager
    @Binding var isPrepareExportView: Bool
    
    var body: some View {
        NavigationView {
            Form {
                NavigationLink(destination: SurveyExportCatchment()) {
                    Text("Catchment: ")
                    Spacer()
                    Text("\(self.userData.catchment?.name ?? "none")")
                }
                NavigationLink(destination: SurveyExportObservations()) {
                    Text("Observations: ")
                    Spacer()
                    Text("\(self.userData.surveyExportObservations.count)")
                }
                NavigationLink(destination: SurveyExportParticipants()) {
                    Text("Participants: ")
                    Spacer()
                    Text("\(self.userData.surveyExportEmployees.count)")
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
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Survey Export", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                    self.exportManager.export(userData: self.userData)
                    self.isPrepareExportView = false
                    self.userData.selection = 3
                    self.userData.isExportView = true
                }, label: {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Export")
                }).disabled(userData.surveyExportObservations.isEmpty || userData.surveyExportEmployees.isEmpty || userData.catchment == nil))
        }
    }
}

struct SurveyExportCatchment: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        List(self.userData.catchments, id: \.self, selection: $userData.catchment){ o in
            Text("\(o.name)")
        }.environment(\.editMode, .constant(EditMode.active))
    }
}

struct SurveyExportObservations: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        List(self.userData.observations, id: \.self, selection: $userData.surveyExportObservations){ o in
            if let anchorPoint = o.anchorPoint {
                Text("#\(o.id) \(anchorPoint)")
                Spacer()
                Text("\(getFullDateFormatter().string(from: o.observedAt))")
            } else {
                Text("#\(o.id)")
                Spacer()
                Text("\(getFullDateFormatter().string(from: o.observedAt))")
            }
        }.environment(\.editMode, .constant(EditMode.active))
    }
}

struct SurveyExportParticipants: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        List(userData.employees, id: \.self, selection: $userData.surveyExportEmployees){ employee in
            Text(employee.name)
        }.environment(\.editMode, .constant(EditMode.active))
    }
}
