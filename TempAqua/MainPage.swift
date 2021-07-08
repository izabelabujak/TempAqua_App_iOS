//
//  MainPage.swift
//  TempAqua
//

import SwiftUI

struct MainPage: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exportManager: ExportManager
    @EnvironmentObject var importManager: ImportManager
    
    var body: some View {
        TabView(selection: $userData.selection) {
            Mapping()
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Mapping")
                }.tag(0)
            SurveyView()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Observations")
                }.tag(1)
            SurveyMap()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }.tag(2)
            if userData.authenticationCredentials != nil {
                Settings()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }.tag(3)
            } else {
                Login()
                    .tabItem {
                        Image(systemName: "person")
                        Text("Login")
                    }.tag(3)
            }
        }.alert(item: $userData.alertItem) { alertItem in
            guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton else {
                return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
            }
            return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
    }
}


