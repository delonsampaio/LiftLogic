import Testing
@testable import LiftLogic

@Suite("AppReviewManager")
struct AppReviewManagerTests {
    @Test func requestsAtEachMilestone() {
        #expect(AppReviewManager.shouldRequestReview(atCount: 5))
        #expect(AppReviewManager.shouldRequestReview(atCount: 20))
        #expect(AppReviewManager.shouldRequestReview(atCount: 75))
    }

    @Test func doesNotRequestBetweenMilestones() {
        #expect(!AppReviewManager.shouldRequestReview(atCount: 0))
        #expect(!AppReviewManager.shouldRequestReview(atCount: 6))
        #expect(!AppReviewManager.shouldRequestReview(atCount: 21))
        #expect(!AppReviewManager.shouldRequestReview(atCount: 76))
    }
}
