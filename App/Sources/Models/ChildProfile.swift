import Foundation
import SwiftData

/// The hero of every story. Stored locally only — never leaves the device.
@Model
final class ChildProfile {
    var name: String
    var ageBandRaw: String
    /// A favorite animal, toy, or friend who joins the adventures.
    var companion: String
    /// Blanket, teddy, pacifier — woven into stories as a source of comfort.
    var comfortObject: String
    var createdAt: Date

    var ageBand: AgeBand {
        get { AgeBand(rawValue: ageBandRaw) ?? .little }
        set { ageBandRaw = newValue.rawValue }
    }

    init(name: String, ageBand: AgeBand, companion: String = "", comfortObject: String = "") {
        self.name = name
        self.ageBandRaw = ageBand.rawValue
        self.companion = companion
        self.comfortObject = comfortObject
        self.createdAt = .now
    }
}
