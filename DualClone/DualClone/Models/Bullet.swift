//
//  Bullet.swift
//  DualClone
//
//  Created by Angel Terol on 13/5/24.
//

import Foundation

struct Bullet : Codable {
    var position: CGPoint
    var velocity: CGFloat
    var playerID: String
    
    mutating func mirrorBullet(for screenHeight: CGFloat) {
        velocity = -velocity
        position.y = screenHeight - position.y
    }
}

func deserializeBullet(_ data: Data) -> Bullet? {
    do {
        let decoder = JSONDecoder()
        let bullet = try decoder.decode(Bullet.self, from: data)
        return bullet
    } catch {
        print("Error on deserialize: \(error)")
        return nil
    }
}

func serializeBullet(_ bullet: Bullet) -> Data? {
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(bullet)
        return data
    } catch {
        print("Error on serialize: \(error)")
        return nil
    }
}
