//
//  GPSConverer.swift
//  TempAqua
//
//  copied from https://github.com/ValentinMinder/Swisstopo-WGS84-LV03/blob/master/scripts/py/wgs84_ch1903.py

import Foundation
import CoreLocation

func calculateDistance(p1: CLLocationCoordinate2D, p2: CLLocationCoordinate2D) -> Int {
    let l1 = CLLocation(latitude: p1.latitude, longitude: p1.longitude)
    let l2 = CLLocation(latitude: p2.latitude, longitude: p2.longitude)
    let distance = l1.distance(from: l2)
    return Int(distance)
}

func locationFromCH1903(longitude: Double, latitude: Double) -> CLLocationCoordinate2D {
    let lat = CLLocationDegrees(CHtoWGSlat(y: longitude, x: latitude))
    let long = CLLocationDegrees(CHtoWGSlng(y: longitude, x: latitude))
    
    return CLLocationCoordinate2D(latitude: lat, longitude: long)
}

//    GPS Converter class which is able to perform convertions between the
//    CH1903 and WGS84 system.

//  Convert CH y/x/h to WGS height
func CHtoWGSheight(y: Double, x: Double, h: Double) -> Double {
    //Axiliary values (% Bern)
    let y_aux = (Double(y) - 600000) / 1000000
    let x_aux = (Double(x) - 200000) / 1000000
    let h1 = (Double(h) + 49.55)
    let h2 = (12.60 * y_aux)
    let h3 = (22.64 * x_aux)
    return h1 - h2 - h3
}
        

// Convert CH y/x to WGS lat
func CHtoWGSlat(y: Double, x: Double) -> Double {
    // Axiliary values (% Bern)
    let y_aux = (Double(y) - 600000) / 1000000
    let x_aux = (Double(x) - 200000) / 1000000
    var lat = (16.9023892 + (3.238272 * x_aux))
        - (0.270978 * pow(y_aux, 2))
        - (0.002528 * pow(x_aux, 2))
        - (0.0447 * pow(y_aux, 2) * x_aux)
        - (0.0140 * pow(x_aux, 3))
    // Unit 10000" to 1" and convert seconds to degrees (dec)
    lat = (lat * 100) / 36
    return lat
}
        

// Convert CH y/x to WGS long
func CHtoWGSlng(y: Double, x: Double) -> Double {
    // Axiliary values (% Bern)
    let y_aux = (Double(y) - 600000) / 1000000
    let x_aux = (Double(x) - 200000) / 1000000
    var lng = (2.6779094 + (4.728982 * y_aux) + (0.791484 * y_aux * x_aux) + (0.1306 * y_aux * pow(x_aux, 2))) - (0.0436 * pow(y_aux, 3))
    // Unit 10000" to 1" and convert seconds to degrees (dec)
    lng = (lng * 100) / 36
    return lng
}
        

// Convert decimal angle (° dec) to sexagesimal angle (dd.mmss,ss)
func DecToSexAngle(dec: Double) -> Double {
    let degree = Int(floor(dec))
    let minute = Int(floor((dec - Double(degree)) * 60))
    let a = dec - Double(degree)
    let second = ((a * 60.0) - Double(minute)) * 60.0
    let b = Double(minute) / 100.0
    let c = Double(second) / 10000.0
    return Double(degree) + b + c
}
        
        
// Convert sexagesimal angle (dd.mmss,ss) to seconds
func SexAngleToSeconds(dms: Double) -> Double {
    var degree = 0.0
    var minute = 0.0
    var second = 0.0
    degree = Double(Int(floor(dms)))
    minute = Double(Int(floor((dms - Double(degree)) * 100)))
    let a = dms - Double(degree)
    let b = (a * 100.0) - Double(minute)
    second = b * 100.0
    return Double(second) + (Double(minute) * 60) + (Double(degree) * 3600)
}
        
// Convert sexagesimal angle (dd.mmss) to decimal angle (degrees)
func SexToDecAngle(dms: Double) -> Double {
    var degree = 0.0
    var minute = 0.0
    var second = 0.0
    degree = Double(floor(dms))
    minute = Double(floor((dms - Double(degree)) * 100))
    let a = dms - Double(degree)
    let b = a * 100
    let c = b - Double(minute)
    second = c * 100
    return Double(degree) + (Double(minute) / 60) + (Double(second) / 3600)
}
        
// Convert WGS lat/long (° dec) and height to CH h
func WGStoCHh(lat: Double, lng: Double, h: Double) -> Int {
    var lat2 = DecToSexAngle(dec: lat)
    var lng2 = DecToSexAngle(dec: lng)
    lat2 = SexAngleToSeconds(dms: lat2)
    lng2 = SexAngleToSeconds(dms: lng2)
    // Axiliary values (% Bern)
    let lat_aux = (lat2 - 169028.66) / 10000
    let lng_aux = (lng2 - 26782.5) / 10000
    let h2 = (h - 49.55) + (2.73 * lng_aux) + (6.94 * lat_aux)
    return Int(h2)
}
        
// Convert WGS lat/long (° dec) to CH x
func WGStoCHx(lat: Double, lng: Double) -> Int {
    var lat2 = DecToSexAngle(dec: lat)
    var lng2 = DecToSexAngle(dec: lng)
    lat2 = SexAngleToSeconds(dms: lat2)
    lng2 = SexAngleToSeconds(dms: lng2)
    // Axiliary values (% Bern)
    let lat_aux = (lat2 - 169028.66) / 10000
    let lng_aux = (lng2 - 26782.5) / 10000
    let x = ((200147.07 + (308807.95 * lat_aux) + (3745.25 * pow(lng_aux, 2)) + (76.63 * pow(lat_aux,2))) - (194.56 * pow(lng_aux, 2) * lat_aux)) + (119.79 * pow(lat_aux, 3))
    return Int(x)
}
        
// Convert WGS lat/long (° dec) to CH y
func WGStoCHy(lat: Double, lng: Double) -> Int {
    var lat2 = DecToSexAngle(dec: lat)
    var lng2 = DecToSexAngle(dec: lng)
    lat2 = SexAngleToSeconds(dms: lat2)
    lng2 = SexAngleToSeconds(dms: lng2)
    // Axiliary values (% Bern)
    let lat_aux = (lat2 - 169028.66) / 10000
    let lng_aux = (lng2 - 26782.5) / 10000
    let y = (600072.37 + (211455.93 * lng_aux)) - (10938.51 * lng_aux * lat_aux) - (0.36 * lng_aux * pow(lat_aux, 2)) - (44.54 * pow(lng_aux, 3))
    return Int(y)
}
        
//func LV03toWGS84(east: Double, north: Double, height: Double) -> Double {
//    // Convert LV03 to WGS84 Return a array of double that contain lat, long,
//    // and height
//    var d = []
//    d.append(CHtoWGSlat(y: east, x: north))
//    d.append(CHtoWGSlng(y: east, x: north))
//    d.append(CHtoWGSheight(y: east, x: north, h: height))
//    return d
//}
//
//func WGS84toLV03(latitude: Double, longitude: Double, ellHeight: Double) -> [Int] {
//    // Convert WGS84 to LV03 Return an array of double that contaign east,
//    // north, and height
//    var d = []
//    d.append(WGStoCHy(y: latitude, x: longitude))
//    d.append(WGStoCHx(y: latitude, x: longitude))
//    d.append(WGStoCHh(y: latitude, x: longitude, h: ellHeight))
//    return d
//}
//
//
//    # Coordinates
//    wgs84 = [46.95108, 7.438637, 0]
//    lv03  = []
//
//    # Convert WGS84 to LV03 coordinates
//    lv03 = converter.WGS84toLV03(wgs84[0], wgs84[1], wgs84[2])
//
//    print "WGS84: "
//    print wgs84
//    print "LV03: "
//    print lv03
