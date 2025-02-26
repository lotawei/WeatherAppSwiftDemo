//
//  Untitled.swift
//  WeatherAppSwiftDemo
//
//  Created by work on 2025/2/26.
//

import DGCharts



final class WeatherChartView: LineChartView, LayoutConfigurable {
    
    func setupConstraints() {
        guard let superview else { return }
        
        NSLayoutConstraint.activate([
            centerYAnchor.constraint(equalTo: superview.centerYAnchor, constant:0),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0),
            heightAnchor.constraint(equalTo: superview.heightAnchor, multiplier: 0.5)
        ])
    }

}

final class TimeAxisFormatter: NSObject, AxisValueFormatter {
    private let dateFormatter: DateFormatter
    
    init(dateFormat: String) {
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
    }
    
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return DateFormatter.formatTimestampToDate(timestamp: value,dateformat: self.dateFormatter.dateFormat)
    }
  

}
