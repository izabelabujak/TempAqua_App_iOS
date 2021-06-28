//
//  SurveyParticipants.swift
//  TempAqua
//

import SwiftUI

struct SurveyExportParticipants: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        List(employees, id: \.self, selection: $userData.surveyExportParticipants){ p in
            Text(p.name)
        }.environment(\.editMode, .constant(EditMode.active))
    }
}
