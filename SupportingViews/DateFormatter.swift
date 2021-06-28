//
//  DateFormatter.swift
//  TempAqua
//

import Foundation

func getTimeFormatter() -> DateFormatter {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm:ss"
    return timeFormatter
}

func getTimeHourMinutesFormatter() -> DateFormatter {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    return timeFormatter
}

func getShortDayFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM"
    return formatter
}

func getDayFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter
}

func getFullDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy HH:mm"
    return formatter
}

