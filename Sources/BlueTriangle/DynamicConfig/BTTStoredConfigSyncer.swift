//
//  ConfigSyncManager.swift
//  
//
//  Created by Ashok Singh on 21/01/25.
//


/// A utility class for synchronizing and managing the SDK's stored  remote configuration into the blue triangle configuration.
///
/// The `BTTStoredConfigSyncer` is responsible for ensuring that the SDK's locally stored
/// remote configuration remains up-to-date and consistent with the blue triangle configuration.
///
/// - Responsibilities:
///   - Synchronizes the locally cached remote configuration with the  blue triangle configuration.
///   - Handles storage and retrieval of configuration data to ensure seamless operation,
///     even when the remote API is unreachable.
///
/// - Key Features:
///   - Ensures the enable/disable state of the SDK is accurately reflected in the stored configuration.
///
class BTTStoredConfigSyncer {
    
    private let configRepo: BTTConfigurationRepo
    private let logger: Logging
    
    init(configRepo: BTTConfigurationRepo, logger: Logging) {
        self.configRepo = configRepo
        self.logger = logger
    }
    
    /// Synchronizes the configuration values from the stored repository.
    ///
    /// This method retrieves the latest remote configuration from the repository and applies it to the
    /// Blue triangle configuration. It updates key configuration values like the network sample rate and screens to
    /// ignore, .
    ///
    /// - Notes:
    ///   - This function ensures that the Blue triangle configuration is kept up-to-date.
    ///
    func syncConfigurationFromStorage() {
        do{
            if let config = try configRepo.get() {
                
                //Sync Sample Rate
                let sampleRate = config.networkSampleRateSDK ?? configRepo.defaultConfig.networkSampleRateSDK
                if CommandLine.arguments.contains(Constants.FULL_SAMPLE_RATE_ARGUMENT) {
                    BlueTriangle.updateNetworkSampleRate(1.0)
                } else if let rate = sampleRate {
                    if rate == 0 {
                        BlueTriangle.updateNetworkSampleRate(0.0)
                    } else {
                        BlueTriangle.updateNetworkSampleRate(Double(rate) / 100.0)
                    }
                }
                
                //Sync Grouped View Sample Rate
                let groupedViewRate = config.groupedViewSampleRate ?? configRepo.defaultConfig.groupedViewSampleRate
                if let rate = groupedViewRate {
                    if rate == 0 {
                        BlueTriangle.updateGroupedViewSampleRate(0.0)
                    } else {
                        BlueTriangle.updateGroupedViewSampleRate(Double(rate) / 100.0)
                    }
                }
                
               // Sync Ignore Screens
                let ignoreScreens = config.ignoreScreens ?? configRepo.defaultConfig.ignoreScreens
                if let ignoreVcs = ignoreScreens {
                    var unianOfIgnoreScreens = Set(ignoreVcs)
                    if let defaultScreens = configRepo.defaultConfig.ignoreScreens {
                        unianOfIgnoreScreens = unianOfIgnoreScreens.union(Set(defaultScreens))
                    }
                    BlueTriangle.updateIgnoreVcs(unianOfIgnoreScreens)
                }

                // Sync Enable Screen tracking
                if let enableScreenTracking = config.enableScreenTracking ?? configRepo.defaultConfig.enableScreenTracking {
                    BlueTriangle.updateScreenTracking(enableScreenTracking)
                }
                
                // Sync Grouping
                if let enableGrouping = config.enableGrouping ?? configRepo.defaultConfig.enableGrouping, let groupingIdleTime = config.groupingIdleTime ?? configRepo.defaultConfig.groupingIdleTime {
                    BlueTriangle.updateGrouping(enableGrouping, idleTime: groupingIdleTime)
                }
            }
        } catch {
            logger.error("BlueTriangle:SessionManager: Failed to retrieve remote configuration from the repository - \(error)")
        }
    }
    /// Evaluates the SDK's state based on the latest configuration and updates it accordingly.
    ///
    /// This method checks whether the SDK should be enabled or disabled based on the retrieved remote
    /// configuration, and updates the SDK state if necessary.
    ///
    /// - Notes:
    ///   - This method ensures that the SDK's behavior is in sync with the remote configuration
    ///

    func updateAndApplySDKState(){
        do{
            if let config = try configRepo.get(){
                let isEnable = config.enableAllTracking ?? true
                if BlueTriangle.initialized && isEnable != BlueTriangle.enableAllTracking{
                    BlueTriangle.enableAllTracking = isEnable
                    BlueTriangle.applyAllTrackerState()
                }
            }
        }
        catch {
            logger.error("BlueTriangle:SessionManager: Failed to retrieve remote configuration from the repository - \(error)")
        }
    }
}
