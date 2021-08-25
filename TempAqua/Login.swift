//
//  Settings.swift
//  TempAqua
//

import SwiftUI

struct Login: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var importManager: ImportManager
    
    @State var email: String = ""
    @State var password: String = ""
    @State var url: String = ""
    let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)
    @State private var showingAlert = false
    @State private var alertMessage: String = ""

    var body: some View {
        ScrollView {
            VStack {
                Image("img")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipped()
                        .cornerRadius(150)
                        .padding(.bottom, 20)
                Text("TempAqua Login").font(.system(size: 30))
                    .padding(.bottom, 20)
                TextField("Hostname", text: $url)
                    .disableAutocorrection(true)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(12)
                    .padding(.bottom, 10)
                TextField("Username", text: $email)
                    .disableAutocorrection(true)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(12)
                    .padding(.bottom, 10)
                SecureField("Password", text: $password)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(12)
                    .padding(.bottom, 20)
                
                Button(action: {
                    self.userData.showLoadingScreen = true
                    login() { (host, error) in
                        usleep(3000000) // wait
                        if let _ = error {
                            DispatchQueue.main.async {
                                self.userData.showLoadingScreen = false
                                userData.alertItem = AlertItem(title: Text("Error"), message: Text("Invalid email or password, or no internet access! Please try again."), dismissButton: .default(Text("Ok")))
                            }
                            return
                        }
                        DispatchQueue.main.async {
                            self.userData.showLoadingScreen = false
                            serverEndpoint = "https://\(host)"
                            db.insert_auth(email: email, password: password, url: serverEndpoint)
                            userData.authenticationCredentials = AuthenticationCredential(email: email, password: password, url: host)
                            userData.selection = 0
                            self.importManager.sync(userData: self.userData)
                        }
                    }
                }) {
                    Text("Login")
                }.alert(isPresented: $showingAlert) {
                    Alert(title: Text("Authentication"), message: Text("Invalid email or password, or no internet access."), dismissButton: .default(Text("Ok")))
                }
                
                Text("Login is only required if you want to import/export the data from/to the server. Contact izabela.bujak@epfl.ch or jana.vonfreyberg@epfl.ch to get instructions on how to set up your server.").foregroundColor(.gray).font(.system(size: 11)).padding(.top, 30)
            }.padding()
        }
    }
    
    func login(completionBlock: @escaping (String, String?) -> Void) {
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
                    completionBlock(host, "Server returned an error when login");
                    return
                }
                let response: RestStatus
                do {
                    response = try JSONDecoder().decode(RestStatus.self, from: data)
                } catch {
                    completionBlock(host, "Server returned an error when login: could not convert data from JSON");
                    return
                }
                if response.status == "error" {
                    completionBlock(host, "Server returned an error when login: \(response.details ?? "")");
                    return
                } else {
                    completionBlock(host, nil);
                }
            }
            task.resume()
        } else {
            completionBlock(host, "Invalid login endpoint");
            return
        }
    }
}
