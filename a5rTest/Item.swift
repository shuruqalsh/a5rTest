//
//  Item.swift
//  a5rTest
//
//  Created by shuruq alshammari on 26/08/1446 AH.
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
