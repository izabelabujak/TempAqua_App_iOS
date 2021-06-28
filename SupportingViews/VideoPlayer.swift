//
//  VideoPlayer.swift
//  TempAqua
//

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
