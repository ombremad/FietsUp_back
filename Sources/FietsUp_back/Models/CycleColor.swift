import Fluent
import struct Foundation.UUID

final class CycleColor: Model, @unchecked Sendable {
    static let schema = "cycle_colors"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    @Field(key: "color") var color: String
    
    @Children(for: \.$cycleColor) var users: [User]
    
    @Siblings(through: CycleColorOwnership.self, from: \.$cycleColor, to: \.$user) var owners: [User]

    init() { }
}
