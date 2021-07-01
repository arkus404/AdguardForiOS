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

public enum UserRuleType {
    case blocklist
    case allowlist
    case invertedAllowlist
}

public protocol UserRuleProtocol: Codable {
    /* Rule is a string that user did enter in the rule field */
    var ruleText: String { get }
    
    /* State of rule */
    var isEnabled: Bool { get set }
    
    /*
     Validates rule
     Returns true if rule can be converted to safari content blocker rule by converter
     Returns false for unsupported rules
     */
    static func isValid(rule: String) -> Bool
}

public struct UserRule: UserRuleProtocol, Equatable {
    public var ruleText: String
    public var isEnabled: Bool
    
    init(ruleText: String, isEnabled: Bool = true) {
        self.ruleText = ruleText
        self.isEnabled = isEnabled
    }
    
    public static func isValid(rule: String) -> Bool {
        let trimmedRule = rule.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedRule.count == 0 {
            return false
        }
        
        let oldInjectRules = "adg_start_style_inject"
        let maskContentRule = "$$"
        let maskContentExceptionRule = "$@$"
        let maskJsRule = "%%"
        let maskFilterUnsupportedRule = "##^"
        
        return !(trimmedRule.contains(oldInjectRules)
                || trimmedRule.contains(maskContentRule)
                || trimmedRule.contains(maskContentExceptionRule)
                || trimmedRule.contains(maskJsRule)
                || trimmedRule.contains(maskFilterUnsupportedRule))
    }
}