//
//  Settings.swift
//  TempAqua
//

import SwiftUI

struct Login: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var importManager: ImportManager
    
    @State var email: String = "izabela.bujak@epfl.ch"
    @State var password: String = ""
    @State var url: String = "izabelabujak.com/tempaqua"
    let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)
    @State private var showingAlert = false
    @State private var alertMessage: String = ""

    var body: some View {
        ScrollView {
            VStack {
                Image("A7F92D54-B2B8-403C-A756-9064AC37569D_1_105_c")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(150)
                        .padding(.bottom, 20)
                Text("TempAqua").font(.system(size: 30))
                    .padding(.bottom, 20)
                TextField("Hostname", text: $url)
                    .textCase(.lowercase)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 10)
                TextField("Username", text: $email)
                    .textCase(.lowercase)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 10)
                SecureField("Password", text: $password)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                Button(action: {
                    userData.loading = true
                    login()
                    userData.loading = false
                }) {
                    Text("Login")
                }.alert(isPresented: $showingAlert) {
                    Alert(title: Text("Authentication"), message: Text("Invalid email or password"), dismissButton: .default(Text("OK")))
                }
            }.padding()
        }
    }
    
    func login() {
        let json: [String: Any] = ["email": self.email, "password": self.password]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        let host = url.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let auth_url = "https://\(host)/api/login.php"

        if let url = URL(string: auth_url) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    self.showingAlert = true
                    return
                }
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    if let status = responseJSON["status"] as? String {
                        if status == "OK" {
                            DispatchQueue.main.async {
                                db.insert_auth(email: email, password: password, url: host)
                                userData.authenticationCredentials = AuthenticationCredential(email: email, password: password, url: host)
                                userData.selection = 0
                                self.importManager.sync(userData: self.userData)
                            }
                        } else {
                            self.showingAlert = true
                        }
                    } else {
                        self.showingAlert = true
                    }
                } else {
                    self.showingAlert = true
                }
            }
            task.resume()
        } else {
            self.showingAlert = true
            return
        }
    }
}

