import Fluent
import struct Foundation.UUID

final class CycleDecorationOwnership: Model, @unchecked Sendable {
    static let schema = "cycle_decoration_ownership"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_cycle_decoration") var cycleDecoration: CycleDecoration

    init() { }
}
