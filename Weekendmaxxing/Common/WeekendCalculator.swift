import Foundation

enum WeekendStyle: String, CaseIterable, Identifiable {
    case fridayToSunday
    case saturdayToSunday

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fridayToSunday: return "Fri – Sun"
        case .saturdayToSunday: return "Sat – Sun"
        }
    }

    /// Gregorian weekday for the departure day (Sun = 1 ... Sat = 7).
    var departureWeekday: Int {
        switch self {
        case .fridayToSunday: return 6   // Friday
        case .saturdayToSunday: return 7 // Saturday
        }
    }

    /// Nights away (return offset in days from departure).
    var nights: Int {
        switch self {
        case .fridayToSunday: return 2
        case .saturdayToSunday: return 1
        }
    }
}

/// Produces the upcoming weekend windows used throughout the app.
enum WeekendCalculator {
    static func upcomingWeekends(
        count: Int = 6,
        from date: Date = Date(),
        style: WeekendStyle = .fridayToSunday,
        calendar: Calendar = AppTime.calendar
    ) -> [WeekendWindow] {
        let cal = calendar
        let today = cal.startOfDay(for: date)
        let todayWeekday = cal.component(.weekday, from: today)
        let daysUntilFirstDeparture = (style.departureWeekday - todayWeekday + 7) % 7

        guard let firstDeparture = cal.date(byAdding: .day, value: daysUntilFirstDeparture, to: today) else {
            return []
        }

        return (0..<count).compactMap { offset in
            guard let departure = cal.date(byAdding: .day, value: offset * 7, to: firstDeparture),
                  let returnDate = cal.date(byAdding: .day, value: style.nights, to: departure) else {
                return nil
            }
            return WeekendWindow(departureDate: departure, returnDate: returnDate)
        }
    }

    /// Every weekend window departing within roughly the next `months` months.
    /// Used by the "Best price" scan to compare fares across a wide horizon.
    static func upcomingWeekends(
        months: Int,
        from date: Date = Date(),
        style: WeekendStyle = .fridayToSunday,
        calendar: Calendar = AppTime.calendar
    ) -> [WeekendWindow] {
        guard let horizon = calendar.date(byAdding: .month, value: months, to: date) else {
            return upcomingWeekends(from: date, style: style, calendar: calendar)
        }
        let days = calendar.dateComponents([.day], from: date, to: horizon).day ?? 0
        let weeks = max(1, days / 7 + 1)
        return upcomingWeekends(count: weeks, from: date, style: style, calendar: calendar)
            .filter { $0.departureDate <= horizon }
    }
}
