//
//  SeatTypeProvider.swift
//  Afisha
//
//  Created by Marjona Davlyatova on 04.04.2025.
//
import UIKit

class SeatTypeProvider {
    static let shared = SeatTypeProvider()
    
    private var types: [SeatType] = []
    
    func configure(with seatTypes: [SeatType]) {
        types = seatTypes
    }
    
    func price(for type: String) -> Int {
        types.first(where: { $0.seat_type == type })?.price ?? 0
    }
    
    func color(for type: String) -> UIColor {
        switch type.uppercased() {
        case "VIP": return .systemPurple
        case "COMFORT": return .systemOrange
        case "STANDARD": return .systemIndigo
        default: return .lightGray
        }
    }
    
    func legendItems() -> [(String, Int)] {
        types.map { ($0.seat_type, $0.price) }
    }
}
