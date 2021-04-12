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
#import <Foundation/Foundation.h>
#import "ABackEndClients/ABECFilter.h"

/// When anitbanner service installed
extern NSString * _Nonnull ASAntibannerInstalledNotification;

/// When anitbanner service did not installed
extern NSString * _Nonnull ASAntibannerNotInstalledNotification;

/// When anitbanner service ready to work
extern NSString * _Nonnull ASAntibannerReadyNotification;

/// When antibanner filter rules updated
extern NSString * _Nonnull ASAntibannerUpdateFilterRulesNotification;

/// When anitbanner started update process
extern NSString * _Nonnull ASAntibannerStartedUpdateNotification;
/// When antibanner does not start update process, according to internal reason.
extern NSString * _Nonnull ASAntibannerDidntStartUpdateNotification;
/// When some part of the update process completed
extern NSString * _Nonnull ASAntibannerUpdatePartCompletedNotification;

/// When anitbanner finished update process
extern NSString * _Nonnull ASAntibannerFinishedUpdateNotification;

/// Key for userInfo of ASAntibannerFinishedUpdateNotification that defines
/// array of metadata objects of updated filters.
extern NSString * _Nonnull ASAntibannerUpdatedFiltersKey;

/// When anti banner update process failed because backend service is unreachable
extern NSString * _Nonnull ASAntibannerFailuredUpdateNotification;

/// When antibanner filter updated from Ad Block Preferences and Main Panel(enabled/desabled/unsubscribe etc..)
extern NSString * _Nonnull ASAntibannerUpdateFilterFromUINotification;

/// When filter enable status did change
extern NSString * _Nonnull ASAntibannerFilterEnabledNotification;

@class Reachability, ASDFilterRule, ACLExecuteBlockDelayed, ASDatabase;
@class AASCustomFilterParserResult;
@protocol ACNNetworkingProtocol, AESharedResourcesProtocol;

/////////////////////////////////////////////////////////////////////////
#pragma mark - ASAntibanner
/////////////////////////////////////////////////////////////////////////

/**
 Service implements: updating from backend, auto detect filters, storing info and rules
 for Ad Blocker (the same Antibanner, requestFilter), and so on..
 */

@protocol AESAntibannerProtocol <NSObject> 

/////////////////////////////////////////////////////////////////////////
#pragma mark Properties and public methods
/////////////////////////////////////////////////////////////////////////

/**
 Indicates that antibanner updates of filters right now.
 */
@property (readonly) BOOL updatesRightNow;

/** set database to work with it */
- (void) setDatabase:(nonnull ASDatabase*) db;

/** start sevice */
- (void) start;

/** stop service */
- (void) stop;

/**
 Obtain active rules for active (enabled) filter.
 
 @param filterId    Filter Id, which will be checked
 and whose rules will be returned.
 
 @return Array of ASDFilterRule objects that represent rules of filtering.
 Returns empty array if receiver property "enabled" equal NO.
 */
- (nonnull NSArray<ASDFilterRule*> *)activeRulesForFilter:(nonnull NSNumber *)filterId;

/**
 Obtain groups information.
 @return Array of ASDFilterGroup objects that contains
 all stored in database groups.
 */
- (nonnull NSArray<ASDFilterGroup*> *)groups;

/**
 Obtain groups information.
 @return Array of ASDFilterGroup objects that contains
 all stored in default database groups.
 */
- (nonnull NSArray<ASDFilterGroup*> *)defaultDbGroups;

/**
 Obtains groups localization information.
 @return ASDGroupsI18n object that contains data from database.
 */
- (nonnull ASDGroupsI18n *)groupsI18n;
/**
 
 /**
  Obtains groups localization information.
  @return ASDGroupsI18n object that contains data from default database.
  */
 - (nonnull ASDGroupsI18n *)defaultDbGroupsI18n;
 /**
  
 Checks if specified filter was installed.

 @param filterId Filter id.
 @return YES, if filter was installed into production DB.
 */
- (BOOL)checkIfFilterInstalled:(nonnull NSNumber *)filterId;
/**
 Obtain filters information.
 @return Array of ASDFilterMetadata objects that contains
 all stored in database antibanner filters.
 */
- (nonnull NSArray<ASDFilterMetadata*> *)filters;

/**
 Obtain filters information.
 @return Array of ASDFilterMetadata objects that contains
 all stored in default database(stored in app bundle) antibanner filters.
 */
- (nonnull NSArray<ASDFilterMetadata*> *)defaultDbFilters;

/**
 Obtain filters information.
 @return Array of ASDFilterMetadata objects that contains
 all stored in database active antibanner filters.
 */
- (nonnull NSArray<ASDFilterMetadata*> *)activeFilters;

/**
 Obtain filters information.
 @return Array of ASDFilterMetadata objects that contains
 all stored in database antibanner filters.
 */
- (nonnull NSArray<ASDFilterMetadata*> *)filtersForGroup:(nonnull NSNumber*) groupId;

/**
 Obtain enabled filters information.
 @return Array of NSNumber objects that contains enabled filter IDs
 */
- (nonnull NSArray<NSNumber*> *) enabledFilterIDs;

/**
 Obtain active filters information.
 @return Array of NSNumber objects that contains enable filter IDs only for enabled groups
 */
- (nonnull NSArray<NSNumber*> *)activeFilterIDs;

/**
 Obtain active group information.
 @return Array of NSNumber objects that contains active groups IDs
 */
- (nonnull NSArray<NSNumber*>*) activeGroupIDs;

/**
 Obtain active filters information.
 @return Array of NSNumber objects that contains active filter IDs by groupID
 */
- (nonnull NSArray<NSNumber*> *)activeFilterIDsByGroupID:(nonnull NSNumber*)groupID;

/**
 Obtains filters localization information.
 @return ASDFiltersI18n object that contains data from database.
 */
- (nonnull ASDFiltersI18n *)filtersI18n;

/**
 Obtains filters localization information.
 @return ASDFiltersI18n object that contains data from default database.
 */
- (nonnull ASDFiltersI18n *)defaultDbFiltersI18n;

/**
 Obtain rules for filter.
 @return Array of ASDFilterRule objects that contains
 all rules stored in database for antibanner filter,
 which is defined filterId parameter.
 */
- (nonnull NSArray<ASDFilterRule*> *)rulesForFilter:(nonnull NSNumber *)filterId;

/**
 Calculates rules count for filter.
 @return rules count
 */
- (int )rulesCountForFilter:(nonnull NSNumber *)filterId;

/**
 Set status of antibanner filter.
 
 @param filterId     Identificator of filter (filter Id).
 @param enabled      Enable/Disable of filter.
 @param  fromUI      Indicator that setting of filters status is performed from UI.
 */
- (void)setFilter:(nonnull NSNumber *)filterId enabled:(BOOL)enabled fromUI:(BOOL)fromUI;

/**
 Set status of antibanner filter.
 
 @param groupId     group id
 @param enabled      Enable/Disable of filter.
 */
- (void)setFiltersGroup:(nonnull NSNumber*) groupId enabled:(BOOL) enabled;

/**
 
 Sets status of rules in antibanner filter.
 
 @param ruleIds     List of NSNumber objects. Identificators of rules.
 @param filterId    Identificator of filter (filter Id).
 @param enabled     Enable/Disable of rule.
 */
- (void)setRules:(nonnull NSArray *)ruleIds filter:(nonnull NSNumber *)filterId enabled:(BOOL)enabled;

/**
 Checks that antibanner filter is editable,
 and then adds rule for antibanner filter into DB.
 
 @return YES if success.
 */
- (BOOL)addRule:(nonnull ASDFilterRule *)rule;

/**
 Checks that antibanner filter is editable,
 and then updates rule for antibanner filter into DB,
 using filterId and ruleId as key.
 
 @return YES if success.
 */
- (BOOL)updateRule:(nonnull ASDFilterRule *)rule;

/**
 Checks that antibanner filter is editable,
 and then removes all rules of the antibanner filter from DB,
 and then adds new rules from list.
 
 @param rules        List of rules, which must be added into filter.
 @param filterId     Identificator of filter (filter Id).
 
 @return YES if success.
 */
- (BOOL)importRules:(nonnull NSArray <ASDFilterRule *> *)rules filterId:(nonnull NSNumber *)filterId;

/**
 Removes rules for antibanner filter from DB.
 
 @param filterId    Identificator of filter (filter Id).
 
 @return YES if success.
 */
- (BOOL)removeRulesForFilter:(nonnull NSNumber *)filterId;

/**
 Performs subscription to filters.
 Inserts filter metadata from filters parameter into production DB.
 Copies the rules from default DB into production DB if they present,
 or tries to obtain the rules from backend server.
 
 @param filters         List of the ASDFilterMetadata objects, which will be save into DB.
 */
- (BOOL)subscribeFilters:(nonnull NSArray<ASDFilterMetadata*>*) filters;

/**
 Removes filter data from production DB.
 */
- (BOOL)unsubscribeFilter:(nonnull NSNumber *)filterId;

/**
 last filters update time of nil
 */
- (nullable NSDate*) filtersLastUpdateTime;

/**
 transaction support
 */
- (BOOL)inTransaction;
- (void)beginTransaction;
- (void)endTransaction;
- (void)rollbackTransaction;
/**
 When app works in background sometimes we must unlock db file to prevent app suspension by iOS.
 We should lock it when app returns foreground.
 */
- (void)applicationWillEnterForeground;

/**
 returns unique custom filter id
 */
- (nonnull NSNumber*) nextCustomFilterId;

/**
 async adds custom filter to database and  calls callback on complete
 */
- (void)subscribeCustomFilterFromResult:(nonnull AASCustomFilterParserResult *)parserResult completion:(nullable void (^)(void))completionBlock;

/**
 returns cusom filter identifier by download url or nil if url is not found
 */
- (nullable NSNumber*) customFilterIdByUrl: (nonnull NSString*) url;

/**
 Changes custom filter name
*/
- (void) renameCustomFilter: (nonnull NSNumber*) filterId newName: (nonnull NSString *)newName;

/**
 enable groups which contain enabled filters
 */
- (BOOL) enableGroupsWithEnabledFilters;

/** disable all user rules */
- (BOOL) disableUserRules;

@end


@interface AESAntibanner : NSObject <AESAntibannerProtocol>

/**
 init
 */
- (_Nonnull instancetype)initWithNetworking:(nonnull id<ACNNetworkingProtocol>)networking resources: (nonnull id<AESharedResourcesProtocol>) resources;

/**
 Indicator that metadata and count of filters are out of date.
 Used for subscribing of new filters.
 */
@property (nonatomic, readonly) BOOL metadataForSubscribeOutdated;


@end