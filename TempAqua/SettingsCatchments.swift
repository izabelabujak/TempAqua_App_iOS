//
//  Settings.swift
//  TempAqua
//

import SwiftUI

struct SettingsCatchments: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var importManager: ImportManager
    
    var body: some View {
        List {
            ForEach(userData.catchments, id: \.id) { catchment in
                HStack {
                    Text(catchment.name)
                        Spacer()
                        if self.userData.displayCatchments.contains(catchment) {
                            Button(action: {
                                self.userData.displayCatchments.remove(catchment)
                                renderMapStreams = true
                            }) {
                                Image(systemName: "eye")
                            }
                        } else {
                            Button(action: {
                                self.userData.displayCatchments.insert(catchment)
                                renderMapStreams = true
                            }) {
                                Image(systemName: "eye.slash")
                            }
                        }
//                        }
                }
            }
        }
        .navigationBarTitle("Display catchments", displayMode: .inline)
    }
}

struct SettingsCatchments_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
