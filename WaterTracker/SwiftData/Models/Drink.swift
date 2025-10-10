//
//  Drink.swift
//  WaterTracker
//
//  Created by Jackson  on 08/09/2025.
//

import SwiftData
import Foundation

@Model
final class WaterProgress {
    var date: Date // Always rounded to start of day
    var goalMl: Double // Goal in milliliters
    @Relationship(deleteRule: .cascade, inverse: \WaterPortion.waterProgress)
    var portions: [WaterPortion]
    
    init(
        date: Date,
        goalMl: Double
    ) {
        self.date = date.rounded()
        self.goalMl = goalMl
        self.portions = []
    }
    
    /// Total net hydration in ml (accounting for hydration factors)
    var totalConsumedMl: Double {
        portions.reduce(0) { sum, portion in
            sum + (portion.amount * portion.drink.hydrationFactor)
        }
    }
    
    /// Total raw consumption in ml (not accounting for hydration factors)
    var totalRawConsumedMl: Double {
        portions.reduce(0) { sum, portion in
            sum + portion.amount
        }
    }
    
    /// Progress percentage towards goal
    var progressPercentage: Double {
        guard goalMl > 0 else { return 0 }
        return min(100, max(0, (totalConsumedMl / goalMl) * 100))
    }
}

@Model
final class WaterPortion {
    var amount: Double // Always stored in millilitres
    var drink: Drink
    var createDate: Date
    var waterProgress: WaterProgress?

    init(
        amount: Double,
        drink: Drink = .water,
        createDate: Date,
        waterProgress: WaterProgress? = nil
    ) {
        self.amount = amount
        self.drink = drink
        self.createDate = createDate
        self.waterProgress = waterProgress
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
    
    /// Calories per 100ml for the drink
    var caloriesPer100ml: Double {
        switch self {
        // Zero or negligible calories
        case .water, .sparklingWater, .tea, .coffee:
            return 0
        // Milks
        case .milk:
            return 64 // Whole milk
        case .almondMilk:
            return 17 // Unsweetened
        case .oatMilk:
            return 47
        case .soyMilk:
            return 33
        case .coconutMilk:
            return 230 // Canned, full fat
        case .coffeeWithMilk:
            return 12 // With a splash of milk
        case .broth:
            return 15
        // Sugary drinks
        case .juice:
            return 45
        case .soda:
            return 42
        case .sportsdrink:
            return 25
        case .smoothie:
            return 60
        // Alcoholic drinks
        case .wine:
            return 85
        case .champagne:
            return 80
        case .beer:
            return 43
        case .strongAlcohol:
            return 250 // 40% ABV spirits
        case .energyShot:
            return 130
        case .other:
            return 0
        }
    }
    
    /// Sugars per 100ml for the drink (in grams)
    var sugarsPer100ml: Double {
        switch self {
        // Zero or negligible sugars
        case .water, .sparklingWater, .tea, .coffee, .broth:
            return 0
        // Milks
        case .milk:
            return 5 // Lactose
        case .almondMilk:
            return 0 // Unsweetened
        case .oatMilk:
            return 4
        case .soyMilk:
            return 1
        case .coconutMilk:
            return 3
        case .coffeeWithMilk:
            return 1
        // Sugary drinks
        case .juice:
            return 10
        case .soda:
            return 10.6
        case .sportsdrink:
            return 6
        case .smoothie:
            return 12
        // Alcoholic drinks
        case .wine:
            return 0.6 // Dry wine
        case .champagne:
            return 1.5
        case .beer:
            return 0 // Negligible
        case .strongAlcohol:
            return 0 // Pure spirits
        case .energyShot:
            return 27
        case .other:
            return 0
        }
    }
    
    /// Whether this drink has significant calories or sugars (for display purposes)
    var hasNutritionalInfo: Bool {
        return caloriesPer100ml > 0 || sugarsPer100ml > 0
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
            return String(localized: "Fluid ounces (fl oz)")
        case .millilitres:
            return String(localized: "Milliliters (ml)")
        }
    }
    
    var shortName: String {
        switch self {
        case .ounces:
            return String(localized: "fl oz")
        case .millilitres:
            return String(localized: "ml")
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
