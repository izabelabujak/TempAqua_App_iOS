//
//  AuthenticationCredentials.swift
//  TempAqua
//

import Foundation

struct LogEntry: Hashable, Codable {
    var message: String
    var status: String
    var createdAt: Date
}
