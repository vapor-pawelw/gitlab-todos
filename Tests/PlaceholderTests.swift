import Testing

@Suite("Placeholder")
struct PlaceholderTests {
    @Test("build sanity")
    func buildSanity() {
        #expect(1 + 1 == 2)
    }
}
