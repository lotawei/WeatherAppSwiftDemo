//
//  DateFormatter.swift
//  WeatherAppSwiftDemo
//
//  Created by work on 2025/2/26.
//
import Foundation
extension DateFormatter {
    static let isoCustom: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter
    }()
    static func formatTimestampToDate(timestamp: TimeInterval,dateformat:String) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = dateformat
        return formatter.string(from: date)
    }
}
