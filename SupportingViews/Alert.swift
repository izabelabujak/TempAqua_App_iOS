//
//  Alert.swift
//  TempAqua
//

import Foundation
import SwiftUI

struct AlertItem: Identifiable {
    var id = UUID()
    var title = Text("")
    var message: Text?
    var dismissButton: Alert.Button?
    var primaryButton: Alert.Button?
    var secondaryButton: Alert.Button?
}
