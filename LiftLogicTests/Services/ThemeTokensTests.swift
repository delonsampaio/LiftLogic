import Testing
import SwiftUI
@testable import LiftLogic

@Suite("AccentColorOption")
struct ThemeTokensTests {
    @Test func orangeMatchesThemeTokensAccentExactly() {
        #expect(AccentColorOption.orange.color == ThemeTokens.accent)
    }
    @Test func blueColorValue() {
        #expect(AccentColorOption.blue.color == Color(red: 0.20, green: 0.55, blue: 0.95))
    }
    @Test func tealColorValue() {
        #expect(AccentColorOption.teal.color == Color(red: 0.10, green: 0.75, blue: 0.70))
    }
    @Test func pinkColorValue() {
        #expect(AccentColorOption.pink.color == Color(red: 0.95, green: 0.30, blue: 0.55))
    }
    @Test func allCasesHasFourOptionsInOrder() {
        #expect(AccentColorOption.allCases == [.orange, .blue, .teal, .pink])
    }
    @Test func displayNamesAreHumanReadable() {
        #expect(AccentColorOption.orange.displayName == "Orange")
        #expect(AccentColorOption.blue.displayName == "Blue")
        #expect(AccentColorOption.teal.displayName == "Teal")
        #expect(AccentColorOption.pink.displayName == "Pink")
    }
    @Test func rawValueRoundTrips() {
        for option in AccentColorOption.allCases {
            #expect(AccentColorOption(rawValue: option.rawValue) == option)
        }
    }
}
