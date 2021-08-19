//
//  CapturePhoto.swift
//  TempAqua
//

import Foundation
import AVFoundation
import SwiftUI
import os
// import this due to a problem when using video camara:
// https://stackoverflow.com/questions/3690920/iphone-video-recording-cameracapturemode-1-not-available-because-mediatypes-do
import MobileCoreServices


class CapturePhotoCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var multimedia: [ObservationMultimedia]
    @Binding var observationId: Int
    @Binding var presentationMode: PresentationMode

    init(observationId: Binding<Int>, multimedia: Binding<[ObservationMultimedia]>, presentationMode: Binding<PresentationMode>) {
        _multimedia = multimedia
        _observationId = observationId
        _presentationMode = presentationMode
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var currentlyDisplayedMultimedia: ObservationMultimedia?
        
        if let unwrapImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // Maximum allowed image size = 1.2MB
            // Maximum allowed dimension: 2200 px (scaled proportionally)
            let scaledImage = scale(image: unwrapImage, toLessThan: CGFloat(2200)) ?? unwrapImage

            // process photo
            var compressionQuality = 1.0
            while true {
                let data = scaledImage.jpegData(compressionQuality: CGFloat(compressionQuality))!
                let imgData = NSData(data: data)
                if imgData.count > 1200000 && compressionQuality > 0 {
                    compressionQuality -= 0.1
                } else {
                    let dataBase64 = data.base64EncodedData()
                    currentlyDisplayedMultimedia = ObservationMultimedia(surveyId: "", observationId: 0, takenAt: Date(), format: "jpg", data: dataBase64)
                    break
                }
            }
        } else if let unwrapVideoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL {
            let sem = DispatchSemaphore.init(value: 0)
            let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
            compressVideo(inputURL: unwrapVideoUrl as URL, outputURL: compressedURL) { exportSession in
                guard let session = exportSession else {
                    return
                }
                defer { sem.signal() }
                switch session.status {
                    case .unknown:
                        break
                    case .waiting:
                        break
                    case .exporting:
                        break
                    case .completed:
                        let data = try! Data(contentsOf: compressedURL.absoluteURL)
                        let dataBase64 = data.base64EncodedData()
                        currentlyDisplayedMultimedia = ObservationMultimedia(surveyId: "0", observationId: self.observationId, takenAt: Date(), format: "mp4", data: dataBase64)
                    case .failed:
                        break
                    case .cancelled:
                        break
                }
            }
            sem.wait()
        } else {
            os_log("Could not read photo/video")
            return
        }
        if var unwrapped = currentlyDisplayedMultimedia {            
            if observationId > 0 {
                // if we are editting existing observation, then automatically persist all changes
                // because people forgot to click the save button
                db.insert_multimedia(surveyId: "0", observationId: observationId, multimedia: unwrapped)
                unwrapped.persisted = true
            }
            multimedia.append(unwrapped)
        }
        self.presentationMode.dismiss()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.presentationMode.dismiss()
    }
}

func compressVideo(inputURL: URL,outputURL: URL, handler:@escaping (_ exportSession: AVAssetExportSession?) -> Void) {
    let urlAsset = AVURLAsset(url: inputURL, options: nil)
    guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) else {
        handler(nil)
        return
    }

    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    exportSession.exportAsynchronously {
        handler(exportSession)
    }
}
 

struct CapturePhotoView {
    @Binding var observationId: Int
    @Binding var multimedia: [ObservationMultimedia]
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> CapturePhotoCoordinator {
        return CapturePhotoCoordinator(observationId: $observationId, multimedia: $multimedia, presentationMode: presentationMode)
    }
}
 
extension CapturePhotoView: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CapturePhotoView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.showsCameraControls = true
        picker.videoMaximumDuration = 2
        picker.videoQuality = .type640x480
        picker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
        picker.cameraCaptureMode = .photo
        picker.modalPresentationStyle = .overFullScreen
        picker.imageExportPreset = .compatible
        picker.extendedLayoutIncludesOpaqueBars = true

        return picker
    }
}

private func scale(image originalImage: UIImage, toLessThan maxResolution: CGFloat) -> UIImage? {
    guard let imageReference = originalImage.cgImage else { return nil }

    let rotate90 = CGFloat.pi/2.0 // Radians
    let rotate180 = CGFloat.pi // Radians
    let rotate270 = 3.0*CGFloat.pi/2.0 // Radians

    let originalWidth = CGFloat(imageReference.width)
    let originalHeight = CGFloat(imageReference.height)
    let originalOrientation = originalImage.imageOrientation

    var newWidth = originalWidth
    var newHeight = originalHeight

    if originalWidth > maxResolution || originalHeight > maxResolution {
      let aspectRatio: CGFloat = originalWidth / originalHeight
      newWidth = aspectRatio > 1 ? maxResolution : maxResolution * aspectRatio
      newHeight = aspectRatio > 1 ? maxResolution / aspectRatio : maxResolution
    }

    let scaleRatio: CGFloat = newWidth / originalWidth
    var scale: CGAffineTransform = .init(scaleX: scaleRatio, y: -scaleRatio)
    scale = scale.translatedBy(x: 0.0, y: -originalHeight)

    var rotateAndMirror: CGAffineTransform

    switch originalOrientation {
    case .up:
      rotateAndMirror = .identity

    case .upMirrored:
      rotateAndMirror = .init(translationX: originalWidth, y: 0.0)
      rotateAndMirror = rotateAndMirror.scaledBy(x: -1.0, y: 1.0)

    case .down:
      rotateAndMirror = .init(translationX: originalWidth, y: originalHeight)
      rotateAndMirror = rotateAndMirror.rotated(by: rotate180 )

    case .downMirrored:
      rotateAndMirror = .init(translationX: 0.0, y: originalHeight)
      rotateAndMirror = rotateAndMirror.scaledBy(x: 1.0, y: -1.0)

    case .left:
      (newWidth, newHeight) = (newHeight, newWidth)
      rotateAndMirror = .init(translationX: 0.0, y: originalWidth)
      rotateAndMirror = rotateAndMirror.rotated(by: rotate270)
      scale = .init(scaleX: -scaleRatio, y: scaleRatio)
      scale = scale.translatedBy(x: -originalHeight, y: 0.0)

    case .leftMirrored:
      (newWidth, newHeight) = (newHeight, newWidth)
      rotateAndMirror = .init(translationX: originalHeight, y: originalWidth)
      rotateAndMirror = rotateAndMirror.scaledBy(x: -1.0, y: 1.0)
      rotateAndMirror = rotateAndMirror.rotated(by: rotate270)

    case .right:
      (newWidth, newHeight) = (newHeight, newWidth)
      rotateAndMirror = .init(translationX: originalHeight, y: 0.0)
      rotateAndMirror = rotateAndMirror.rotated(by: rotate90)
      scale = .init(scaleX: -scaleRatio, y: scaleRatio)
      scale = scale.translatedBy(x: -originalHeight, y: 0.0)

    case .rightMirrored:
      (newWidth, newHeight) = (newHeight, newWidth)
      rotateAndMirror = .init(scaleX: -1.0, y: 1.0)
      rotateAndMirror = rotateAndMirror.rotated(by: CGFloat.pi/2.0)
    @unknown default:
        print ("unknown value")
        return nil
    }

    UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    context.concatenate(scale)
    context.concatenate(rotateAndMirror)
    context.draw(imageReference, in: CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight))
    let copy = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return copy
}
