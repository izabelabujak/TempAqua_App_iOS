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
        ZStack {
            if userData.loading {
                LoadingView().zIndex(1)
            }
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
                SurveyMap(userData: userData)
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
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black
                .opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            Text("Please wait...")
        }
    }
}
