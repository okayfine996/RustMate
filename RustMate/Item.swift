//
//  Item.swift
//  RustMate
//
//  Created by Fine Ke on 31/12/2025.
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
