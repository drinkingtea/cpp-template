cmake_minimum_required(VERSION 3.19)
set(CMAKE_POLICY_DEFAULT_CMP0110 NEW) # requires CMake 3.19

project(CppProject)

include(deps/buildcore/base.cmake)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${QTDIR})

if(NOT MSVC)
	# enable warnings
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wsign-conversion")
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

if(APPLE)
	set(CMAKE_MACOSX_RPATH OFF)
	set(CMAKE_INSTALL_NAME_DIR "@executable_path/../Library/")
	set(CPPPROJECT_DIST_BIN              CppProject.app/Contents/MacOS)
	set(CPPPROJECT_DIST_LIB              CppProject.app/Contents/Library)
	set(CPPPROJECT_DIST_MODULE           CppProject.app/Contents/Plugins)
	set(CPPPROJECT_DIST_RESOURCES        CppProject.app/Contents/Resources)
	set(CPPPROJECT_DIST_MAC_APP_CONTENTS CppProject.app/Contents)
else()
	if(UNIX)
		set(BUILD_SHARED_LIBS ON)
	endif()
	set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
	set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
	set(CPPPROJECT_DIST_BIN       bin)
	set(CPPPROJECT_DIST_LIB       lib)
	set(CPPPROJECT_DIST_MODULE    lib)
	set(CPPPROJECT_DIST_RESOURCES share)
endif()

if(QTDIR)
	set(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_RPATH} "${QTDIR}/lib")
endif()
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)

add_subdirectory(src)
