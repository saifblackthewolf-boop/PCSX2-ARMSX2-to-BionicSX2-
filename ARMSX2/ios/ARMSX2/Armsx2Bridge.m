#import "Armsx2Bridge.h"
#import <React/RCTLog.h>
#import <Foundation/Foundation.h>

@interface Armsx2Bridge ()

@property (nonatomic, strong) INISettingsInterface* settingsInterface;
@property (nonatomic, assign) BOOL coreInitialized;

@end

@implementation Armsx2Bridge

RCT_EXPORT_MODULE(Armsx2Bridge);

- (instancetype)init {
    self = [super init];
    if (self) {
        _coreInitialized = NO;
        [self ensureCoreInitialized];
    }
    return self;
}

- (void)ensureCoreInitialized {
    if (_coreInitialized) return;

    // Set up EmuFolders for iOS
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    std::string dataRoot = [documentsPath UTF8String];

    EmuFolders::AppRoot = dataRoot;
    EmuFolders::DataRoot = dataRoot;
    EmuFolders::SetResourcesDirectory();

    // Initialize logging
    Log::SetConsoleOutputLevel(LOGLEVEL_DEBUG);

    // Create settings interface
    std::string iniPath = dataRoot + "/PCSX2-iOS.ini";
    _settingsInterface = new INISettingsInterface(iniPath);

    // Set base settings layer
    Host::Internal::SetBaseSettingsLayer(_settingsInterface);

    // Load or create default settings
    if (!_settingsInterface->Load() || _settingsInterface->IsEmpty()) {
        VMManager::SetDefaultSettings(*_settingsInterface, true, true, true, true, true);
        _settingsInterface->SetBoolValue("EmuCore", "EnableDiscordPresence", false);
        _settingsInterface->SetBoolValue("EmuCore/GS", "FrameLimitEnable", false);
        _settingsInterface->SetBoolValue("InputSources", "SDL", false);
        _settingsInterface->SetBoolValue("Logging", "EnableSystemConsole", true);
        _settingsInterface->SetBoolValue("Logging", "EnableTimestamps", true);
        _settingsInterface->SetBoolValue("Logging", "EnableVerbose", false);
        _settingsInterface->SetBoolValue("EmuCore/GS", "OsdShowFPS", false);
        _settingsInterface->SetBoolValue("EmuCore/GS", "OsdShowResolution", false);
        _settingsInterface->SetBoolValue("EmuCore/GS", "OsdShowGSStats", false);
        _settingsInterface->SetBoolValue("UI", "EnableFullscreenUI", false);
        _settingsInterface->SetBoolValue("Achievements", "Enabled", false);
        _settingsInterface->SetBoolValue("Achievements", "ChallengeMode", false);
        _settingsInterface->Save();
    }

    // Apply settings
    VMManager::Internal::LoadStartupSettings();
    VMManager::ApplySettings();

    _coreInitialized = YES;
}

RCT_EXPORT_METHOD(getSetting:(NSString*)section
                  key:(NSString*)key
                  type:(NSString*)type
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    if (!_settingsInterface) {
        reject(@"core_not_initialized", @"Core not initialized", nil);
        return;
    }

    std::string sec = [section UTF8String];
    std::string k = [key UTF8String];
    std::string t = [type UTF8String];

    if (t == "bool") {
        bool value = false;
        _settingsInterface->GetBoolValue(sec.c_str(), k.c_str(), &value);
        resolve(@(value));
    } else if (t == "int") {
        s32 value = 0;
        _settingsInterface->GetIntValue(sec.c_str(), k.c_str(), &value);
        resolve(@(value));
    } else if (t == "uint") {
        u32 value = 0;
        _settingsInterface->GetUIntValue(sec.c_str(), k.c_str(), &value);
        resolve(@(value));
    } else if (t == "float") {
        float value = 0.0f;
        _settingsInterface->GetFloatValue(sec.c_str(), k.c_str(), &value);
        resolve(@(value));
    } else if (t == "double") {
        double value = 0.0;
        _settingsInterface->GetDoubleValue(sec.c_str(), k.c_str(), &value);
        resolve(@(value));
    } else {
        std::string value;
        _settingsInterface->GetStringValue(sec.c_str(), k.c_str(), &value);
        resolve([NSString stringWithUTF8String:value.c_str()]);
    }
}

RCT_EXPORT_METHOD(setSetting:(NSString*)section
                  key:(NSString*)key
                  type:(NSString*)type
                  value:(id)value
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    if (!_settingsInterface) {
        reject(@"core_not_initialized", @"Core not initialized", nil);
        return;
    }

    std::string sec = [section UTF8String];
    std::string k = [key UTF8String];
    std::string t = [type UTF8String];

    if (t == "bool") {
        bool b = [value boolValue];
        _settingsInterface->SetBoolValue(sec.c_str(), k.c_str(), b);
    } else if (t == "int") {
        s32 i = [value intValue];
        _settingsInterface->SetIntValue(sec.c_str(), k.c_str(), i);
    } else if (t == "uint") {
        u32 u = [value unsignedIntValue];
        _settingsInterface->SetUIntValue(sec.c_str(), k.c_str(), u);
    } else if (t == "float") {
        float f = [value floatValue];
        _settingsInterface->SetFloatValue(sec.c_str(), k.c_str(), f);
    } else if (t == "double") {
        double d = [value doubleValue];
        _settingsInterface->SetDoubleValue(sec.c_str(), k.c_str(), d);
    } else {
        std::string s = [value UTF8String];
        _settingsInterface->SetStringValue(sec.c_str(), k.c_str(), s.c_str());
    }

    VMManager::ApplySettings();
    _settingsInterface->Save();
    resolve(@YES);
}

RCT_EXPORT_METHOD(refreshBIOS:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    // No-op placeholder for now
    resolve(nil);
}

RCT_EXPORT_METHOD(hasValidVm:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    bool hasValid = VMManager::HasValidVM();
    resolve(@(hasValid));
}

RCT_EXPORT_METHOD(setPadVibration:(BOOL)enabled
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    if (!_settingsInterface) {
        reject(@"core_not_initialized", @"Core not initialized", nil);
        return;
    }

    _settingsInterface->SetBoolValue("Pad1", "Vibration", enabled);
    _settingsInterface->Save();

    // Reload pad configuration
    Pad::LoadConfig(*_settingsInterface);

    resolve(nil);
}

RCT_EXPORT_METHOD(convertIsoToChd:(NSString*)inputIsoPath
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    // Stub implementation - return -1 for not implemented
    resolve(@(-1));
}

RCT_EXPORT_METHOD(getDataRoot:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    resolve(documentsPath);
}

RCT_EXPORT_METHOD(setDataRootOverride:(NSString*)path
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    std::string newPath = [path UTF8String];
    EmuFolders::AppRoot = newPath;
    EmuFolders::DataRoot = newPath;
    EmuFolders::SetResourcesDirectory();

    // Reload settings from new location
    std::string iniPath = newPath + "/PCSX2-iOS.ini";
    delete _settingsInterface;
    _settingsInterface = new INISettingsInterface(iniPath);
    Host::Internal::SetBaseSettingsLayer(_settingsInterface);
    _settingsInterface->Load();

    VMManager::Internal::LoadStartupSettings();
    VMManager::ApplySettings();

    resolve(path);
}

// RetroAchievements stubs
RCT_EXPORT_METHOD(getRetroAchievementsState:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSDictionary* state = @{
        @"loggedIn": @NO,
        @"achievementsEnabled": @NO
    };
    resolve(state);
}

RCT_EXPORT_METHOD(refreshRetroAchievementsState:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    resolve(nil);
}

RCT_EXPORT_METHOD(loginRetroAchievements:(NSString*)username
                  password:(NSString*)password
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSDictionary* result = @{
        @"success": @NO,
        @"message": @"RetroAchievements not implemented for iOS"
    };
    resolve(result);
}

RCT_EXPORT_METHOD(logoutRetroAchievements:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    resolve(nil);
}

RCT_EXPORT_METHOD(setRetroAchievementsEnabled:(BOOL)enabled
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    resolve(nil);
}

RCT_EXPORT_METHOD(setRetroAchievementsHardcore:(BOOL)enabled
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    resolve(nil);
}

// Discord stubs
RCT_EXPORT_METHOD(getDiscordProfile:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSDictionary* profile = @{
        @"available": @NO,
        @"loggedIn": @NO
    };
    resolve(profile);
}

RCT_EXPORT_METHOD(beginDiscordLogin:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    reject(@"discord_unavailable", @"Discord not available on iOS", nil);
}

RCT_EXPORT_METHOD(logoutDiscord:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    resolve(nil);
}

// Event emission stubs
- (NSArray<NSString *> *)supportedEvents {
    return @[@"armsx2.retroAchievements", @"armsx2.retroAchievementsLogin", @"armsx2.discord"];
}

- (void)dealloc {
    delete _settingsInterface;
}

@end