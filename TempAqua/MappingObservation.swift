//
//  ObservationDetail.swift
//  TempAqua
//

import SwiftUI
import CoreLocation

struct MappingObservation: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.presentationMode) var presentationMode
    @State var category: ObservationCategory = ObservationCategory.other
    @State var id: Int = 0
    @State var comment: String = " "
    @State var latitude: String = ""
    @State var longitude: String = ""
    @State var accuracy: String = ""
    @State var gpsDevice: String = "iPhone"
    @State var direction: String?
    @State var elevation: String?
    @State var marker: ObservationMarker = .red
    @State var observedAt: Date = Date()
    @State var observationMultimedia: [ObservationMultimedia] = []
    @State var parent: Int?
    @State var observationFrom: Set<Observation>
    @State var observationTo: Observation?
    // Added in May 2021:
    @State var nearCatchmentLocations: [NearCatchmentLocation] = []
    @State var anchorPoint: String?
    @State var discharge: String?
    @State var waterLevel: String?
    
    @State var longitudeColor = Color.black
    @State var latitudeColor = Color.black
    
    init() {
        self._latitude = State(initialValue: "")
        self._longitude = State(initialValue: "")
        self._direction = State(initialValue: "")
        self._elevation = State(initialValue: "")
        self._waterLevel = State(initialValue: nil)
        self._discharge = State(initialValue: nil)
        self._anchorPoint = State(initialValue: nil)
        self._observedAt = State(initialValue: Date())
        self._observationTo = State(initialValue: nil)
        self._observationFrom = State(initialValue: Set())
        self._nearCatchmentLocations = State(initialValue: [])
    }
    
    init(observation: Observation, userData: UserData) {
        self._category = State(initialValue: observation.category)
        self._id = State(initialValue: observation.id)
        if let unwrapped = observation.comment {
            self._comment = State(initialValue: String(unwrapped))
        }
        self._latitude = State(initialValue: String(observation.latitude))
        self._longitude = State(initialValue: String(observation.longitude))
        self._accuracy = State(initialValue: String(observation.accuracy))
        self._gpsDevice = State(initialValue: String(observation.gpsDevice))
        if let unwrapped = observation.direction {
            self._direction = State(initialValue: String(unwrapped))
        }
        if let unwrapped = observation.elevation {
            self._elevation = State(initialValue: String(unwrapped))
        }
        if let unwrapped = observation.waterLevel {
            self._waterLevel = State(initialValue: String(unwrapped))
        } else {
            self._waterLevel = State(initialValue: nil)
        }
        if let unwrapped = observation.discharge {
            self._discharge = State(initialValue: String(unwrapped))
        } else {
            self._discharge = State(initialValue: nil)
        }
        if let unwrapped = observation.anchorPoint {
            self._anchorPoint = State(initialValue: String(unwrapped))
        }
        self._marker = State(initialValue: observation.marker)
        self._observedAt = State(initialValue: observation.observedAt)
        self._observationMultimedia = State(initialValue: observation.multimedia)
        self._parent = State(initialValue: observation.parent)
        var from: Set<Observation> = Set()
        for (_, o) in userData.observations.enumerated() {
            if let parent = observation.parent {
                if o.id == parent {
                    self._observationTo = State(initialValue: o)
                }
            }
            if o.parent == observation.id {
                from.insert(o)
            }
        }
        self._observationFrom = State(initialValue: from)
        
        self._nearCatchmentLocations = State(initialValue: self.findNearCatchmentLocations(userData: userData))
    }
    
    func findNearCatchmentLocations(userData: UserData) -> [NearCatchmentLocation] {
        let geo = geolocation
        var heap : Set<NearCatchmentLocation> = Set()
        for (catchment) in userData.displayCatchments {
            for (location) in catchment.locations {
                let anchorPointId = "\(catchment.id)@\(location.id)";
                let parent = location.parent
                var found = false;
                for (observation) in userData.observations {
                    if observation.anchorPoint == anchorPointId {
                        found = true;
                        break;
                    }
                }
                if (!found || self.id > 0) {
                    let distance = calculateDistance(p1: geo, p2: location.wgs())
                    heap.insert(NearCatchmentLocation(catchmentId: catchment.id, locationId: location.id, id: anchorPointId, parent: parent, distance: distance))
                }
            }
        }
        return Array(heap.sorted())
    }
    
    var body: some View {
        List {
            Section(header: Text("GPS Coordinates")) {
                HStack {
                    Button(action: {
                        readPhoneLocation()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }.buttonStyle(BorderlessButtonStyle())
                    VStack {
                        Text("Easting (x)")
                        TextField("CH-1903", text: $longitude).onChange(of: longitude) { newValue in
                            let intValue = Int(newValue) ?? 0
                            if intValue < 450000 || intValue > 850000 {
                                longitudeColor = Color.red
                            } else {
                                longitudeColor = Color.black
                            }
                            self.gpsDevice = "Garmin"
                        }.font(.system(size: 30)).foregroundColor(self.longitudeColor).keyboardType(.numberPad)
                            
                    }
                    Spacer()
                    VStack {
                        Text("Northing (y)")
                        TextField("CH-1903", text: $latitude).onChange(of: latitude) { newValue in
                            let intValue = Int(newValue) ?? 0
                            if intValue < 70000 || intValue > 300000 {
                                latitudeColor = Color.red
                            } else {
                                latitudeColor = Color.black
                            }
                            self.gpsDevice = "Garmin"
                        }.font(.system(size: 30)).foregroundColor(self.latitudeColor).keyboardType(.numberPad)
                    }
                }
                HStack {
                    VStack {
                        Text("Accur. [m]")
                        TextField("?", text: $accuracy).font(.system(size: 30)).keyboardType(.numberPad)
                    }
                    Spacer()
                    VStack {
                        Text("Heading [°T]")
                        TextField("?", text: $direction.bound).font(.system(size: 30)).keyboardType(.numberPad)
                    }
                    Spacer()
                    VStack {
                        Text("Altitude [m]")
                        TextField("?", text: $elevation.bound).font(.system(size: 30)).keyboardType(.numberPad)
                    }
                }
            }.onAppear {
                // make sure there are no coordinates specified yet
                if self.longitude == "" && self.latitude == "" {
                    readPhoneLocation()
                }
            }
            Section(header: Text("Anchor points and stream flow")) {
                if self.nearCatchmentLocations.count > 0 {
                    HStack {
                        VStack{
                            Text("Anchor point: \(self.anchorPoint ?? "None")")
                            ScrollView (.horizontal) {
                                HStack(spacing: 5) {
                                    ForEach(self.nearCatchmentLocations, id: \.id) { c in
                                        Button(action: {
                                            if self.anchorPoint == c.id {
                                                self.anchorPoint = nil
                                                self.observationTo = nil
                                                self.observationFrom = Set()
                                            } else {
                                                self.anchorPoint = c.id
                                                if let parent = c.parent {
                                                    // check if there is already an observation of the parent anchor point
                                                    // if yes, then water flows from here to the parent
                                                    for observation in userData.observations {
                                                        if observation.anchorPoint == "\(c.catchmentId)@\(parent)" {
                                                            self.observationTo = observation
                                                            break
                                                        }
                                                    }
                                                }
                                                // check if there is our child observation
                                                var childAnchorPoints: [String] = []
                                                for catchment in userData.displayCatchments {
                                                    if catchment.id != c.catchmentId {
                                                        continue
                                                    }
                                                    for location in catchment.locations {
                                                        if location.parent == c.locationId {
                                                            childAnchorPoints.append("\(catchment.id)@\(location.id)")
                                                        }
                                                    }
                                                }
                                                for childAnchorPoint in childAnchorPoints {
                                                    for observation in userData.observations {
                                                        if observation.anchorPoint == childAnchorPoint {
                                                            self.observationFrom.insert(observation)
                                                            break
                                                        }
                                                    }
                                                }
                                            }
                                        }) {
                                            VStack(spacing: 10) {
                                                if self.anchorPoint == c.id {
                                                    VStack {
                                                        Text("\(c.catchmentId)").font(.system(size: 12)).foregroundColor(Color.blue).padding(.bottom, 0)
                                                        Text("\(c.locationId)").font(.system(size: 30)).foregroundColor(Color.blue)
                                                        Text("\(c.distance, specifier: "%d")m away").font(.system(size: 12)).foregroundColor(Color.blue)
                                                    }
                                                } else {
                                                    VStack {
                                                        Text("\(c.catchmentId)").font(.system(size: 12)).padding(.bottom, 0)
                                                        Text("\(c.locationId)").font(.system(size: 30)).padding(0)
                                                        Text("\(c.distance, specifier: "%d")m away").font(.system(size: 12)).padding(.top, 0)
                                                    }
                                                }
                                            }
                                        }.padding(10).buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
                HStack {
                    Text("Flows from:")
                    Spacer()
                    NavigationLink(destination: ObservationDetailFrom(observationFrom: self.$observationFrom, longitude: self.longitude, latitude: self.latitude)
                    ) {
                        if observationFrom.count > 0 {
                            Text("\(convertToIds(observations: self.observationFrom))")
                        } else {
                            Text("?")
                        }
                    }
                }
                HStack {
                    Text("Flows to:")
                    Spacer()
                    NavigationLink(destination: ObservationDetailTo(observationTo: self.$observationTo, longitude: self.longitude, latitude: self.latitude)) {
                        if let obs = observationTo {
                            if let anchorPoint = obs.anchorPoint {
                                Text("\(anchorPoint)")
                            } else {
                                Text("#\(obs.id)")
                            }
                            
                        } else {
                            Text("?")
                        }
                    }
                }
            }
            Section(header: Text("Stream state")) {
                HStack {
                    VStack{
                        Text("Category: \(self.category.description())")
                        ScrollView (.horizontal) {
                            HStack(spacing: 5) {
                                ForEach(ObservationCategory.allCases, id: \.self) { c in
                                    Button(action: {
                                        self.category = c
                                        if self.marker == .red {
                                            self.marker = .yellow
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            if self.category == c {
                                                Text("\(c.rawValue)").font(.system(size: 30)).foregroundColor(Color.blue)
                                            } else {
                                                Text("\(c.rawValue)").font(.system(size: 30))
                                            }
                                        }
                                    }.padding(10).buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                HStack {
                    VStack {
                        Text("Water level [cm]")
                        TextField("?", text: $waterLevel.bound).font(.system(size: 30)).keyboardType(.decimalPad)
                    }
                    Spacer()
                    VStack {
                        Text("Discharge [L/min]")
                        TextField("?", text: $discharge.bound).font(.system(size: 30)).keyboardType(.decimalPad)
                    }
                }
            }
            Section(header: Text("Soft data")) {
                HStack {
                    VStack {
                        Text("Comment")
                        TextEditor(text: $comment).frame(height: 160)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                            
                    }
                }
                HStack {
                    VStack{
                        Text("Photos/Videos")
                        ScrollView (.horizontal) {
                            HStack(spacing: 5) {
                                NavigationLink(destination: CapturePhotoView(observationId: self.$id, multimedia: self.$observationMultimedia)
                                ) {
                                    Image(systemName: "plus").frame(width: 60, height: 60).aspectRatio(contentMode: .fill).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray, lineWidth: 1))
                                }
                                ForEach(self.observationMultimedia, id: \.self) { multimedia in
                                    NavigationLink(destination: MappingObservationMultimedia(multimedia: self.$observationMultimedia, showCaptureImageView: false, currentlyDisplayedImage: multimedia)) {
                                        if multimedia.format == "jpg" {
                                            multimedia.image().resizable()
                                                .frame(width: 60, height: 60)
                                                .aspectRatio(contentMode: .fill)
                                                .cornerRadius(12)
                                        } else {
                                            Image(systemName: "film")
                                                .frame(width: 60, height: 60)
                                                .aspectRatio(contentMode: .fill)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }.padding(1).buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                HStack {
                    VStack{
                        Text("Marker: \(self.marker.description())")
                        ScrollView (.horizontal) {
                            HStack(spacing: 5) {
                                ForEach(ObservationMarker.allCases, id: \.self) { m in
                                    Button(action: {
                                        self.marker = m
                                    }) {
                                        HStack(spacing: 10) {
                                            if self.marker == m {
                                                Text("\(m.rawValue)").foregroundColor(m.color())
                                            } else {
                                                Text("\(m.rawValue)")
                                            }
                                        }
                                    }.padding(10).buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
        }.listStyle(InsetGroupedListStyle())
            .gesture(DragGesture().onChanged{_ in UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)})
            .navigationBarTitle(Text("Observation \(getTimeHourMinutesFormatter().string(from: self.observedAt))"), displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                var index = -1
                for (i, observation) in self.userData.observations.enumerated() {
                    if observation.id == self.id {
                        index = i
                        break
                    }
                }
                if index == -1 {
                    index = 0
                    self.userData.observations.insert(Observation(), at: 0)
                }
                self.userData.observations[index].id = self.id
                self.userData.observations[index].observedAt = self.observedAt
                self.userData.observations[index].category = self.category
                self.userData.observations[index].comment = self.comment.trimmingCharacters(in: .whitespacesAndNewlines)
                self.userData.observations[index].latitude = Int(self.latitude) ?? 0
                self.userData.observations[index].longitude = Int(self.longitude) ?? 0
                self.userData.observations[index].accuracy = Int(self.accuracy) ?? 99
                self.userData.observations[index].anchorPoint = self.anchorPoint
                // hack to convert from comma separated decimal format to the dot notation.
                self.userData.observations[index].waterLevel = Double((self.waterLevel ?? "").replacingOccurrences(of: ",", with: ".")) ?? nil
                self.userData.observations[index].discharge = Double((self.discharge ?? "").replacingOccurrences(of: ",", with: ".")) ?? nil
                self.userData.observations[index].gpsDevice = self.gpsDevice
                self.userData.observations[index].multimedia = self.observationMultimedia
                if let obs = self.observationTo {
                    self.userData.observations[index].parent = obs.id
                }
                
                if let unwrapped = self.direction {
                    self.userData.observations[index].direction = Int(unwrapped)
                }
                if let unwrapped = self.elevation {
                    self.userData.observations[index].elevation = Int(unwrapped)
                }
                self.userData.observations[index].marker = self.marker
                            
                let insertNewObservation = self.userData.observations[index].id == 0
                if insertNewObservation {
                    var max = 1
                    for observation in self.userData.observations {
                        if observation.id >= max {
                            max = observation.id + 1
                        }
                    }
                    self.userData.observations[index].id = max
                    db.insert_survey_observations(survey_id: "0", observations: [self.userData.observations[index]])
                } else {
                    db.update_survey_observation(survey_id: "0", observation: self.userData.observations[index])
                }
                
                // update parent
                // remove previous parent bindings
                for (i, o) in self.userData.observations.enumerated() {
                    if o.parent == self.userData.observations[index].id {
                        self.userData.observations[i].parent = nil
                        db.update_survey_observation(survey_id: "0", observation: self.userData.observations[i])
                    }
                }
                for obs in self.observationFrom {
                    for (i, o) in self.userData.observations.enumerated() {
                        if o.id == obs.id {
                            self.userData.observations[i].parent = self.userData.observations[index].id
                            db.update_survey_observation(survey_id: "0", observation: self.userData.observations[i])
                            break
                        }
                    }
                }
                if !insertNewObservation {
                    self.presentationMode.wrappedValue.dismiss()
                }
                // save the information that the photo is persisted
                for (pindex, _) in self.userData.observations[index].multimedia.enumerated() {
                    self.userData.observations[index].multimedia[pindex].persisted = true
                }

                // clear the state
                self.id = 0
                self.comment = " "
                self.latitude = ""
                self.longitude = ""
                self.accuracy = ""
                self.direction = nil
                self.elevation = nil
                self.waterLevel = nil
                self.gpsDevice = "iPhone"
                self.discharge = nil
                self.anchorPoint = nil
                self.marker = ObservationMarker.red
                self.observationMultimedia = []
                self.parent = nil
                self.observationFrom = Set()
                self.observationTo = nil
                self.category = .other

                self.userData.selection = 1
                self.userData.renderMapObservations = true
            }, label: {
                Text("Save")
            }).disabled(self.latitude.isEmpty || self.longitude.isEmpty)
        )
    }
    
    func readPhoneLocation() {
        let latitude = geolocation.latitude
        let longitude = geolocation.longitude
        self.accuracy = String(Int(floor(geolocation_accuracy)))
        self.latitude = String(WGStoCHx(lat: latitude, lng: longitude))
        self.longitude = String(WGStoCHy(lat: latitude, lng: longitude))
        if let course = geolocationCourse {
            self.direction = String(format: "%d", course)
        }
        if let altitude = geolocationAltitude {
            self.elevation = String(format: "%d", altitude)
        }
        self.observedAt = Date()
        self.nearCatchmentLocations = self.findNearCatchmentLocations(userData: self.userData)
        self.gpsDevice = "iPhone"
    }
}

struct ObservationDetailFrom: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.presentationMode) var presentationMode
    @Binding var observationFrom: Set<Observation>
    @State var longitude: String
    @State var latitude: String

    
    var body: some View {
        List(userData.observations, id: \.self, selection: self.$observationFrom){ observation in
            ObservationRow(observation: observation, longitude: self.longitude, latitude: self.latitude)
        }
        .environment(\.editMode, .constant(EditMode.active))
    }
}


struct ObservationDetailTo: View {
    @EnvironmentObject var userData: UserData
    @Environment(\.presentationMode) var presentationMode
    @Binding var observationTo: Observation?
    @State var longitude: String
    @State var latitude: String
    var observations: [Observation] = []
    
    var body: some View {
        List(userData.observations, id: \.id){ observation in
            Button(action: {
                observationTo = observation
                self.presentationMode.wrappedValue.dismiss()
            }) {
                ObservationRow(observation: observation, longitude: self.longitude, latitude: self.latitude)
            }
        }.listStyle(PlainListStyle())
        .navigationBarTitle("Water flows TO this observation:", displayMode: .inline)
    }
}

func convertToIds(observations: Set<Observation>) -> String {
    var ret = ""
    observations.forEach { obs in
        if let anchorPoint = obs.anchorPoint {
            ret += String("\(anchorPoint) ")
        } else {
            ret += String("#\(obs.id) ")
        }
    }
    return ret
}

struct ObservationRow: View {
    var observation: Observation
    var longitude: String
    var latitude: String
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text("#\(observation.id)")
                    if let anchorPoint = observation.anchorPoint {
                        Text("\(anchorPoint)").font(.footnote)
                    } else {
                        Text("\(calculateDistance(p1: geolocation, p2: observation.location()))m away").font(.footnote)
                        if let elevation = observation.elevation {
                            if let elevation2 = geolocationAltitude {
                                if elevation > 0 && elevation2 > 0 {
                                    Text("\(elevation-elevation2)m higher").font(.footnote)
                                }
                            }
                        }
                    }
                    Spacer()
                    if let parent_id = observation.parent {
                        Image(systemName: "arrow.right.to.line.alt")
                        Text("#\(parent_id)")
                    }
                }
                HStack {
                    Image(systemName: "smallcircle.fill.circle").foregroundColor(observation.marker.color()).font(.footnote)
                    Text(observation.category.description())
                    Spacer()
                    Text("\(getFullDateFormatter().string(from: observation.observedAt))").font(.footnote)
                }
            }
        }
    }
}
