import Foundation
import Testing
@testable import LiftLogic

@Suite("DocsParity")
struct DocsParityTests {
    private var docsIndexHTML: String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        // LiftLogicTests/DocsParityTests.swift -> repo root is one directory up
        let repoRoot = testFileURL.deletingLastPathComponent().deletingLastPathComponent()
        let docsURL = repoRoot.appendingPathComponent("docs/index.html")
        return (try? String(contentsOf: docsURL, encoding: .utf8)) ?? ""
    }

    @Test func everyFAQQuestionAppearsInDocsIndexHTML() {
        let html = docsIndexHTML
        #expect(!html.isEmpty, "docs/index.html should be readable from the test file's location")
        for question in HelpView.allFAQQuestions {
            #expect(html.contains(question), "Missing from docs/index.html: \(question)")
        }
    }

    @Test func htmlHasNoStaleFAQEntriesBeyondSwiftSource() {
        let html = docsIndexHTML
        let htmlFAQCount = html.components(separatedBy: "<summary>").count - 1
        let swiftCount = HelpView.allFAQQuestions.count
        #expect(htmlFAQCount == swiftCount,
                 "docs/index.html has \(htmlFAQCount) FAQ entries but HelpView.allFAQQuestions has \(swiftCount) — an HTML-only entry may be stale")
    }
}
