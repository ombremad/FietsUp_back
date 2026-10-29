@testable import FietsUp_back
import VaporTesting
import Testing

@Suite("Pagination Tests")
struct PaginationTests {
  @Test("Page count rounds up")
  func pageCountRoundsUp() {
    #expect(PageMetadata(page: 1, per: 10, total: 21).pageCount == 3)
    #expect(PageMetadata(page: 1, per: 10, total: 20).pageCount == 2)
  }

  @Test("The first page has no previous page")
  func firstPage() {
    let metadata = PageMetadata(page: 1, per: 10, total: 21)
    #expect(metadata.previousPage == nil)
    #expect(metadata.nextPage == 2)
  }

  @Test("The last page has no next page")
  func lastPage() {
    let metadata = PageMetadata(page: 3, per: 10, total: 21)
    #expect(metadata.previousPage == 2)
    #expect(metadata.nextPage == nil)
  }

  @Test("An empty result has no pages")
  func emptyResult() {
    let metadata = PageMetadata(page: 1, per: 10, total: 0)
    #expect(metadata.pageCount == 0)
    #expect(metadata.previousPage == nil)
    #expect(metadata.nextPage == nil)
  }
}
