# ARMSX2 to BionicSX2 iOS Port

This project ports the ARMSX2 Android emulator core to iOS using React Native.

## Project Structure

```
ARMSX2/
├── ios/
│   ├── ARMSX2/                    # iOS bridge module
│   │   ├── Armsx2Bridge.h         # Objective-C bridge header
│   │   ├── Armsx2Bridge.m         # Objective-C bridge implementation
│   │   └── Bridging-Header.h      # C++ to Objective-C bridging header
│   ├── CMakeLists.txt             # CMake build configuration for iOS
│   ├── cmake/
│   │   └── ios.toolchain.cmake    # iOS cross-compilation toolchain
│   ├── ExportOptions.plist        # Xcode export options for unsigned IPA
│   └── build/                     # Build directory (created during build)
├── app_ui/native/armsx2.js        # JavaScript interface (existing)
└── app/src/reactnative/...        # Java React Native module (existing)
```

## Build Instructions

### Prerequisites

1. macOS with Xcode 14+
2. Node.js 18+
3. CMake 3.16+
4. Ninja build system

### Manual Build Steps

1. **Create React Native iOS Project:**
   ```bash
   cd ARMSX2
   npx react-native init BionicSX2 --template react-native-template-typescript
   cp -r BionicSX2/ios ios/
   rm -rf BionicSX2
   ```

2. **Copy Bridge Files:**
   ```bash
   cp ios/ARMSX2/* ios/BionicSX2/
   ```

3. **Build PCSX2 Static Library:**
   ```bash
   cd ios
   mkdir -p build
   cd build
   cmake .. -DCMAKE_BUILD_TYPE=Release -G Ninja
   ninja emucore
   ```

4. **Link Library to Xcode Project:**
   - Open `ios/BionicSX2/BionicSX2.xcworkspace` in Xcode
   - Add `libemucore.a` to the project
   - Add header search paths: `$(PROJECT_DIR)/../../../app/src/main/cpp`
   - Add library search paths: `$(PROJECT_DIR)/../build/lib`
   - Add bridging header: `Bridging-Header.h`
   - Link frameworks: Foundation, UIKit, Metal, MetalKit, QuartzCore, IOKit

5. **Build and Export IPA:**
   ```bash
   cd ios/BionicSX2
   xcodebuild archive \
     -workspace BionicSX2.xcworkspace \
     -scheme BionicSX2 \
     -configuration Release \
     -sdk iphoneos \
     -archivePath build/BionicSX2.xcarchive \
     CODE_SIGNING_ALLOWED=NO

   xcodebuild -exportArchive \
     -archivePath build/BionicSX2.xcarchive \
     -exportOptionsPlist ../ExportOptions.plist \
     -exportPath build \
     CODE_SIGNING_ALLOWED=NO
   ```

### GitHub Actions

The project includes a GitHub Actions workflow (`.github/workflows/build_ios.yml`) that automates the build process and produces an unsigned IPA artifact.

### Testing

1. Install the unsigned IPA using Xcode:
   ```bash
   xcrun ios-deploy --bundle build/BionicSX2.ipa --no-wifi
   ```

2. The app will have `get-task-allow` entitlement for JIT debugging.

## Implementation Notes

### Bridge Module

The `Armsx2Bridge` class implements the same interface as the Android `Armsx2NativeModule`:

- Settings management (getSetting/setSetting)
- VM status checks (hasValidVm)
- BIOS operations (refreshBIOS)
- Pad vibration control (setPadVibration)
- ISO to CHD conversion (stubbed)
- Data root management
- RetroAchievements stubs
- Discord stubs

### CMake Build System

- Uses iOS toolchain for cross-compilation to arm64
- Builds PCSX2 core as static library `libemucore.a`
- Includes Metal renderer for iOS
- Excludes Android-specific code
- Links iOS frameworks

### Limitations

- RetroAchievements and Discord are stubbed (not implemented for iOS)
- ISO to CHD conversion is not implemented
- Full UI integration requires additional React Native components
- VM execution methods (runVMThread, pause, resume, shutdown) need additional implementation

### Future Work

1. Implement VM execution methods in the bridge
2. Add Metal-based rendering surface
3. Implement RetroAchievements for iOS
4. Add proper error handling and logging
5. Integrate with React Native navigation and UI components