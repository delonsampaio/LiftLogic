import Foundation
import Testing
@testable import LiftLogic

@Suite("Formatters")
struct FormattersTests {
    @Test func weightStringHandlesNormalWholeNumber() {
        #expect(225.0.weightString == "225")
    }

    @Test func weightStringHandlesNormalDecimal() {
        #expect(47.5.weightString == "47.5")
    }

    @Test func weightStringPreciseHandlesNormalWholeNumber() {
        #expect(225.0.weightStringPrecise == "225")
    }

    @Test func weightStringPreciseHandlesNormalDecimal() {
        #expect(47.5.weightStringPrecise == "47.50")
    }

    @Test func weightStringDoesNotCrashOnInfinity() {
        #expect(!Double.infinity.weightString.isEmpty)
        #expect(!(-Double.infinity).weightString.isEmpty)
    }

    @Test func weightStringDoesNotCrashOnNaN() {
        #expect(!Double.nan.weightString.isEmpty)
    }

    @Test func weightStringDoesNotCrashOnAbsurdlyLargeValue() {
        #expect(!(1e300).weightString.isEmpty)
    }

    @Test func weightStringPreciseDoesNotCrashOnAbsurdlyLargeValue() {
        #expect(!(1e300).weightStringPrecise.isEmpty)
    }

    @Test func weightStringPreciseDoesNotCrashOnInfinity() {
        #expect(!Double.infinity.weightStringPrecise.isEmpty)
    }

    @Test func weightStringPreciseDoesNotCrashOnNaN() {
        #expect(!Double.nan.weightStringPrecise.isEmpty)
    }

    @Test func weightStringJustUnderBoundaryUsesNormalFormatting() {
        let value = 1e15 - 1
        #expect(value.weightString == String(Int(value)))
    }

    @Test func weightStringAtBoundaryUsesFallbackFormatting() {
        #expect((1e15).weightString == String(format: "%.1f", 1e15))
    }
}
