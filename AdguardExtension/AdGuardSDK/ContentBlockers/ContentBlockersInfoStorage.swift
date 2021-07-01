/**
       This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
       Copyright © Adguard Software Limited. All rights reserved.
 
       Adguard for iOS is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.
 
       Adguard for iOS is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.
 
       You should have received a copy of the GNU General Public License
       along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

// MARK: - ContentBlockerType

public enum ContentBlockerType: Int, CaseIterable, Codable {
    case general
    case privacy
    case socialWidgetsAndAnnoyances
    case other
    case custom
    case security
    
    var affinity: Affinity {
        switch self {
        case .general: return .general
        case .privacy: return .privacy
        case .socialWidgetsAndAnnoyances: return .socialWidgetsAndAnnoyances
        case .other: return .other
        case .custom: return .custom
        case .security: return .security
        }
    }
}

// MARK: - ConverterResult

/**
 This struct is used to represent the convertation result of Converter lib.
 It is practically the same as **FiltersConverter.Result** but instead of storing JSON file string it stores JSON file URL.
 It is more convenient to use URLs because Content Blockers are waiting JSON URL with converted rules.
 */
public struct ConverterResult: Codable, Equatable {
    let contentBlockerType: ContentBlockerType // Content blocker type the result is related with
    let totalRules: Int // Total valis rules number, because some rules that we pass can be invalid
    let totalConverted: Int // The result number of rules with Content blockers limit of 'contentBlockerRulesLimit' rules
    let overlimit: Bool // Is true if totalRules is greater than 'contentBlockerRulesLimit' rules
    let jsonUrl: URL // URL where JSON with converted rules is stored 
}

// MARK: - ContentBlockersInfoStorage

protocol ContentBlockersInfoStorageProtocol: ResetableSyncProtocol {
    /* Returns all content blocker conversion results and JSONs urls */
    var allCbInfo: [ContentBlockerType: ConverterResult] { get }

    /* Saves filters convertion info and JSON file to storage */
    func save(cbInfo: FiltersConverter.Result) throws

    /* Saves filters convertion info and JSON files to storage */
    func save(cbInfos: [FiltersConverter.Result]) throws

    /* Loads filters convertion result and JSON file url for specified content blocker type */
    func getInfo(for cbType: ContentBlockerType) -> ConverterResult?
    
    /**
     Safari Content Blocker can return an error if we pass empty json
     So we just pass json with empty rule to avoid this error
     */
    func getEmptyRuleJsonUrl() throws -> URL
}

/* This class is responsible for managing JSON files for every content blocker */
final class ContentBlockersInfoStorage: ContentBlockersInfoStorageProtocol {
        
    // MARK: - Public properties
    
    var allCbInfo: [ContentBlockerType: ConverterResult] { userDefaultsStorage.allCbInfo }
    
    // MARK: - Private properties
    
    private let fileManager = FileManager.default
    
    // URL of directory where jsons for each content blocker will be stored
    private let jsonStorageUrl: URL
    private let userDefaultsStorage: UserDefaultsStorageProtocol
    
    // MARK: - Initialization
    
    init(jsonStorageUrl: URL, userDefaultsStorage: UserDefaultsStorageProtocol) throws {
        // We are trying to create directory if passed URL is not a valid directory
        if !jsonStorageUrl.isDirectory {
            try fileManager.createDirectory(at: jsonStorageUrl, withIntermediateDirectories: true, attributes: nil)
        }
        self.jsonStorageUrl = jsonStorageUrl
        self.userDefaultsStorage = userDefaultsStorage
    }
    
    // MARK: - Internal methods
    
    func save(cbInfo: FiltersConverter.Result) throws {
        let urlToSave = urlForJson(withType: cbInfo.type)
        try cbInfo.jsonString.write(to: urlToSave, atomically: true, encoding: .utf8)
        
        // Save filters convertion result
        let converterResult = ConverterResult(contentBlockerType: cbInfo.type,
                                              totalRules: cbInfo.totalRules,
                                              totalConverted: cbInfo.totalConverted,
                                              overlimit: cbInfo.overlimit,
                                              jsonUrl: urlToSave)
        userDefaultsStorage.allCbInfo[cbInfo.type] = converterResult
        userDefaultsStorage.allCbInfo = allCbInfo
    }
    
    func save(cbInfos: [FiltersConverter.Result]) throws {
        Logger.logInfo("(ContentBlockersJSONStorage) - save cbJsons; Trying to save \(cbInfos.count) jsons")
        try cbInfos.forEach { try save(cbInfo: $0) }
    }
    
    func getInfo(for cbType: ContentBlockerType) -> ConverterResult? {
        return userDefaultsStorage.allCbInfo[cbType]
    }
    
    func getEmptyRuleJsonUrl() throws -> URL {
        let fm = FileManager.default
        let emptyRuleJsonUrl = jsonStorageUrl.appendingPathComponent("empty_rule.json")
        if fm.fileExists(atPath: emptyRuleJsonUrl.absoluteString) {
            Logger.logDebug("(ContentBlockersJSONStorage) - getEmptyRuleJsonUrl; empty_rule.json exists returning it's URL")
            return emptyRuleJsonUrl
        } else {
            Logger.logDebug("(ContentBlockersJSONStorage) - getEmptyRuleJsonUrl; empty_rule.json missing create it now")
            // TODO: - It'll be in converter, remove it later
            let emptyRule = "[{\"trigger\": {\"url-filter\": \".*\",\"if-domain\": [\"domain.com\"]},\"action\":{\"type\": \"ignore-previous-rules\"}}]"
            try emptyRule.write(to: emptyRuleJsonUrl, atomically: true, encoding: .utf8)
            return emptyRuleJsonUrl
        }
    }
    
    func reset() throws {
        Logger.logInfo("(ContentBlockersJSONStorage) - reset start")
        
        // Remove all converted JSON fils
        try fileManager.removeItem(at: jsonStorageUrl)
        
        // Create directory
        try fileManager.createDirectory(at: jsonStorageUrl, withIntermediateDirectories: true, attributes: nil)
        
        // Clear user defaults
        userDefaultsStorage.allCbInfo = [:]
        
        Logger.logInfo("(ContentBlockersJSONStorage) - reset; Successfully deleted directory with CBs JSONs")
    }
    
    // MARK: - Private methods
    
    private func urlForJson(withType cbType: ContentBlockerType) -> URL {
        return jsonStorageUrl.appendingPathComponent(cbType.fileName)
    }
}

// MARK: - ContentBlockerType + fileName

fileprivate extension ContentBlockerType {
    var fileName: String {
        switch self {
        case .general: return "cb_general.json"
        case .privacy: return "cb_privacy.json"
        case .socialWidgetsAndAnnoyances: return "cb_annoyances.json"
        case .other: return "cb_other.json"
        case .custom: return "cb_custom.json"
        case .security: return "cb_security.json"
        }
    }
}

// MARK: - UserDefaultsStorageProtocol + allCbInfo

fileprivate extension UserDefaultsStorageProtocol {
    
    private var allCbInfoKey: String { "AdGuardSDK.allCbInfoKey" }
    
    var allCbInfo: [ContentBlockerType: ConverterResult] {
        get {
            if let savedCbData = storage.data(forKey: allCbInfoKey) {
                let decoder = JSONDecoder()
                let cbInfo = try? decoder.decode([ContentBlockerType: ConverterResult].self, from: savedCbData)
                return cbInfo ?? [:]
            }
            return [:]
        }
        set {
            let encoder = JSONEncoder()
            if let cbInfoData = try? encoder.encode(newValue) {
                storage.set(cbInfoData, forKey: allCbInfoKey)
            } else {
                storage.set(Date(), forKey: allCbInfoKey)
            }
        }
    }
}