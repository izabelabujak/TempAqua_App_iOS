//
//  Settings.swift
//  TempAqua
//

import SwiftUI

struct SettingsLogs: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var importManager: ImportManager
    
    var body: some View {
        List {
            ForEach(db.read_logs(), id: \.self) { log in
                HStack {
                    Text("\(getFullDateFormatter().string(from: log.createdAt))")
                    Spacer()
                    Text(log.status)
                    Spacer()
                    Text(log.message)
                }
            }
        }
        .navigationBarTitle("Logs", displayMode: .inline)
    }
}
