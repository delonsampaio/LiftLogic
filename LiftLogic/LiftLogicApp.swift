import SwiftUI

// App entry point.
@main
struct LiftLogicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}
