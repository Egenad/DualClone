//
//  Physics.swift
//  DualClone
//
//  Created by Angel Terol on 22/5/24.
//

import Foundation

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let spaceship: UInt32 = 0x1 << 0 // 1
    static let bullet: UInt32 = 0x1 << 1 // 2
}
