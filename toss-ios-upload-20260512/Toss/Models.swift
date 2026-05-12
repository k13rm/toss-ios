import Foundation

struct TossItem: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let name: String
    let reason: String
    let keepScore: Int
    let category: String
}

let sampleItems = [
    TossItem(emoji: "👟", name: "Old running shoes", reason: "Worn soles, duplicate pair, low resale value.", keepScore: 28, category: "Closet"),
    TossItem(emoji: "🔌", name: "Mystery cable", reason: "No matching device found. Low future-use confidence.", keepScore: 12, category: "Drawer"),
    TossItem(emoji: "📚", name: "Expired manuals", reason: "Digital copies are easy to find. Paper stack can go.", keepScore: 18, category: "Office"),
    TossItem(emoji: "🧥", name: "Winter jacket", reason: "Still useful, good condition, seasonal item.", keepScore: 82, category: "Closet"),
    TossItem(emoji: "🎧", name: "Backup earbuds", reason: "Compact, working, and useful when your main pair dies.", keepScore: 71, category: "Tech")
]

let tossPhrases = [
    "Tossed",
    "Space reclaimed",
    "Clutter cleared",
    "Gone from the pile"
]

let keepPhrases = [
    "Kept",
    "Still earning its spot",
    "Keeper",
    "Saved with purpose"
]

let donatePhrases = [
    "Donated",
    "Ready for a new home",
    "Passed along",
    "Good deed sorted"
]
