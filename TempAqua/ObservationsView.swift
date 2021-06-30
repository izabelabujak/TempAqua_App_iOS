//
//  LandmarkList.swift
//  TempAqua
//

import SwiftUI

struct ObservationsView: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var exportManager: ExportManager
    @State var isExportView = false    
    
    var body: some View {        
        NavigationView {
            List {
                ForEach(userData.observations, id: \.self) { observation in
                    NavigationLink(destination: ObservationDetail(observation: observation, userData: self.userData)) {
                        HStack {
                            VStack {
                                HStack {
                                    Text("#\(observation.id)")
                                    if let anchorPoint = observation.anchorPoint {
                                        Text("\(anchorPoint)")
                                    }
                                    Spacer()
                                    if let parent_id = observation.parent {
                                        Image(systemName: "arrow.right.to.line.alt")
                                        Text("#\(parent_id)")
                                    }
                                }
                                HStack {
                                    Image(systemName: "smallcircle.fill.circle").foregroundColor(observation.marker.color()).font(.footnote)
                                    Text(observation.category.description()).font(.footnote)
                                    Spacer()
                                    Text("\(getFullDateFormatter().string(from: observation.observedAt))").font(.footnote)
                                    
                                }
                            }
                        }
                    }
                }.onDelete(perform: delete)
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Observations", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                    self.isExportView.toggle()
                    userData.surveyExportObservations = Set(userData.observations)
                }, label: {
                    Image(systemName: "icloud.and.arrow.up")
                    Text("Export")
                }).disabled(userData.observations.isEmpty))
        }.sheet(isPresented: $isExportView) {
            SurveyExport(isExportView: self.$isExportView).environmentObject(self.userData).environmentObject(self.exportManager)
        }
    }
    
    func delete(at offsets: IndexSet) {
        offsets.forEach { (i) in
            let id = userData.observations[i].id
            db.deleteById(id: id)
        }
        userData.observations.remove(atOffsets: offsets)
        renderMapObservations = true
    }
}

struct ObservationList_Previews: PreviewProvider {
    static var previews: some View {
        ObservationsView().environmentObject(UserData())
    }
}
