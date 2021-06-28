//
//  SurveyExportObservations.swift
//  TempAqua
//

import SwiftUI

struct SurveyExportObservations: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        List(self.userData.observations, id: \.self, selection: $userData.surveyExportObservations){ o in
            Text("#\(o.id) \(getFullDateFormatter().string(from: o.observedAt))")
        }.environment(\.editMode, .constant(EditMode.active))
    }
}
