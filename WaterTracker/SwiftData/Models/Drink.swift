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
    // Fully hydrating drinks
    case water
    case sparklingWater
    case tea
    case coffee
    case coffeeWithMilk
    case milk
    case almondMilk
    case oatMilk
    case soyMilk
    case coconutMilk
    case broth
    
    // Partially hydrating drinks (with extras)
    case juice
    case soda
    case sportsdrink
    case smoothie
    
    // Dehydrating drinks
    case wine
    case champagne
    case beer
    case strongAlcohol
    case energyShot
    
    case other

    var title: String {
        return switch self {
        case .water: String(localized: "Water")
        case .sparklingWater: String(localized: "Sparkling Water")
        case .coffee: String(localized: "Coffee")
        case .coffeeWithMilk: String(localized: "Coffee with Milk")
        case .tea: String(localized: "Tea")
        case .milk: String(localized: "Milk")
        case .almondMilk: String(localized: "Almond Milk")
        case .oatMilk: String(localized: "Oat Milk")
        case .soyMilk: String(localized: "Soy Milk")
        case .coconutMilk: String(localized: "Coconut Milk")
        case .broth: String(localized: "Broth")
        case .juice: String(localized: "Juice")
        case .soda: String(localized: "Soda")
        case .sportsdrink: String(localized: "Sports Drink")
        case .smoothie: String(localized: "Smoothie")
        case .wine: String(localized: "Wine")
        case .champagne: String(localized: "Champagne")
        case .beer: String(localized: "Beer")
        case .strongAlcohol: String(localized: "Strong Alcohol")
        case .energyShot: String(localized: "Energy Shot")
        case .other: String(localized: "Other")
        }
    }

    var emoji: String {
        return switch self {
        case .water: "💧"
        case .sparklingWater: "🫧"
        case .coffee: "☕️"
        case .coffeeWithMilk: "☕️"
        case .tea: "🍵"
        case .milk: "🥛"
        case .almondMilk: "🥛"
        case .oatMilk: "🥛"
        case .soyMilk: "🥛"
        case .coconutMilk: "🥥"
        case .broth: "🍲"
        case .juice: "🧃"
        case .soda: "🥤"
        case .sportsdrink: "⚡"
        case .smoothie: "🥤"
        case .wine: "🍷"
        case .champagne: "🥂"
        case .beer: "🍺"
        case .strongAlcohol: "🥃"
        case .energyShot: "💊"
        case .other: "🔍"
        }
    }
    
    /// Hydration category for this drink type
    var hydrationCategory: HydrationCategory {
        return switch self {
        case .water, .sparklingWater, .tea, .coffeeWithMilk, .milk, .almondMilk, .oatMilk, .soyMilk, .coconutMilk, .broth:
            .fullyHydrating
        case .coffee:
            .mildDiuretic
        case .juice, .soda, .sportsdrink, .smoothie:
            .partiallyHydrating
        case .wine, .champagne, .beer, .strongAlcohol, .energyShot:
            .dehydrating
        case .other:
            .fullyHydrating // Default to hydrating for unknown drinks
        }
    }
    
    /// Hydration factor: 1.0 = fully hydrating, 0.85 = coffee, 0.7 = partially hydrating, negative = dehydrating
    var hydrationFactor: Double {
        return switch self {
        // Fully hydrating drinks
        case .water, .sparklingWater, .tea, .coffeeWithMilk, .milk, .almondMilk, .oatMilk, .soyMilk, .coconutMilk, .broth, .other:
            1.0
        // Plain coffee - mild diuretic effect but still net positive hydration
        case .coffee:
            0.85
        // Partially hydrating drinks (with extras)
        case .juice, .soda, .sportsdrink, .smoothie:
            0.7
        // Dehydrating drinks
        case .wine, .champagne:
            -0.1 // Mild dehydration
        case .beer:
            0.1 // Very mild hydration (low alcohol content)
        case .strongAlcohol:
            -0.3 // Significant dehydration
        case .energyShot:
            -0.2 // Moderate dehydration due to high caffeine
        }
    }
    
    /// Whether this drink contains caffeine
    var containsCaffeine: Bool {
        switch self {
        case .coffee, .coffeeWithMilk, .tea, .energyShot:
            return true
        default:
            return false
        }
    }
    
    /// Whether this drink contains alcohol
    var containsAlcohol: Bool {
        switch self {
        case .wine, .champagne, .beer, .strongAlcohol:
            return true
        default:
            return false
        }
    }
}

/// Categories for drink hydration effects
enum HydrationCategory: String, Codable, CaseIterable {
    case fullyHydrating = "fully_hydrating"
    case mildDiuretic = "mild_diuretic"
    case partiallyHydrating = "partially_hydrating"
    case dehydrating = "dehydrating"
    
    var displayName: String {
        switch self {
        case .fullyHydrating:
            return String(localized: "Fully Hydrating")
        case .mildDiuretic:
            return String(localized: "Mild Diuretic")
        case .partiallyHydrating:
            return String(localized: "Partially Hydrating")
        case .dehydrating:
            return String(localized: "Dehydrating")
        }
    }
    
    var color: String {
        switch self {
        case .fullyHydrating:
            return "blue"
        case .mildDiuretic:
            return "teal"
        case .partiallyHydrating:
            return "orange"
        case .dehydrating:
            return "red"
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

    /// Convert amount from this unit to milliliters
    func toMilliliters(_ amount: Double) -> Double {
        return amount * self.conversionFactor
    }

    /// Convert amount from milliliters to this unit
    func fromMilliliters(_ amountInMl: Double) -> Double {
        return amountInMl / self.conversionFactor
    }
}

// MARK: - Convenience Extensions
extension WaterUnit {
    /// The conversion factor from fluid ounces to milliliters
    static let mlPerFlOz: Double = 29.5735

    /// Convert any amount to milliliters, given the source unit
    static func toMilliliters(_ amount: Double, from unit: WaterUnit) -> Double {
        return unit.toMilliliters(amount)
    }

    /// Convert milliliters to the target unit
    static func fromMilliliters(_ amountInMl: Double, to unit: WaterUnit) -> Double {
        return unit.fromMilliliters(amountInMl)
    }
}
