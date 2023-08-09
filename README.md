# CppProject

This is a template for C++ projects. Replace the name 'CppProject' in the following files:

* ./README.md (this file)
* ./Makefile
* ./CMakeLists.txt

Also, update .liccor.yml with your copyright info.

## Prerequisites

* Install GCC, Clang, or Visual Studio with C++20 support
* Install Python 3
* Install Ninja, Make, and CMake
* Consider also installing ccache for faster subsequent build times

## Build

Build options: release, debug, asan

	make purge configure-{release,debug} install

## Run

	make run
