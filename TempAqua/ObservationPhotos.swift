//
//  PhotoPicker.swift
//  TempAqua
//

import Foundation
import SwiftUI
import os
// import this due to a problem when using video camara:
// https://stackoverflow.com/questions/3690920/iphone-video-recording-cameracapturemode-1-not-available-because-mediatypes-do
import MobileCoreServices

struct ObservationPhotos: View {
    @Binding var multimedia: [ObservationMultimedia]
    @State var showCaptureImageView: Bool = false
    @State var currentlyDisplayedImage: ObservationMultimedia?

    var body: some View {
        VStack {
            if self.currentlyDisplayedImage?.format == "jpg" {
                self.currentlyDisplayedImage?.image().resizable()
                    .aspectRatio(self.currentlyDisplayedImage?.aspectRatio(), contentMode: .fit)
                    .frame(alignment: .center)
            } else {
                PlayerView(video: self.currentlyDisplayedImage!)
           }
            Spacer()
            Button(action: {
                for (i,m) in self.multimedia.enumerated() {
                    if m == self.currentlyDisplayedImage {
                        self.multimedia.remove(at: i)
                    }
                }
            }) {
                Text("Remove")
            }.frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.red)
                .cornerRadius(10)
                .padding(10)
        }.navigationBarTitle("Photo gallery").padding()
    }
}
