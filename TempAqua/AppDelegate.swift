//
//  AppDelegate.swift
//  TempAqua
//

import UIKit
import CoreLocation

var importManager = ImportManager()
var geolocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
var geolocation_accuracy = 0.0
var geolocationAltitude: Int? = nil
var geolocationCourse: Int? = nil
var arcgisGeometry: [ArcgisGeometry] = []
var serverEndpoint = "";

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    var locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 3
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = manager.location else { return }
        let altitudeValue = location.altitude
        let accuracy: Double = location.horizontalAccuracy
        let locValue: CLLocationCoordinate2D = location.coordinate
        
        geolocation = locValue
        geolocation_accuracy = accuracy
        geolocationAltitude = Int(altitudeValue)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let courseValue = newHeading.magneticHeading
        if courseValue >= 0 {
            geolocationCourse = Int(courseValue)
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

