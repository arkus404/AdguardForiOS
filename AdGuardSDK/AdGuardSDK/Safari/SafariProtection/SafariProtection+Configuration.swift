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

/*  Application user configuration */
public protocol SafariProtectionConfigurationProtocol {
        
    /* Shows if user has Premium app version */
    var proStatus: Bool { get }
    
    /* State of the whole Safari protection. If it is false nothing will be filtered */
    var safariProtectionEnabled: Bool { get }
    
    /* State of the list that is responsible for blocking rules. In UI it is called User rules */
    var blocklistIsEnabled: Bool { get }
    
    /* State of the list that is responsible for the rules that cancel blocklist rules actions */
    var allowlistIsEnbaled: Bool { get }
    
    /* Allowlist rules can be inverted. That means that blocklist rules will work on all sites except the sites from the inverted allowlist  */
    var allowlistIsInverted: Bool { get }
    
    /* Updates pro status in configuration and reloads content blockers */
    func update(proStatus: Bool, onCbReloaded: ((_ error: Error?) -> Void)?)
    
    /* Updates Safari protection state and reloads content blockers */
    func update(safariProtectionEnabled: Bool, onCbReloaded: ((_ error: Error?) -> Void)?)
    
    /* Updates block list state and reloads content blockers */
    func update(blocklistIsEnabled: Bool, onCbReloaded: ((_ error: Error?) -> Void)?)
    
    /* Updates allow list state and reloads content blockers */
    func update(allowlistIsEnbaled: Bool, onCbReloaded: ((_ error: Error?) -> Void)?)
    
    /* Updates state of allowlist invertion and reloads content blockers */
    func update(allowlistIsInverted: Bool, onCbReloaded: ((_ error: Error?) -> Void)?)
}

/* Extension is used to properly process all configuration changes */
extension SafariProtection {
    public var proStatus: Bool {
        return workingQueue.sync { return configuration.proStatus }
    }
    
    public var safariProtectionEnabled: Bool {
        return workingQueue.sync { return configuration.safariProtectionEnabled }
    }
    
    public var blocklistIsEnabled: Bool {
        return workingQueue.sync { return configuration.blocklistIsEnabled }
    }
    
    public var allowlistIsEnbaled: Bool {
        return workingQueue.sync { return configuration.allowlistIsEnbaled }
    }
    
    public var allowlistIsInverted: Bool {
        return workingQueue.sync { return configuration.allowlistIsInverted }
    }
    
    public func update(proStatus: Bool, onCbReloaded: ((_ error: Error?) -> Void)?) {
        workingQueue.sync {
            Logger.logInfo("(SafariProtection+Configuration) - updateProStatus; Updating proStatus from=\(self.configuration.proStatus) to=\(proStatus)")
            
            try? executeBlockAndReloadCbs {
                if configuration.proStatus != proStatus {
                    configuration.proStatus = proStatus
                } else {
                    // Throw error to not reload CB
                    throw CommonError.dataDidNotChange
                }
            } onCbReloaded: { [weak self] error in
                guard let self = self else {
                    Logger.logError("(SafariProtection+Configuration) - update.proStatus.reloadContentBlockers; self is missing!")
                    DispatchQueue.main.async { onCbReloaded?(CommonError.missingSelf) }
                    return
                }
                
                if let error = error {
                    Logger.logError("(SafariProtection+Configuration) - updateProStatus; Error reloading CBs when updating proStatus; Error: \(error)")
                } else {
                    Logger.logInfo("(SafariProtection+Configuration) - updateProStatus; Successfully reloaded CBs after updating proStatus")
                }
                self.completionQueue.async { onCbReloaded?(error) }
            }
        }
    }
    
    public func update(safariProtectionEnabled: Bool, onCbReloaded: ((_ error: Error?) -> Void)?) {
        workingQueue.sync {
            Logger.logInfo("(SafariProtection+Configuration) - updateSafariProtection; Updating safariProtection from=\(self.configuration.safariProtectionEnabled) to=\(safariProtectionEnabled)")
            
            try? executeBlockAndReloadCbs {
                if configuration.safariProtectionEnabled != safariProtectionEnabled {
                    configuration.safariProtectionEnabled = safariProtectionEnabled
                } else {
                    throw CommonError.dataDidNotChange
                }
            } onCbReloaded: { [weak self] error in
                guard let self = self else {
                    Logger.logError("(SafariProtection+Configuration) - update.safariProtection.reloadContentBlockers; self is missing!")
                    DispatchQueue.main.async { onCbReloaded?(CommonError.missingSelf) }
                    return
                }
                
                if let error = error {
                    Logger.logError("(SafariProtection+Configuration) - updateSafariProtection; Error reloading CBs when updating safariProtection; Error: \(error)")
                } else {
                    Logger.logInfo("(SafariProtection+Configuration) - updateSafariProtection; Successfully reloaded CBs after updating safariProtection")
                }
                self.completionQueue.async { onCbReloaded?(error) }
            }
        }
    }
    
    public func update(blocklistIsEnabled: Bool, onCbReloaded: ((_ error: Error?) -> Void)?) {
        workingQueue.sync {
            Logger.logInfo("(SafariProtection+Configuration) - updateBlocklistIsEnabled; Updating blocklist state from=\(self.configuration.blocklistIsEnabled) to=\(blocklistIsEnabled)")

            try? executeBlockAndReloadCbs {
                if configuration.blocklistIsEnabled != blocklistIsEnabled {
                    configuration.blocklistIsEnabled = blocklistIsEnabled
                } else {
                    throw CommonError.dataDidNotChange
                }
            } onCbReloaded: { [weak self] error in
                guard let self = self else {
                    Logger.logError("(SafariProtection+Configuration) - update.blocklistIsEnabled.reloadContentBlockers; self is missing!")
                    DispatchQueue.main.async { onCbReloaded?(CommonError.missingSelf) }
                    return
                }
                
                if let error = error {
                    Logger.logError("(SafariProtection+Configuration) - updateBlocklistIsEnabled; Error reloading CBs when updating blocklist state; Error: \(error)")
                } else {
                    Logger.logInfo("(SafariProtection+Configuration) - updateBlocklistIsEnabled; Successfully reloaded CBs after updating blocklist state")
                }
                self.completionQueue.async { onCbReloaded?(error) }
            }
        }
    }
    
    public func update(allowlistIsEnbaled: Bool, onCbReloaded: ((_ error: Error?) -> Void)?) {
        workingQueue.sync {
            Logger.logInfo("(SafariProtection+Configuration) - updateAllowlistIsEnbaled; Updating allowlist state from=\(self.configuration.allowlistIsEnbaled) to=\(allowlistIsEnbaled)")

            try? executeBlockAndReloadCbs {
                if configuration.allowlistIsEnbaled != allowlistIsEnbaled {
                    configuration.allowlistIsEnbaled = allowlistIsEnbaled
                } else {
                    throw CommonError.dataDidNotChange
                }
            } onCbReloaded: { [weak self] error in
                guard let self = self else {
                    Logger.logError("(SafariProtection+Configuration) - update.allowlistIsEnbaled.reloadContentBlockers; self is missing!")
                    DispatchQueue.main.async { onCbReloaded?(CommonError.missingSelf) }
                    return
                }
                
                if let error = error {
                    Logger.logError("(SafariProtection+Configuration) - updateAllowlistIsEnbaled; Error reloading CBs when updating allowlist state; Error: \(error)")
                } else {
                    Logger.logInfo("(SafariProtection+Configuration) - updateAllowlistIsEnbaled; Successfully reloaded CBs after updating allowlist state")
                }
                self.completionQueue.async { onCbReloaded?(error) }
            }
        }
    }
    
    public func update(allowlistIsInverted: Bool, onCbReloaded: ((_ error: Error?) -> Void)?) {
        workingQueue.sync {
            Logger.logInfo("(SafariProtection+Configuration) - updateAllowlistIsInverted; Updating allowlist invertion state from=\(self.configuration.allowlistIsInverted) to=\(allowlistIsInverted)")
            
            try? executeBlockAndReloadCbs {
                if configuration.allowlistIsInverted != allowlistIsInverted {
                    configuration.allowlistIsInverted = allowlistIsInverted
                } else {
                    throw CommonError.dataDidNotChange
                }
            } onCbReloaded: { [weak self] error in
                guard let self = self else {
                    Logger.logError("(SafariProtection+Configuration) - update.allowlistIsInverted.reloadContentBlockers; self is missing!")
                    DispatchQueue.main.async { onCbReloaded?(CommonError.missingSelf) }
                    return
                }
                
                if let error = error {
                    Logger.logError("(SafariProtection+Configuration) - updateAllowlistIsEnbaled; Error reloading CBs when updating allowlist invertion; Error: \(error)")
                } else {
                    Logger.logInfo("(SafariProtection+Configuration) - updateAllowlistIsEnbaled; Successfully reloaded CBs after updating allowlist invertion")
                }
                self.completionQueue.async { onCbReloaded?(error) }
            }
        }
    }
}