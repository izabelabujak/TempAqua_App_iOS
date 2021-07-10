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
        if userData.showLoadingScreen {
            LoadingView()
        } else {
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
}


struct LoadingView: View {
    @State private var isLoading = false
    @State private var isLoading2 = false
    private let animation = Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
    private let animation2 = Animation.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3)
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    Circle()
                        .frame(width: 120, height: 120)
                        .foregroundColor(isLoading ? Color(.systemGray5) : .red)
                        .animation(.spring(response: 0.3, dampingFraction: 0.3, blendDuration: 0.3))
                    Image(systemName: "heart.fill")
                        .foregroundColor(isLoading ? .red : .white)
                        .font(.system(size: 70))
                        .scaleEffect(isLoading ? 1.0 : 0.5)
                }.onAppear() {
                    withAnimation(self.animation, {
                        self.isLoading.toggle()
                    })
                }
                Text("Please wait...").font(.system(size: 25)).padding()
            }

            
        }
    }
}
