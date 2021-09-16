cmake_minimum_required(VERSION 3.7)
set (CMAKE_CXX_STANDARD 20)

project( SharingLeds )

add_subdirectory(lua-5.4.3)

SET(BUILD_TEST OFF CACHE BOOL "")
SET(BUILD_SHARED OFF CACHE BOOL "")
add_subdirectory(rpi_ws281x)

add_subdirectory(cpp-httplib)
add_subdirectory(main)
