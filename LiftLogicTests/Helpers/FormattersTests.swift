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
        _ = Double.infinity.weightString
        _ = (-Double.infinity).weightString
    }

    @Test func weightStringDoesNotCrashOnNaN() {
        _ = Double.nan.weightString
    }

    @Test func weightStringDoesNotCrashOnAbsurdlyLargeValue() {
        _ = (1e300).weightString
    }

    @Test func weightStringPreciseDoesNotCrashOnAbsurdlyLargeValue() {
        _ = (1e300).weightStringPrecise
    }

    @Test func weightStringPreciseDoesNotCrashOnInfinity() {
        _ = Double.infinity.weightStringPrecise
    }

    @Test func weightStringPreciseDoesNotCrashOnNaN() {
        _ = Double.nan.weightStringPrecise
    }
}
