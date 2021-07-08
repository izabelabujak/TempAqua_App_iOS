//
//  SurveyParticipants.swift
//  TempAqua
//

import SwiftUI

struct SurveyExportParticipants: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        List(userData.employees, id: \.self, selection: $userData.surveyExportEmployees){ employee in
            Text(employee.name)
        }.environment(\.editMode, .constant(EditMode.active))
    }
}
