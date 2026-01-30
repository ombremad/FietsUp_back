import Fluent
import struct Foundation.UUID

final class CycleDecoration: Model, @unchecked Sendable {
    static let schema = "cycle_decorations"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    @Field(key: "file_link") var fileLink: String
    
    @Children(for: \.$cycleDecoration) var users: [User]
    
    @Siblings(through: CycleDecorationOwnership.self, from: \.$cycleDecoration, to: \.$user) var owners: [User]

    init() { }
}
