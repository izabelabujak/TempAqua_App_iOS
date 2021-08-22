//
//  SurveyMap.swift
//  TempAqua
//

import SwiftUI
import MapKit

struct SurveyMap: UIViewRepresentable {
    @EnvironmentObject var userData: UserData
    
    func makeUIView(context: Context) -> MKMapView {
        if userData.displayCatchments.count > 0 && arcgisGeometry.count == 0 {
            display_catchments(userData: userData)
        }
        let coorindate = CLLocationCoordinate2D(latitude: geolocation.latitude, longitude: geolocation.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.0000001, longitudeDelta: 0.0000001)
        let region = MKCoordinateRegion(center: coorindate, span: span)
        
        let uiView = MKMapView(frame: .zero)
        uiView.showsScale = true
        uiView.isZoomEnabled = true
        uiView.isPitchEnabled = true
        uiView.showsScale = true
        uiView.backgroundColor = UIColor.black
        uiView.showsUserLocation = true
        uiView.delegate = context.coordinator
        uiView.setRegion(region, animated: false)
        uiView.mapType = MKMapType.satellite
        uiView.register(MapPinMarkerView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        return uiView
    }
    
    func makeCoordinator() -> MapViewDelegate {
        MapViewDelegate(self)
    }
    
    func renderCatchments(uiView: MKMapView) {
        if !userData.renderMapStreams {
            // make sure not to render the map twice.
            // otherwise, when we change the tab (for example, we go to observations tab)
            // the map will be rendered again. this will cause delay and bad
            // user experience
            return
        }
        if userData.displayCatchments.count > 0 && arcgisGeometry.count == 0 {
            display_catchments(userData: userData)
        }
        var annotationsToRemove: [MKAnnotation] = []
        for annotation in uiView.annotations {
            if let a = annotation as? MapPin {
                if a.type == "CatchmentLocation" {
                    annotationsToRemove.append(annotation)
                }
            }
        }
        uiView.removeAnnotations(annotationsToRemove)
        
        var ccc: [MapPin] = []
        for catchment in self.userData.displayCatchments {
            for location in catchment.locations {
                var color = UIColor.cyan
                if location.id.starts(with: "CA") || location.id.starts(with: "LA") || location.id.starts(with: "EA") {
                    color = UIColor.orange
                }
//                let anchorPointName = "\(catchment.id)@\(location.id)"
//                if self.userData.observations.contains(where: { $0.anchorPoint == anchorPointName }) {
//                    continue
//                }
                let newLocation = MapPin(observationId: String(location.id),
                                         title: "\(location.id)",
                                         locationName: "\(location.id), \(location.equipment)",
                                         markerTintColor: color,
                                         coordinate: location.wgs(),
                                         type: "CatchmentLocation")
                newLocation.old = true
                ccc.append(newLocation)
            }
        }
        uiView.showAnnotations(ccc, animated: false)
               
        for geometry in arcgisGeometry {
            for feature in geometry.features {
                let myPolyline = MKPolyline(coordinates: feature.points, count: feature.points.count)
                myPolyline.title = geometry.displayType
                uiView.addOverlay(myPolyline)
            }
        }
        
        DispatchQueue.main.async {
            userData.renderMapStreams = false // uiView.annotations.count != 0 && uiView.overlays.count != 0
        }
    }
    
    func renderObservations(uiView: MKMapView) {
        if !userData.renderMapObservations {
            // make sure not to render the map twice.
            // otherwise, when we change the tab (for example, we go to observations tab)
            // the map will be rendered again. this will cause delay and bad
            // user experience
            return
        }
        // remove old annotations
        var annotationsToRemove: [MKAnnotation] = []
        for annotation in uiView.annotations {
            if let a = annotation as? MapPin {
                if a.type == "NewObservation" {
                    annotationsToRemove.append(annotation)
                }
            }
        }
        uiView.removeAnnotations(annotationsToRemove)
        // remove overlays
        var overlaysToRemove: [MKOverlay] = []
        for overlay in uiView.overlays {
            if let o = overlay as? MKPolyline {
                if (o.title ?? "").hasSuffix("_mapping") {
                    overlaysToRemove.append(overlay)
                }
            }
        }
        uiView.removeOverlays(overlaysToRemove)
        
        var aaa: [MapPin] = []
        for observation in self.userData.observations {
            if observation.anchorPoint != nil {
                continue
            }
            let newLocation = MapPin(observationId: String(observation.id),
                                     title: "new",
                                     locationName: "\(getTimeFormatter().string(from: observation.observedAt)), \(observation.category.description())",
                                     markerTintColor: observation.marker.uiColor(),
                                     coordinate: observation.locationAnchorPoint(catchments: self.userData.catchments),
                                     type: "NewObservation")
            aaa.append(newLocation)
        }
        uiView.showAnnotations(aaa, animated: false)
        
        // if in mapping mode then try to display reconstructed stream
        for observation in userData.observations {
            if let parent_id = observation.parent {
                if let parent = userData.observations.first(where: { $0.id == parent_id }) {
                    let myPolyline = MKPolyline(coordinates: [observation.locationAnchorPoint(catchments: self.userData.catchments), parent.locationAnchorPoint(catchments: self.userData.catchments)], count: 2)
                    myPolyline.title = "\(observation.category.rawValue)_mapping"
                    uiView.addOverlay(myPolyline)
                }
            }
        }
        DispatchQueue.main.async {
            userData.renderMapObservations = false
        }
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        renderCatchments(uiView: uiView)
        renderObservations(uiView: uiView)
    }
}

class MapViewDelegate: NSObject, MKMapViewDelegate {
    var control: SurveyMap

    init(_ control: SurveyMap) {
        self.control = control
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let zoomWidth = mapView.visibleMapRect.size.width
        if zoomWidth < 1500 {
            mapView.mapType = MKMapType.standard
        } else {
            mapView.mapType = MKMapType.satellite
        }
//        let zoomFactor = Int(log2(zoomWidth)) - 9
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        var col = UIColor.init(red: 0, green: 240/255, blue: 201/255, alpha: 1)
        var lw = 0.8
        if overlay.title == "_border" {
            col = UIColor.yellow
            lw = 3
        } else if overlay.title == "D_mapping" {
            col = UIColor.red
            lw = 5
        } else if overlay.title == "WS_mapping" {
            col = UIColor.orange
            lw = 5
        } else if overlay.title == "S_mapping" {
            col = UIColor.yellow
            lw = 5
        }  else if overlay.title == "WT_mapping" {
            col = UIColor.init(red: 115/255, green: 222/255, blue: 0/255, alpha: 1) //light green
            lw = 5
        } else if overlay.title == "T_mapping" {
            col = UIColor.init(red: 0/255, green: 179/255, blue: 104/255, alpha: 1) //light blue
            lw = 6
        } else if overlay.title == "WF_mapping" {
            col = UIColor.init(red: 0/255, green: 180/255, blue: 218/255, alpha: 1) //light blue
            lw = 7
        } else if overlay.title == "F_mapping" {
            col = UIColor.init(red: 96/255, green: 0/255, blue: 222/255, alpha: 1)
            lw = 8
        } else if overlay.title == "W_mapping" {
            col = UIColor.green
            lw = 5
        }
        renderer.fillColor = col.withAlphaComponent(CGFloat(0.5))
        renderer.strokeColor = col.withAlphaComponent(CGFloat(0.8))
        renderer.lineWidth = CGFloat(lw)
        

        return renderer
    }
}

class MapPin: NSObject, MKAnnotation {
    let observationId: String?
    let title: String?
    let locationName: String?
    let markerTintColor: UIColor
    let coordinate: CLLocationCoordinate2D
    var old = false
    var type: String

    init(
        observationId: String,
        title: String?,
        locationName: String?,
        markerTintColor: UIColor,
        coordinate: CLLocationCoordinate2D,
        type: String
    ) {
        self.observationId = observationId
        self.title = title
        self.locationName = locationName
        self.markerTintColor = markerTintColor
        self.coordinate = coordinate
        self.type = type

        super.init()
    }

    var subtitle: String? {
      return locationName
    }
}

class MapPinMarkerView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let artwork = newValue as? MapPin else {
                return
            }
            canShowCallout = true
            calloutOffset = CGPoint(x: 0, y: 0)
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            markerTintColor = artwork.markerTintColor
            
            if artwork.old {
                glyphText = artwork.observationId ?? ""
            } else {
                glyphText = artwork.observationId ?? ""
            }
        }
    }
}
