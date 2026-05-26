import OSLog

extension Logger {
    private static let subsystem = "com.DelonSampaio.LiftLogic"

    static let storeKit = Logger(subsystem: subsystem, category: "storekit")
    static let timer    = Logger(subsystem: subsystem, category: "timer")
    static let general  = Logger(subsystem: subsystem, category: "general")
}
