//
//  Untitled.swift
//  WeatherAppDemo
//
//  Created by work on 2025/2/26.
//
import Foundation

struct HourlyData: Codable {
    let time: [String]
    let temperature2M: [Double]
    
    // 处理 JSON key 与属性名不一致的问题
    enum CodingKeys: String, CodingKey {
        case time
        case temperature2M = "temperature_2m"
    }
}
struct WeatherData: Codable {
    let latitude: Double
    let longitude: Double
    let hourly: HourlyData
}
