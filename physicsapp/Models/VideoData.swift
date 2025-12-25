//
//  VideoData.swift
//  physicsapp
//
//  Created by Michelle on 12/14/25.
//

import Foundation

struct VideoData: Identifiable, Codable, Equatable {
    let id: UUID
    let url: URL
    let name: String
    var duration: Double? // in seconds
    var startTime: Double? // start timestamp in seconds
    var endTime: Double? // end timestamp in seconds
    var measuredValue: Double? // user-entered measurement value (keeping for potential future use)
    
    init(url: URL, name: String, duration: Double? = nil, startTime: Double? = nil, endTime: Double? = nil, measuredValue: Double? = nil) {
        self.id = UUID()
        self.url = url
        self.name = name
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.measuredValue = measuredValue
    }
}
