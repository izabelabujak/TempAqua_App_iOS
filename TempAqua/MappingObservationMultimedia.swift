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

struct MappingObservationMultimedia: View {
    @Binding var multimedia: [ObservationMultimedia]
    @State var showCaptureImageView: Bool = false
    @State var currentlyDisplayedImage: ObservationMultimedia?
    @EnvironmentObject var userData: UserData

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
                        db.deleteObservationMultimediaFile(surveyId: "0", observationId: m.observationId, takenAt: m.takenAt)
                        for (i2,observation) in self.userData.observations.enumerated() {
                            if observation.id == m.observationId {
                                for (i3,m2) in observation.multimedia.enumerated() {
                                    if m2 == self.currentlyDisplayedImage {
                                        self.userData.observations[i2].multimedia.remove(at: i3)
                                    }
                                }
                                
                            }
                        }
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

// code to display video

import UIKit
import AVKit
import AVFoundation
import os
import SwiftUI

struct PlayerView: UIViewRepresentable {
    let video: ObservationMultimedia
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(frame: .zero, video: self.video)
    }
}

class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    
    init(frame: CGRect, video: ObservationMultimedia) {
        super.init(frame: frame)

        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        url.appendPathComponent("video.mov") // or whatever extension the video is
        do {
            try video.rawData().write(to: url) // assuming video is of Data type
        } catch {
            os_log("Could not play video", type: .error)
            return
        }
        let player = AVPlayer(url: url)
        player.play()

        playerLayer.player = player
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
