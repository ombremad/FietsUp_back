import Fluent
import struct Foundation.UUID

final class CycleColorOwnership: Model, @unchecked Sendable {
    static let schema = "cycle_color_ownership"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_cycle_color") var cycleColor: CycleColor

    init() { }
}
