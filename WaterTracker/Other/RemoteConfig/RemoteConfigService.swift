//
//  RemoteConfigService.swift
//  Weeshlist
//
//  Created by Jackson  on 12/04/2025.
//

import Foundation
import FirebaseRemoteConfig

protocol RemoteConfigServiceProtocol {
    var remoteConfig: RemoteConfig { get }

    func string(for key: RemoteConfigStringKey) -> String
    func bool(_ key: RemoteConfigBooleanKey) -> Bool
    func integer(_ key: RemoteConfigNumberKey) -> Int
    func model<T: Decodable>(_ key: RemoteConfigJsonKey) -> T?
    func fetchAndActivate() async
}

extension RemoteConfigServiceProtocol {
    var remoteConfig: RemoteConfig {
        RemoteConfig.remoteConfig()
    }

    func string(for key: RemoteConfigStringKey) -> String {
        remoteConfig.configValue(forKey: key.rawValue).stringValue
    }

    func bool(_ key: RemoteConfigBooleanKey) -> Bool {
        remoteConfig.configValue(forKey: key.rawValue).boolValue
    }

    func integer(_ key: RemoteConfigNumberKey) -> Int {
        Int(truncating: remoteConfig.configValue(forKey: key.rawValue).numberValue)
    }

    func model<T: Decodable>(_ key: RemoteConfigJsonKey) -> T? {
        // Assuming `remoteConfig.configValue(forKey:)` gives you a JSON object
        if let jsonValue = remoteConfig.configValue(forKey: key.rawValue).jsonValue {
            do {
                // Convert `jsonValue` to `Data`
                let data = try JSONSerialization.data(withJSONObject: jsonValue, options: [])

                // Decode the `Data` into your Decodable model
                let decodedModel = try JSONDecoder().decode(T.self, from: data)

                // Use the decoded model as needed
                return decodedModel
            } catch {
                // Handle any errors that might occur during serialization or decoding
                print("Failed to decode JSON: \(error)")
            }
        }
        return nil
    }

    func fetchAndActivate() async {
        // Configure settings (short interval in debug)
        #if DEBUG
        remoteConfig.configSettings = RemoteConfigSettings()
        remoteConfig.configSettings.minimumFetchInterval = 0
        #endif

        do {
            let _ = try await remoteConfig.fetch(withExpirationDuration: 0)
            let _ = try await remoteConfig.activate()
        } catch {
            // Even on failure, previously activated values remain available
            #if DEBUG
            print("Remote Config fetch/activate failed: \(error.localizedDescription)")
            #endif
        }
    }
}

class RemoteConfigService: RemoteConfigServiceProtocol {
    static let shared = RemoteConfigService()
}
