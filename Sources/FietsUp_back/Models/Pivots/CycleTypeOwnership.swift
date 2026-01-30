import Fluent
import struct Foundation.UUID

final class CycleTypeOwnership: Model, @unchecked Sendable {
    static let schema = "cycle_type_ownership"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_cycle_type") var cycleType: CycleType

    init() { }
}
