# iOS Toolchain for PCSX2
set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_SYSTEM_VERSION 14.0)
set(CMAKE_OSX_ARCHITECTURES arm64)
set(CMAKE_OSX_DEPLOYMENT_TARGET 14.0)

# Set the compilers
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# Set compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fobjc-arc")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fobjc-arc -fno-objc-arc")

# Find iOS SDK
execute_process(COMMAND xcrun --sdk iphoneos --show-sdk-path
                OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
                OUTPUT_STRIP_TRAILING_WHITESPACE)

# Set the sysroot
set(CMAKE_OSX_SYSROOT ${CMAKE_OSX_SYSROOT} CACHE PATH "iOS SDK root")

# Set framework search paths
set(CMAKE_FRAMEWORK_PATH ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks)

# Disable code signing for development builds
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO")
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "")

# Set minimum iOS version
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "14.0")

# Enable Metal support
set(CMAKE_XCODE_ATTRIBUTE_METAL_ENABLE_DEBUG_INFO "YES")

# Set build type specific flags
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O0 -g")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -g")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")

# Set linker flags
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -framework Foundation -framework UIKit -framework Metal -framework MetalKit -framework QuartzCore -framework IOKit")

# Set shared library flags
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -framework Foundation -framework UIKit -framework Metal -framework MetalKit -framework QuartzCore -framework IOKit")

# Set static library flags
set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS}")

# Disable certain features not available on iOS
set(USE_OPENGL OFF CACHE BOOL "Disable OpenGL on iOS" FORCE)
set(USE_VULKAN OFF CACHE BOOL "Disable Vulkan on iOS" FORCE)
set(USE_DISCORD_SDK OFF CACHE BOOL "Disable Discord SDK on iOS" FORCE)

# Enable Metal renderer
set(USE_METAL ON CACHE BOOL "Enable Metal renderer for iOS" FORCE)