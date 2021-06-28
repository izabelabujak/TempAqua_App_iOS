//
//  SceneDelegate.swift
//  TempAqua
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        let userData = UserData()
        // load previous surveys stored in the database
        var surveys = db.read_surveys()
        // the survey with ID=0 is the current survey that should be modifiable
        for (index, survey) in surveys.enumerated() {
            if survey.id == "0" {
                userData.observations = survey.observations ?? []
                surveys.remove(at: index)
                break
            }
        }
        userData.surveys = surveys
        // by default turn display on the map the latest survey
        if !userData.surveys.isEmpty {
            userData.displaySurveys.insert(userData.surveys[userData.surveys.count-1])
        }
        //
        let catchments = db.read_catchments()
        userData.catchments = catchments
        for (_, catchment) in userData.catchments.enumerated() {
            userData.displayCatchments.insert(catchment)
        }
        display_catchments(userData: userData)
        
        //load photos that still have to be uploaded to the remote server
        let exportManager = ExportManager()
        let multimedia = db.read_media_to_export()
        exportManager.multimediaToExport = Set(multimedia)
        
        // Create the SwiftUI view that provides the window contents.
        let rootView = MainPage()
            .environmentObject(userData)
            .environmentObject(exportManager)
            .environmentObject(ImportManager())

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: rootView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

func display_catchments(userData: UserData) {
    for catchment in userData.displayCatchments {
        for type in ["", "_border"] {
            let filename = getDocumentsDirectory().appendingPathComponent("\(catchment.id)\(type).geojson")
            do {
                let data = try Data(contentsOf: filename)
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    if type == "_border" {
                        let arcgis = try decoder.decode(ArcgisBorder.self, from: data)
                        arcgisGeometry.append(arcgis.convert_to_ch_system(displayType: type))
                    } else {
                        let arcgis = try decoder.decode(ArcgisStreams.self, from: data)
                        arcgisGeometry.append(arcgis.convert_to_ch_system(displayType: type))
                    }
                } catch {
                    print("Couldn't parse \(error)")
                }
            } catch {
                print("Couldn't load from main bundle:\n\(error)")
            }
        }
    }
}
