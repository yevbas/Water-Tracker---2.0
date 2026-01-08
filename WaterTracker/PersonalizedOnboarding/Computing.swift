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
        // Normalize and use word-boundary regex so "every" doesn't match "very"
        let s = answer.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        if s.range(of: #"\bsedentary\b"#, options: .regularExpression) != nil { return "sedentary" }
        if s.range(of: #"\blight\b"#,     options: .regularExpression) != nil { return "light" }
        if s.range(of: #"\bmoderate\b"#,  options: .regularExpression) != nil { return "moderate" }
        if s.range(of: #"\bvery\b"#,      options: .regularExpression) != nil { return "very" }
        if s.range(of: #"\bextra\b"#,     options: .regularExpression) != nil { return "extra" }
        if s.range(of: #"\bphysical\b"#,  options: .regularExpression) != nil { return "extra" }
        return nil
    }
}

enum WaterPlanner {
    struct Tuning {
        static let mlPerKg: Double = 30.0      // was 35.0
        static let cupSizeMl: Double = 240.0   // 8 oz cup (unchanged)
        static let roundStepMl: Double = 50.0  // (unchanged)
    }

    static func activityBonus(bucket: String) -> Double {
        switch bucket {
        case "sedentary": return 0
        case "light":     return 150   // was 350
        case "moderate":  return 350   // was 700
        case "very":      return 600   // was 1000
        case "extra":     return 800   // was 1200
        default:          return 350   // keep default aligned with "moderate"
        }
    }

    static func climateBonus(climate: String) -> Double {
        if climate.contains("hot")       { return 300 } // was 500
        if climate.contains("temperate") { return 150 } // was 250
        return 0 // cold (unchanged)
    }

    static func roundMl(_ x: Double) -> Int {
        Int((x / Tuning.roundStepMl).rounded() * Tuning.roundStepMl)
    }

    static func plan(for m: UserMetrics, unit: WaterUnit = .millilitres) -> PlanPreviewModel {
        let base = m.weightKg * Tuning.mlPerKg
        let bonus = activityBonus(bucket: m.activityBucket) + climateBonus(climate: m.climate)
        let totalMl = max(1200, base + bonus)           // keep existing lower bound
        let ml = roundMl(totalMl)

        // switch to floor to avoid inflating servings (was rounded())
        let cups = Int(floor(Double(ml) / Tuning.cupSizeMl))

        return PlanPreviewModel(
            waterMl: ml,
            waterUnit: unit,
            cups: cups,
            expectedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        )
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
