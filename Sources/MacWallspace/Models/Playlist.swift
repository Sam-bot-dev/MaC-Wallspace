import Foundation

public struct Playlist: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var itemIds: [UUID]
    public var dateCreated: Date
    public var isDefault: Bool
    public var cycleIntervalMinutes: Int // 0 = Manual, 5, 10, 15, 30, 60
    public var isShuffle: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        itemIds: [UUID] = [],
        dateCreated: Date = Date(),
        isDefault: Bool = false,
        cycleIntervalMinutes: Int = 0,
        isShuffle: Bool = false
    ) {
        self.id = id
        self.name = name
        self.itemIds = itemIds
        self.dateCreated = dateCreated
        self.isDefault = isDefault
        self.cycleIntervalMinutes = cycleIntervalMinutes
        self.isShuffle = isShuffle
    }
}
