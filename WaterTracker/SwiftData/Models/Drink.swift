//
//  Drink.swift
//  WaterTracker
//
//  Created by Jackson  on 08/09/2025.
//

import SwiftData
import Foundation

@Model
final class WaterPortion {
    var amount: Double
    var unit: WaterUnit
    var drink: Drink
    var createDate: Date

    init(amount: Double, unit: WaterUnit = .millilitres, drink: Drink = .water, createDate: Date) {
        self.amount = amount
        self.unit = unit
        self.drink = drink
        self.createDate = createDate
    }
}

enum Drink: String, Codable, Equatable, Hashable, CaseIterable {
    case water
    case coffee
    case tea
    case milk
    case juice
    case soda
    case other

    var title: String {
        return switch self {
        case .water: String(localized: "Water")
        case .coffee: String(localized: "Coffee")
        case .tea: String(localized: "Tea")
        case .milk: String(localized: "Milk")
        case .juice: String(localized: "Juice")
        case .soda: String(localized: "Soda")
        case .other: String(localized: "Other")
        }
    }

    var emoji: String {
        return switch self {
        case .water: "💧"
        case .coffee: "☕️"
        case .tea: "🍵"
        case .milk: "🥛"
        case .juice: "🧃"
        case .soda: "🥤"
        case .other: "🔍"
        }
    }
}

enum WaterUnit: Codable, Equatable {
    case ounces
    case millilitres
}
