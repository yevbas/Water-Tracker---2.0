//
//  Computing.swift
//  PlateAI
//
//  Created by Jackson  on 21/08/2025.
//

import Foundation

enum ActivitySelectionMap {
    private static let options: [(label: String, bucket: String)] = [
        (String(localized: "Sedentary (little or no exercise)"), "sedentary"),
        (String(localized: "Light (1–3 days/week)"),             "light"),
        (String(localized: "Moderate (3–5 days/week)"),          "moderate"),
        (String(localized: "Very (6–7 days/week)"),              "very"),
        (String(localized: "Extra (physical job + training)"),   "extra")
    ]

    static func bucket(from answer: String?) -> String? {
        guard let answer = answer else { return nil }
        if let exact = options.first(where: { $0.label == answer }) {
            return exact.bucket
        }
        let low = answer.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        if low.contains("sedentary") { return "sedentary" }
        if low.contains("light") { return "light" }
        if low.contains("moderate") { return "moderate" }
        if low.contains("very") { return "very" }
        if low.contains("extra") || low.contains("physical") { return "extra" }
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

enum Gender: String {
    case male
    case female
    case other
}

struct UserMetrics {
    let gender: Gender
    let heightCm: Double
    let weightKg: Double
    let ageYears: Int
    let activityBucket: String
    let climate: String

    init?(answers: [String: MetricView.Answer]) {
        guard let gender = Gender(rawValue: answers["gender"]?.value ?? ""),
              let h = extractNumber(answers["height"]?.value),
              let w = extractNumber(answers["weight"]?.value),
              let a = extractInt(answers["age"]?.value) else {
            return nil
        }
        self.gender = gender
        self.heightCm = h
        self.weightKg = w
        self.ageYears = a
        self.activityBucket = ActivitySelectionMap.bucket(from: answers["activity-factor"]?.value) ?? "moderate"
        self.climate = (answers["climate"]?.value ?? "temperate").lowercased()
    }
}

struct PlanPreviewModel {
    let waterMl: Int
    let waterAmount: Double
    let waterUnit: WaterUnit
    let cups: Int
    let expectedDate: Date
    
    init(waterMl: Int, waterUnit: WaterUnit, cups: Int, expectedDate: Date) {
        self.waterMl = waterMl
        self.waterUnit = waterUnit
        self.waterAmount = WaterUnit.millilitres.convertTo(waterUnit, amount: Double(waterMl))
        self.cups = cups
        self.expectedDate = expectedDate
    }
}

enum WaterPlanner {
    struct Tuning {
        static let mlPerKg: Double = 35.0      // base daily water per kg bodyweight
        static let cupSizeMl: Double = 240.0   // 8 oz cup
        static let roundStepMl: Double = 50.0
    }

    static func activityBonus(bucket: String) -> Double {
        switch bucket {
        case "sedentary": return 0
        case "light": return 350
        case "moderate": return 700
        case "very": return 1000
        case "extra": return 1200
        default: return 350
        }
    }

    static func climateBonus(climate: String) -> Double {
        if climate.contains("hot") { return 500 }
        if climate.contains("temperate") { return 250 }
        return 0 // cool
    }

    static func roundMl(_ x: Double) -> Int {
        Int((x / Tuning.roundStepMl).rounded() * Tuning.roundStepMl)
    }

    static func plan(for m: UserMetrics, unit: WaterUnit = .millilitres) -> PlanPreviewModel {
        let base = m.weightKg * Tuning.mlPerKg
        let bonus = activityBonus(bucket: m.activityBucket) + climateBonus(climate: m.climate)
        let totalMl = max(1200, base + bonus)
        let ml = roundMl(totalMl)
        let cups = Int((Double(ml) / Tuning.cupSizeMl).rounded())
        return PlanPreviewModel(
            waterMl: ml,
            waterUnit: unit,
            cups: cups,
            expectedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )
    }
}
