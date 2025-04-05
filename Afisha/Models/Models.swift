//
//  Models.swift
//  Afisha
//
//  Created by Marjona Davlyatova on 02.04.2025.
//


import Foundation

struct Seat: Decodable {
    let seat_id: Int
    let sector: String?
    let row_num: String
    let place: String
    let top: Int
    let left: Int
    let booked_seats: Int
    let seat_view: String
    let seat_type: String?
    let object_type: String
    let object_description: String
    let object_title: String

    var price: Int {
        SeatTypeProvider.shared.price(for: seat_type ?? "")
    }
}

struct SeatType: Decodable {
    let ticket_id: Int
    let ticket_type: String
    let name: String
    let price: Int
    let seat_type: String
}

struct HallInfo: Decodable {
    let session_date: String
    let session_time: String
    let map_width: Int
    let map_height: Int
    let hall_name: String
    let merchant_id: Int
    let has_orzu: Bool
    let has_started: Bool
    let has_started_text: String
    let seats: [Seat]
    let seats_type: [SeatType]
}
