//
//  Item.swift
//  PraxisEn
//
//  Created by Akinalp Fidan on 10.11.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
