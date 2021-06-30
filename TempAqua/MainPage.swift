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
            ObservationsView()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Observations")
                }.tag(1)
            SurveyMap(userData: userData)
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }.tag(2)
            Settings()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }.tag(3)
        }
    }
}
