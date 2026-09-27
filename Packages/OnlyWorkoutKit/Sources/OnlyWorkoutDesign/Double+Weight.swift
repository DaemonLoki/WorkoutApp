import Foundation

extension Double {
    /// Weight as the user reads it, e.g. "62.5 kg" (kg only, README §2).
    public var kilograms: String {
        Measurement(value: self, unit: UnitMass.kilograms).formatted(
            .measurement(
                width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...2))))
    }

    /// Weight without the unit, e.g. "62.5".
    public var weightNumber: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }

    /// Signed weight change, e.g. "+7.5 kg".
    public var kilogramsChange: String {
        (self > 0 ? "+" : "") + kilograms
    }
}
