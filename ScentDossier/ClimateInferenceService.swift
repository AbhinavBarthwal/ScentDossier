import Foundation
import CoreLocation

// MARK: - Climate Inference Errors

enum ClimateInferenceError: Error, LocalizedError {
    case inputTooShort
    case inputTooLong
    case noMatchFound
    case timeout

    var errorDescription: String? {
        switch self {
        case .inputTooShort:
            return "Location text must be at least 2 characters."
        case .inputTooLong:
            return "Location text must not exceed 100 characters."
        case .noMatchFound:
            return "Could not determine climate for the given location."
        case .timeout:
            return "Climate inference timed out."
        }
    }
}

// MARK: - Geocoding Result

struct GeocodingResult {
    let climate: ClimateClassification
    let resolvedLocationName: String
    let latitude: Double?
    let longitude: Double?
    var weather: WeatherData?
}

// MARK: - Protocol

protocol ClimateInferenceServiceProtocol {
    func inferClimate(from location: String) async throws -> ClimateClassification
    func inferClimateWithGeocoding(from location: String) async throws -> GeocodingResult
}

// MARK: - Implementation

struct ClimateInferenceService: ClimateInferenceServiceProtocol {

    /// Infers climate classification from a location string.
    /// First attempts geocoding via CLGeocoder, falls back to static keyword lookup.
    /// - Parameter location: A city/country name (2–100 characters).
    /// - Returns: The inferred `ClimateClassification`.
    /// - Throws: `ClimateInferenceError` for invalid input, no match, or timeout.
    func inferClimate(from location: String) async throws -> ClimateClassification {
        let result = try await inferClimateWithGeocoding(from: location)
        return result.climate
    }
    
    /// Infers climate classification with full geocoding result including resolved location name.
    /// First attempts geocoding via CLGeocoder, falls back to static keyword lookup.
    func inferClimateWithGeocoding(from location: String) async throws -> GeocodingResult {
        // Input validation
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            throw ClimateInferenceError.inputTooShort
        }
        guard trimmed.count <= 100 else {
            throw ClimateInferenceError.inputTooLong
        }

        // Wrap in a timeout of 5 seconds
        let result: GeocodingResult? = try await withThrowingTaskGroup(of: GeocodingResult?.self) { group in
            group.addTask {
                // First try geocoding
                if let geocodedResult = await Self.geocodeAndClassify(trimmed) {
                    return geocodedResult
                }
                // Fallback to static keyword lookup
                if let classification = Self.lookup(trimmed) {
                    return GeocodingResult(climate: classification, resolvedLocationName: "", latitude: nil, longitude: nil, weather: nil)
                }
                return nil
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                throw ClimateInferenceError.timeout
            }

            // Return the first successful result or propagate timeout
            if let first = try await group.next() {
                group.cancelAll()
                return first
            }
            return nil
        }

        guard let geocodingResult = result else {
            throw ClimateInferenceError.noMatchFound
        }
        
        // Fetch live weather if we have coordinates
        var finalResult = geocodingResult
        if let lat = geocodingResult.latitude, let lon = geocodingResult.longitude {
            do {
                let weather = try await WeatherService.fetchCurrentWeather(latitude: lat, longitude: lon)
                finalResult.weather = weather
            } catch {
                // Weather fetch failed — continue without it (non-critical)
                print("⚠️ Weather fetch failed: \(error.localizedDescription)")
            }
        }
        
        return finalResult
    }

    // MARK: - Geocoding-Based Climate Classification
    
    /// Geocodes a location string and classifies climate based on latitude/longitude.
    private static func geocodeAndClassify(_ location: String) async -> GeocodingResult? {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(location)
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else {
                return nil
            }
            
            let latitude = abs(coordinate.latitude)
            let longitude = coordinate.longitude
            
            // Build resolved location name from placemark
            let resolvedName = buildResolvedName(from: placemark)
            
            // Determine if location is coastal (rough heuristic)
            let isCoastal = checkIfCoastal(placemark: placemark)
            
            // Classify climate by latitude zones
            let climate = classifyByLatitude(
                absoluteLatitude: latitude,
                longitude: longitude,
                isCoastal: isCoastal
            )
            
            return GeocodingResult(
                climate: climate,
                resolvedLocationName: resolvedName,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                weather: nil
            )
        } catch {
            // Geocoding failed (no network, invalid location, etc.)
            return nil
        }
    }
    
    /// Builds a human-readable resolved location name from a CLPlacemark.
    private static func buildResolvedName(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let adminArea = placemark.administrativeArea {
            components.append(adminArea)
        }
        if let country = placemark.country {
            components.append(country)
        }
        return components.joined(separator: ", ")
    }
    
    /// Rough heuristic to determine if a location is coastal.
    /// Checks if the placemark is near an ocean based on available data.
    private static func checkIfCoastal(placemark: CLPlacemark) -> Bool {
        // If the placemark has ocean info or is on an island
        if let ocean = placemark.ocean, !ocean.isEmpty {
            return true
        }
        // Check if it's an island or inland water body nearby
        if let inlandWater = placemark.inlandWater, !inlandWater.isEmpty {
            return false // inland water isn't coastal
        }
        // Heuristic: some known coastal regions by country + admin area
        // For now, we'll use a simple approach — if the timezone contains "Pacific",
        // "Atlantic", "Indian", or the country is an island nation, consider coastal
        if let tz = placemark.timeZone?.identifier.lowercased() {
            if tz.contains("pacific") || tz.contains("atlantic") || tz.contains("indian") {
                return true
            }
        }
        // Default: not sure, assume not coastal
        return false
    }
    
    /// Classifies climate zone based on absolute latitude, longitude, and coastal proximity.
    /// - Latitude 0–23.5 (tropics): `.hot` or `.humid` for coastal
    /// - Latitude 23.5–35 (subtropical): `.hot` or `.humid` for coastal, `.dry` for inland
    /// - Latitude 35–55 (temperate zone): `.temperate`
    /// - Latitude 55–66.5 (subarctic): `.cold`
    /// - Latitude 66.5+ (arctic): `.cold`
    private static func classifyByLatitude(
        absoluteLatitude: Double,
        longitude: Double,
        isCoastal: Bool
    ) -> ClimateClassification {
        switch absoluteLatitude {
        case 0..<23.5:
            // Tropics
            if isCoastal {
                return .humid
            }
            return .hot
            
        case 23.5..<35:
            // Subtropical
            if isCoastal {
                return .humid
            }
            // Check for known dry regions (Middle East, North Africa, inland deserts)
            // Longitude roughly: Middle East 30-60E, North Africa -15 to 35E, US Southwest -120 to -105
            if (longitude > 20 && longitude < 65) {
                return .dry
            }
            if (longitude > -120 && longitude < -100 && absoluteLatitude > 30) {
                return .dry
            }
            return .hot
            
        case 35..<55:
            // Temperate zone
            return .temperate
            
        case 55..<66.5:
            // Subarctic
            return .cold
            
        default:
            // Arctic (66.5+)
            return .cold
        }
    }

    // MARK: - Static Keyword Fallback Lookup

    /// Performs a case-insensitive, partial-match (substring) lookup against known mappings.
    /// Used as a FALLBACK when geocoding fails (e.g., offline use).
    private static func lookup(_ location: String) -> ClimateClassification? {
        let lowercased = location.lowercased()

        for (keyword, classification) in Self.climateMappings {
            if lowercased.contains(keyword) {
                return classification
            }
        }
        return nil
    }

    // MARK: - Static Climate Mappings (Fallback)

    /// Dictionary of lowercase city/country keywords mapped to climate classifications.
    /// Contains 50+ entries covering major global locations.
    /// Used as fallback when geocoding is unavailable (offline use).
    static let climateMappings: [(String, ClimateClassification)] = [
        // Hot climate locations
        ("mumbai", .hot),
        ("delhi", .hot),
        ("chennai", .hot),
        ("dubai", .hot),
        ("abu dhabi", .hot),
        ("riyadh", .hot),
        ("cairo", .hot),
        ("phoenix", .hot),
        ("las vegas", .hot),
        ("miami", .hot),
        ("jeddah", .hot),
        ("karachi", .hot),
        ("lagos", .hot),
        ("doha", .hot),
        ("bahrain", .hot),
        ("kuwait", .hot),
        ("muscat", .hot),
        ("hyderabad", .hot),
        ("bangkok", .hot),
        ("havana", .hot),
        ("mexico city", .hot),
        ("marrakech", .hot),
        ("morocco", .hot),
        ("india", .hot),
        ("saudi arabia", .hot),

        // Cold climate locations
        ("moscow", .cold),
        ("helsinki", .cold),
        ("oslo", .cold),
        ("reykjavik", .cold),
        ("iceland", .cold),
        ("anchorage", .cold),
        ("alaska", .cold),
        ("stockholm", .cold),
        ("minnesota", .cold),
        ("winnipeg", .cold),
        ("siberia", .cold),
        ("finland", .cold),
        ("norway", .cold),
        ("murmansk", .cold),
        ("quebec", .cold),

        // Temperate climate locations
        ("london", .temperate),
        ("paris", .temperate),
        ("tokyo", .temperate),
        ("new york", .temperate),
        ("berlin", .temperate),
        ("madrid", .temperate),
        ("rome", .temperate),
        ("sydney", .temperate),
        ("melbourne", .temperate),
        ("san francisco", .temperate),
        ("toronto", .temperate),
        ("amsterdam", .temperate),
        ("brussels", .temperate),
        ("vienna", .temperate),
        ("prague", .temperate),
        ("seoul", .temperate),
        ("buenos aires", .temperate),
        ("lisbon", .temperate),
        ("chicago", .temperate),
        ("boston", .temperate),
        ("vancouver", .temperate),
        ("seattle", .temperate),
        ("portland", .temperate),
        ("dublin", .temperate),
        ("zurich", .temperate),
        ("geneva", .temperate),
        ("copenhagen", .temperate),
        ("united kingdom", .temperate),
        ("england", .temperate),
        ("japan", .temperate),
        ("france", .temperate),
        ("germany", .temperate),
        ("italy", .temperate),

        // Humid climate locations
        ("singapore", .humid),
        ("kuala lumpur", .humid),
        ("malaysia", .humid),
        ("jakarta", .humid),
        ("indonesia", .humid),
        ("manila", .humid),
        ("philippines", .humid),
        ("ho chi minh", .humid),
        ("vietnam", .humid),
        ("colombo", .humid),
        ("sri lanka", .humid),
        ("hong kong", .humid),
        ("taipei", .humid),
        ("taiwan", .humid),
        ("hawaii", .humid),
        ("new orleans", .humid),
        ("houston", .humid),
        ("amazon", .humid),
        ("brazil", .humid),

        // Dry climate locations
        ("denver", .dry),
        ("salt lake", .dry),
        ("tucson", .dry),
        ("albuquerque", .dry),
        ("sahara", .dry),
        ("gobi", .dry),
        ("tehran", .dry),
        ("iran", .dry),
        ("kabul", .dry),
        ("afghanistan", .dry),
        ("namibia", .dry),
        ("lima", .dry),
        ("peru", .dry),
        ("jordan", .dry),
        ("amman", .dry),
        ("iraq", .dry),
        ("baghdad", .dry),
    ]
}
