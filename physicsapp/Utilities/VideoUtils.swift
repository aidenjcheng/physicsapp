//
//  VideoUtils.swift
//  physicsapp
//
//  Created by Michelle on 12/14/25.
//

import Foundation
import AVFoundation

struct VideoUtils {
    // Get the FPS of a video from its URL
    static func getVideoFPS(from url: URL) -> Float? {
        let asset = AVAsset(url: url)
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        
        // Get the nominal frame rate
        let fps = videoTrack.nominalFrameRate
        return fps > 0 ? fps : nil
    }
    
    // Static function that can be called from VideoTimestampView
    static func saveVideoDataToDocuments(_ data: Data) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return nil
        }

        let fileName = UUID().uuidString + ".mov"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            // Remove file if it already exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }

            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving video to documents: \(error)")
            return nil
        }
    }
}
