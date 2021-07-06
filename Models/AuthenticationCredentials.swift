//
//  AuthenticationCredentials.swift
//  TempAqua
//

import Foundation

struct AuthenticationCredential: Hashable, Codable {
    var email: String = ""
    var password: String = ""
    var url: String = ""
}
