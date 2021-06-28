//
//  ObservationPhoto.swift
//  TempAqua
//

import SwiftUI

struct ObservationMultimedia: Hashable, Codable {
    var surveyId: String
    var observationId: Int
    var takenAt: Date
    var format: String = "jpg"
    var data: Data = Data()
    var persisted = true
    
    func image() -> Image {
        return Image(uiImage: self.uiImage())
    }
    
    func uiImage() -> UIImage {
        let dataDecoded: NSData  = NSData(base64Encoded: self.data)!
        let decodedimage: UIImage = UIImage(data: dataDecoded as Data)!
        
        return decodedimage
    }
    
    func aspectRatio() -> CGFloat {
        let image = self.uiImage();
        let size = image.size
        return size.width / size.height
   }
    
    // exclude content of the photo from serialization
    enum CodingKeys: String, CodingKey {
        case surveyId
        case observationId
        case takenAt
        case format
    }
    
    func base64encoded() -> String {
        return String(decoding: self.data, as: UTF8.self)
    }
    
    func rawData() -> Data {
        return Data(base64Encoded: self.data)!
    }
    
    func sizeInMb() -> Double {
        return Double(self.data.count / 1000000).rounded(toPlaces: 2)
    }
}
