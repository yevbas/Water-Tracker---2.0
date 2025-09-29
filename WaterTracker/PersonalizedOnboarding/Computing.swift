//
//  Computing.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import Foundation

enum ActivityFactorMap {

    private static let options: [(label: String, factor: Double)] = [
        (String(localized: "Sedentary (little or no exercise)"), 1.20),
        (String(localized: "Light (1–3 days/week)"),             1.375),
        (String(localized: "Moderate (3–5 days/week)"),          1.55),
        (String(localized: "Very (6–7 days/week)"),              1.725),
        (String(localized: "Extra (physical job + training)"),   1.90)
    ]

    static func factor(from answer: String?) -> Double? {
        guard let answer = answer else {
            return nil
        }

        if let exact = options.first(where: { $0.label == answer }) {
            return exact.factor
        }

        let low = answer.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        if low.contains("sedentary") {
            return 1.20
        }
        if low.contains("light") {
            return 1.375
        }
        if low.contains("moderate") {
            return 1.55
        }
        if low.contains("very") {
            return 1.725
        }
        if low.contains("extra") || low.contains("physical") {
            return 1.90
        }
        return nil
    }
}


// --- Parsing helpers (no typed-regex needed) ---
private func extractNumber(_ string: String?) -> Double? {
    guard let s = string,
          let r = s.range(of: #"[0-9]+(?:[.,][0-9]+)?"#, options: .regularExpression) else {
        return nil
    }
    return Double(s[r].replacingOccurrences(of: ",", with: "."))
}
private func extractInt(_ string: String?) -> Int? {
    guard let s = string else {
        return nil
    }
    let digits = s.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
    return Int(String(String.UnicodeScalarView(digits)))
}

enum Goal: String {
    case lose
    case maintain
    case gain
}

enum Gender: String {
    case male
    case female
    case other
}

struct UserMetrics {
    let goal: Goal
    let gender: Gender
    let heightCm: Double
    let weightKg: Double
    let ageYears: Int
    let weeklyChangeKg: Double
    let activityFactor: Double

    init?(answers: [String: MetricView.Answer]) {
        guard let goal = Goal(rawValue: answers["goal"]?.value ?? ""),
              let gender = Gender(rawValue: answers["gender"]?.value ?? ""),
              let h = extractNumber(answers["height"]?.value),
              let w = extractNumber(answers["weight"]?.value),
              let a = extractInt(answers["age"]?.value) else {
            return nil
        }
        self.goal = goal
        self.gender = gender
        self.heightCm = h
        self.weightKg = w
        self.ageYears = a
        self.weeklyChangeKg = extractNumber(answers["expected-weight-change"]?.value) ?? 0
        self.activityFactor = ActivityFactorMap.factor(from: answers["activity-factor"]?.value) ?? 1.55
    }
}

struct PlanPreviewModel {
    let calories: Int
    let proteinG: Int
    let fatG: Int
    let carbsG: Int
    let expectedDate: Date
}

enum NutritionPlanner {
    struct Tuning {
        static let minCalories = 1200.0
        static let carbFloorG  = 130.0
        static let maxDeficitFraction = 0.20   // ≤20% below TDEE
        static let maxSurplusFraction = 0.15   // ≤15% above TDEE
        static let roundStepG = 5.0
    }

    struct MacroPreset {
        let pGPerKg: Double
        let fGPerKg: Double
        let minPGPerKg: Double
        let minFGPerKg: Double
    }

    static func preset(for goal: Goal) -> MacroPreset {
        switch goal {
        case .lose:
            return .init(
                pGPerKg: 1.6,
                fGPerKg: 0.7,
                minPGPerKg: 1.4,
                minFGPerKg: 0.6
            )
        case .maintain:
            return .init(
                pGPerKg: 1.6,
                fGPerKg: 0.8,
                minPGPerKg: 1.2,
                minFGPerKg: 0.6
            )
        case .gain:
            return .init(
                pGPerKg: 1.8,
                fGPerKg: 0.8,
                minPGPerKg: 1.2,
                minFGPerKg: 0.6
            )
        }
    }

    static func bmr(_ w: Double,_ h: Double,_ age: Int,_ g: Gender) -> Double {
        let s = (g == .male) ? 5.0 : (g == .female ? -161.0 : -78.0)
        return 10 * w + 6.25 * h - 5 * Double(age) + s
    }

    static func tdee(bmr: Double, af: Double) -> Double {
        bmr * af
    }

    static func deltaPerDay(kgPerWeek: Double) -> Double {
        1100.0 * kgPerWeek
    }

    static func plan(for m: UserMetrics) -> PlanPreviewModel {
        let baseBMR  = bmr(m.weightKg, m.heightCm, m.ageYears, m.gender)
        let baseTDEE = tdee(bmr: baseBMR, af: m.activityFactor)
        let reqDelta = deltaPerDay(kgPerWeek: m.weeklyChangeKg)

        var target = baseTDEE
        switch m.goal {
        case .lose:
            let cap = Tuning.maxDeficitFraction * baseTDEE
            target = max(Tuning.minCalories, baseTDEE - min(reqDelta, cap))
        case .maintain:
            target = baseTDEE
        case .gain:
            let cap = Tuning.maxSurplusFraction * baseTDEE
            target = baseTDEE + min(reqDelta, cap)
        }

        let p = preset(for: m.goal)
        var protein = p.pGPerKg * m.weightKg
        var fat = p.fGPerKg * m.weightKg

        func carbsFrom(_ calories: Double, _ prot: Double, _ fat: Double) -> Double {
            max(0, (calories - (prot * 4 + fat * 9)) / 4)
        }
        let minP = p.minPGPerKg * m.weightKg
        let minF = p.minFGPerKg * m.weightKg

        var carbs = carbsFrom(target, protein, fat)

        if carbs < Tuning.carbFloorG {
            if fat > minF {
                fat = minF
                carbs = carbsFrom(target, protein, fat)
            }
            if carbs < Tuning.carbFloorG, protein > minP {
                protein = minP
                carbs = carbsFrom(target, protein, fat)
            }
            if carbs < Tuning.carbFloorG {
                carbs = Tuning.carbFloorG
                target = protein * 4 + fat * 9 + carbs * 4
            }
        }

        func roundG(_ x: Double) -> Int {
            Int((x / Tuning.roundStepG).rounded() * Tuning.roundStepG)
        }
        let P = roundG(protein)
        let F = roundG(fat)
        let C = roundG(carbs)
        let K = P * 4 + F * 9 + C * 4

        return .init(
            calories: K,
            proteinG: P,
            fatG: F,
            carbsG: C,
            expectedDate: Date()
        )
    }
}
