cmake_minimum_required(VERSION 3.16...3.25)
project(Pcsx2IOS C CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../app/src/main/cpp/cmake")
include(Pcsx2Utils)
check_no_parenthesis_in_path()
detect_operating_system()
detect_compiler()

set(TOP_CMAKE_WAS_SOURCED TRUE)
set(CMAKE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../app/src/main/cpp")
set(CMAKE_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")

include(BuildParameters)
include(SearchForStuff)

set(ANDROID FALSE)
set(APPLE TRUE)
set(IOS TRUE)

add_subdirectory(${CMAKE_SOURCE_DIR}/common ${CMAKE_CURRENT_BINARY_DIR}/common)
add_subdirectory(${CMAKE_SOURCE_DIR}/pcsx2 ${CMAKE_CURRENT_BINARY_DIR}/pcsx2)
