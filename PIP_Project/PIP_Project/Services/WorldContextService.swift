
import Foundation

// Service responsible for capturing the automatic World Context (w)
class WorldContextService {
    static let shared = WorldContextService()
    
    private init() {}
    
    func getCurrentTimeContext() -> (dayPhase: DayPhase, weekday: Int, isHoliday: Bool, timeZoneIdentifier: String) {
        let now = Date()
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now) // 1=Sun, ..., 7=Sat
        
        // Determine DayPhase
        let phase: DayPhase
        switch hour {
        case 0..<5: phase = .deepNight
        case 5..<12: phase = .morning
        case 12..<18: phase = .afternoon
        default: phase = .night // 18-24
        }
        
        // Simple holiday logic (Weekend check)
        // This should be enhanced with actual calendar logic in the future
        let isWeekend = weekday == 1 || weekday == 7
        
        return (
            dayPhase: phase,
            weekday: weekday,
            isHoliday: isWeekend,
            timeZoneIdentifier: timeZone.identifier
        )
    }
    
    /// Returns current location category
    /// This is a placeholder that would normally use CoreLocation
    func getCurrentLocation() -> LocationCategory {
        return .unknown
    }
    
    /// Returns current weather condition
    /// This is a placeholder that would normally use WeatherKit or OpenMeteo
    func getCurrentWeather() -> WeatherCondition {
        return .unknown
    }
}
