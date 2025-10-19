//
//  AIDrinkAnalysisClient.swift
//  WaterTracker
//
//  Created by Jackson  on 11/06/2025.
//

import UIKit
import SwiftUI
import OpenAI

struct DrinkAnalysisResult {
    let amount: Double
    let unit: WaterUnit
    let drink: Drink
}

final class AIDrinkAnalysisClient: ObservableObject {
    @Published var isAnalyzing = false

    
    func analyzeWeatherForHydration(weatherData: WeatherRecommendation) async throws -> String {
        await MainActor.run {
            isAnalyzing = true
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        let apiKey = RemoteConfigService.shared.string(for: .openAIApiKey)
        let openAI = OpenAI(apiToken: apiKey)
        
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        let systemPrompt = """
        You are a hydration expert AI assistant. Analyze weather data and provide personalized, encouraging hydration advice.
        
        Guidelines:
        - Be conversational and friendly
        - Explain the science behind your recommendations
        - Use emojis appropriately
        - Keep responses concise (2-3 sentences)
        - Focus on practical advice
        - Consider temperature, humidity, UV index, and weather conditions
        - IMPORTANT: Respond ONLY in \(systemLanguage) language
        - Use natural, native-level language for \(systemLanguage)
        - Max amount of symbols is 200
        """
        
        let weatherContext = """
        Current Weather Data:
        - Temperature: \(Int(weatherData.currentTemperature))°C
        - Humidity: \(Int(weatherData.humidity * 100))%
        - UV Index: \(weatherData.uvIndex)
        - Weather Condition: \(weatherData.condition.description)
        - Additional Water Needed: \(weatherData.recommendation.additionalWaterMl)ml
        - Weather Factors: \(weatherData.recommendation.factors.joined(separator: ", "))
        """
        
        let messages: [ChatQuery.ChatCompletionMessageParam] = [
            .system(.init(content: .textContent(systemPrompt))),
            .user(.init(content: .string(weatherContext)))
        ]

        let query = ChatQuery(
            messages: messages,
            model: .gpt4_o_mini
        )
        
        let result = try await openAI.chats(query: query)
        
        guard let content = result.choices.first?.message.content else {
            throw DrinkAnalysisError.analysisError("Failed to generate AI analysis")
        }
        
        return content
    }
    
    func analyzeSleepForHydration(sleepData: SleepRecommendation, waterData: [WaterPortion]) async throws -> String {
        await MainActor.run {
            isAnalyzing = true
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        let apiKey = RemoteConfigService.shared.string(for: .openAIApiKey)
        let openAI = OpenAI(apiToken: apiKey)
        
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        let systemPrompt = """
        You are a sleep and hydration expert AI assistant. Analyze sleep data and water intake patterns to provide personalized, evidence-based hydration recommendations.
        
        Guidelines:
        - Be conversational and encouraging
        - Reference scientific research on sleep-hydration connections
        - Use emojis appropriately
        - Keep responses concise (2-3 sentences)
        - Focus on practical, actionable advice
        - Consider sleep duration, quality, stages, and timing
        - IMPORTANT: Respond ONLY in \(systemLanguage) language
        - Use natural, native-level language for \(systemLanguage)
        - Reference specific sleep metrics when relevant
        - Max amount of symbols is 200        
        """
        
        // Calculate water intake for context
        let totalWaterMl = waterData.reduce(0) { total, portion in
            // portion.amount is already in millilitres
            total + Int(portion.amount)
        }
        let avgDailyWater = totalWaterMl / max(1, Set(waterData.map { Calendar.current.startOfDay(for: $0.createDate) }).count)
        
        let sleepContext = """
        Sleep Analysis Data:
        - Sleep Duration: \(String(format: "%.1f", sleepData.sleepDurationHours)) hours
        - Sleep Quality Score: \(Int(sleepData.sleepQualityScore * 100))%
        - Deep Sleep: \(sleepData.deepSleepMinutes) minutes
        - REM Sleep: \(sleepData.remSleepMinutes) minutes
        - Bed Time: \(sleepData.bedTime?.formatted(date: .omitted, time: .shortened) ?? "Unknown")
        - Wake Time: \(sleepData.wakeTime?.formatted(date: .omitted, time: .shortened) ?? "Unknown")
        - Additional Water Recommended: \(sleepData.recommendation.additionalWaterMl)ml
        - Sleep Factors: \(sleepData.recommendation.factors.joined(separator: ", "))
        
        Recent Water Intake Context:
        - Average daily water intake (last week): \(avgDailyWater)ml
        - Total water intake (last week): \(totalWaterMl)ml
        """
        
        let messages: [ChatQuery.ChatCompletionMessageParam] = [
            .system(.init(content: .textContent(systemPrompt))),
            .user(.init(content: .string(sleepContext)))
        ]

        let query = ChatQuery(
            messages: messages,
            model: .gpt4_o_mini
        )
        
        let result = try await openAI.chats(query: query)
        
        guard let content = result.choices.first?.message.content else {
            throw DrinkAnalysisError.analysisError("Failed to generate sleep-hydration analysis")
        }
        
        return content
    }
    
    func analyzeDrink(image: UIImage, measurementUnits: WaterUnit) async throws -> DrinkAnalysisResult {
        await MainActor.run {
            isAnalyzing = true
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        // Resize and compress image
        let processedImage = processImage(image)
        
        guard let imageData = processedImage.jpegData(compressionQuality: 0.6) else {
            throw DrinkAnalysisError.imageProcessingFailed
        }
        
        let apiKey = RemoteConfigService.shared.string(for: .openAIApiKey)
        let openAI = OpenAI(apiToken: apiKey)
        
        let systemPrompt = createSystemPrompt(measurementUnits: measurementUnits)
        
        let messages: [ChatQuery.ChatCompletionMessageParam] = [
            .system(.init(content: .textContent(systemPrompt))),
            .user(.init(content: .contentParts([.image(.init(imageUrl: .init(imageData: imageData, detail: .auto)))])))
        ]
        
        let chatResult = try await openAI.chats(
            query: .init(messages: messages, model: .gpt4_o_mini)
        )
        
        let response: DrinkAnalysisResponse = try extractResponse(from: chatResult)
        
        return DrinkAnalysisResult(
            amount: response.amount,
            unit: measurementUnits,
            drink: response.drinkType
        )
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 1024, height: 1024)
        
        // Calculate aspect ratio to maintain proportions
        let aspectRatio = image.size.width / image.size.height
        var newSize = targetSize
        
        if aspectRatio > 1 {
            // Landscape
            newSize.height = targetSize.width / aspectRatio
        } else {
            // Portrait or square
            newSize.width = targetSize.height * aspectRatio
        }
        
        // Center the image
        let x = (targetSize.width - newSize.width) / 2
        let y = (targetSize.height - newSize.height) / 2
        let rect = CGRect(x: x, y: y, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    private func createSystemPrompt(measurementUnits: WaterUnit) -> String {
        let unitName = measurementUnits.shortName
        let language = Locale.current.localizedString(forIdentifier: Locale.current.identifier) ?? "English"
        
        return """
        As a hydration tracking assistant, analyze the drink in the image and determine the volume and type.
        
        If the image does not contain any drink, respond with: { "error": "No drink detected in image" }
        
        If the image contains a drink, respond with this JSON format:
        {
            "amount": <number>,
            "drink": "<drink_type>"
        }
        
        Guidelines:
        - Estimate the volume in \(unitName)
        - Be conservative with estimates - it's better to underestimate than overestimate
        - Common drink types: water, coffee, tea, milk, juice, soda, other
        - For containers, estimate based on typical serving sizes
        - Consider the container size relative to common objects in the image
        
        Language: \(language)
        """
    }
    
    private func removeJSONCodeBlock(from text: String) -> String {
        var cleanedText = text
        
        if cleanedText.hasPrefix("```json\n") {
            cleanedText.removeFirst("```json\n".count)
        }
        
        if cleanedText.hasSuffix("\n```") {
            cleanedText.removeLast("\n```".count)
        }
        
        return cleanedText
    }
    
    private func extractResponse<T: Codable>(from chatResult: ChatResult) throws -> T {
        guard let response = chatResult.choices.first?.message.content,
              let data = removeJSONCodeBlock(from: response).data(using: .utf8) else {
            throw DrinkAnalysisError.invalidResponse
        }
        
        if let analysis = try? JSONDecoder().decode(T.self, from: data) {
            return analysis
        } else if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            throw DrinkAnalysisError.analysisError(errorResponse.error)
        } else {
            throw DrinkAnalysisError.invalidResponse
        }
    }
}

enum DrinkAnalysisError: Error {
    case imageProcessingFailed
    case invalidResponse
    case analysisError(String)
}

struct DrinkAnalysisResponse: Codable {
    let amount: Double
    let drink: String
    
    var drinkType: Drink {
        switch drink.lowercased() {
        case "water": return .water
        case "coffee": return .coffee
        case "tea": return .tea
        case "milk": return .milk
        case "juice": return .juice
        case "soda": return .soda
        default: return .other
        }
    }
}

struct ErrorResponse: Codable {
    let error: String
}
