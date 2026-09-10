import Foundation

// MARK: - Weather Data

struct WeatherData: Codable {
    let temperature: Double   // °C
    let humidity: Int         // 0–100 %
    
    /// High humidity (>65%) means top notes (citrus, fruity, aquatic) project more strongly.
    var isHighHumidity: Bool { humidity > 65 }
    
    /// Moderate humidity (40–65%).
    var isModerateHumidity: Bool { humidity >= 40 && humidity <= 65 }
    
    /// Low humidity (<40%) — dry air, top notes evaporate faster.
    var isLowHumidity: Bool { humidity < 40 }
    
    /// Temperature in Fahrenheit for display purposes.
    var temperatureF: Double { (temperature * 9.0 / 5.0) + 32 }
}

// MARK: - Weather Service (Open-Meteo — free, no API key)

/// Fetches current weather using the Open-Meteo API.
/// Docs: https://open-meteo.com/en/docs
enum WeatherService {
    
    enum WeatherError: Error, LocalizedError {
        case invalidCoordinates
        case networkError(String)
        case decodingError
        
        var errorDescription: String? {
            switch self {
            case .invalidCoordinates: return "Invalid coordinates for weather lookup."
            case .networkError(let msg): return "Weather network error: \(msg)"
            case .decodingError: return "Failed to decode weather response."
            }
        }
    }
    
    /// Fetches current temperature (°C) and relative humidity (%) for given coordinates.
    static func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> WeatherData {
        guard latitude >= -90, latitude <= 90, longitude >= -180, longitude <= 180 else {
            throw WeatherError.invalidCoordinates
        }
        
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,relative_humidity_2m"
        
        guard let url = URL(string: urlString) else {
            throw WeatherError.networkError("Invalid URL")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw WeatherError.networkError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        // Parse the Open-Meteo response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let current = json["current"] as? [String: Any],
              let temp = current["temperature_2m"] as? Double,
              let humidity = current["relative_humidity_2m"] as? Int else {
            
            // Try Double humidity fallback (API sometimes returns Double)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current"] as? [String: Any],
               let temp = current["temperature_2m"] as? Double,
               let humidityDouble = current["relative_humidity_2m"] as? Double {
                return WeatherData(temperature: temp, humidity: Int(humidityDouble))
            }
            
            throw WeatherError.decodingError
        }
        
        return WeatherData(temperature: temp, humidity: humidity)
    }
}
