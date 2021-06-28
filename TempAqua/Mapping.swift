import SwiftUI
import CoreLocation


struct Mapping: View {
    @EnvironmentObject var userData: UserData
    
    @ViewBuilder
    var body: some View {
        NavigationView {
            ObservationDetail()
        }
    }
}
