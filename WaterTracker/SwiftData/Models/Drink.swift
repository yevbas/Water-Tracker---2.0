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
    var dayDate: Date

    init(amount: Double, unit: WaterUnit = .millilitres, drink: Drink = .water, createDate: Date, dayDate: Date) {
        self.amount = amount
        self.unit = unit
        self.drink = drink
        self.createDate = createDate
        self.dayDate = dayDate
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

enum WaterUnit: Codable, Equatable, CaseIterable {
    case ounces
    case millilitres
    
    var displayName: String {
        switch self {
        case .ounces:
            return "Fluid ounces (fl oz)"
        case .millilitres:
            return "Milliliters (ml)"
        }
    }
    
    var shortName: String {
        switch self {
        case .ounces:
            return "fl oz"
        case .millilitres:
            return "ml"
        }
    }
    
    var conversionFactor: Double {
        switch self {
        case .ounces:
            return 29.5735 // 1 fl oz = 29.5735 ml
        case .millilitres:
            return 1.0
        }
    }
    
    static func fromString(_ string: String) -> WaterUnit {
        switch string {
        case "fl_oz", "fl oz", "ounces":
            return .ounces
        case "ml", "millilitres", "milliliters":
            return .millilitres
        default:
            return .millilitres // default to ml
        }
    }
    
    func convertTo(_ targetUnit: WaterUnit, amount: Double) -> Double {
        if self == targetUnit {
            return amount
        }
        
        // Convert to ml first, then to target unit
        let amountInMl = amount * self.conversionFactor
        return amountInMl / targetUnit.conversionFactor
    }
}
