import Foundation

/// Utility for computing age from a birth date.
enum AgeCalculator {
    /// Returns the number of fully completed years (floored) between the given birth date
    /// and the current device date.
    static func age(from birthDate: Date) -> Int {
        let components = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
        return components.year ?? 0
    }
}
