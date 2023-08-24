#
#  Copyright 2016 - 2023 gary@drinkingtea.net
#
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

ifeq (${OS},Windows_NT)
	SHELL := powershell.exe
	.SHELLFLAGS := -NoProfile -Command
	BC_OS=windows
	BC_HOST_ENV=${BC_OS}
else
	BC_OS=$(shell uname | tr [:upper:] [:lower:])
	BC_HOST_ENV=${BC_OS}-$(shell uname -m)
endif

ifdef BC_USE_DOCKER_DEVENV
	ifneq ($(shell which docker 2> /dev/null),)
		BC_DEVENV=devenv$(shell pwd | sed 's/\//-/g')
		BC_DEVENV_IMAGE=${BC_PROJECT_NAME}-devenv
		ifeq ($(shell docker inspect --format="{{.State.Status}}" ${BC_DEVENV} 2>&1),running)
			BC_ENVRUN=docker exec -i -t --user $(shell id -u ${USER}) ${BC_DEVENV}
		endif
	endif
endif

ifneq ($(shell ${BC_ENVRUN} which python3 2> /dev/null),)
	BC_PY3=${BC_ENVRUN} python3
else
	ifeq ($(shell ${BC_ENVRUN} python -c 'import sys; print(sys.version_info[0])'),3)
		BC_PY3=python
	else
		echo 'Please install Python3'
		exit 1
	endif
endif

BC_SCRIPTS=${BUILDCORE_PATH}/scripts
BC_SETUP_BUILD=${BC_PY3} ${BC_SCRIPTS}/setup-build.py
BC_PYBB=${BC_PY3} ${BC_SCRIPTS}/pybb.py
BC_CMAKE_BUILD=${BC_PYBB} cmake-build
BC_GETENV=${BC_PYBB} getenv
BC_CTEST=${BC_PYBB} ctest-all
BC_RM_RF=${BC_PYBB} rm
BC_CAT=${BC_PYBB} cat
BC_BUILD_PATH=build
ifdef BC_USE_VCPKG
	ifndef BC_VCPKG_DIR_BASE
		BC_VCPKG_DIR_BASE=.vcpkg
	endif
	ifndef BC_VCPKG_VERSION
		BC_VCPKG_VERSION=2023.08.09
	endif
	BC_VCPKG_TOOLCHAIN=--toolchain=${BC_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake
endif
BC_DEBUGGER=${BC_PYBB} debug

BC_VCPKG_DIR=$(BC_VCPKG_DIR_BASE)/$(BC_VCPKG_VERSION)-$(BC_HOST_ENV)
BC_CURRENT_BUILD=$(BC_HOST_ENV)-$(shell ${BC_ENVRUN} ${BC_CAT} .current_build)

.PHONY: build
build:
	${BC_ENVRUN} ${BC_CMAKE_BUILD} ${BC_BUILD_PATH}
.PHONY: install
install:
	${BC_ENVRUN} ${BC_CMAKE_BUILD} ${BC_BUILD_PATH} install
.PHONY: clean
clean:
	${BC_ENVRUN} ${BC_CMAKE_BUILD} ${BC_BUILD_PATH} clean
.PHONY: purge
purge:
	${BC_ENVRUN} ${BC_RM_RF} .current_build
	${BC_ENVRUN} ${BC_RM_RF} ${BC_BUILD_PATH}
	${BC_ENVRUN} ${BC_RM_RF} dist
	${BC_ENVRUN} ${BC_RM_RF} compile_commands.json
.PHONY: test
test: build
	${BC_ENVRUN} mypy ${BC_SCRIPTS}
	${BC_ENVRUN} ${BC_CMAKE_BUILD} ${BC_BUILD_PATH} test
.PHONY: test-verbose
test-verbose: build
	${BC_ENVRUN} ${BC_CTEST} ${BC_BUILD_PATH} --output-on-failure
.PHONY: test-rerun-verbose
test-rerun-verbose: build
	${BC_ENVRUN} ${BC_CTEST} ${BC_BUILD_PATH} --rerun-failed --output-on-failure

.PHONY: devenv-image
devenv-image:
	docker build . -t ${BC_DEVENV_IMAGE}
.PHONY: devenv-create
devenv-create:
	docker run -d \
		-e LOCAL_USER_ID=$(shell id -u ${USER}) \
		-e DISPLAY=$(DISPLAY) \
		-e QT_AUTO_SCREEN_SCALE_FACTOR=1 \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v /run/dbus/:/run/dbus/ \
		-v $(shell pwd):/usr/src/project \
		-v /dev/shm:/dev/shm \
		--restart=always \
		--name ${BC_DEVENV} \
		-t ${BC_DEVENV_IMAGE} bash
.PHONY: devenv-destroy
devenv-destroy:
	docker rm -f ${BC_DEVENV}
ifdef BC_ENVRUN
.PHONY: devenv-shell
devenv-shell:
	${BC_ENVRUN} bash
endif

ifdef BC_USE_VCPKG

.PHONY: vcpkg
vcpkg: ${BC_VCPKG_DIR} vcpkg-install

${BC_VCPKG_DIR}:
	${BC_ENVRUN} ${BC_RM_RF} ${BC_VCPKG_DIR}
	${BC_ENVRUN} mkdir -p ${BC_VCPKG_DIR_BASE}
	${BC_ENVRUN} git clone -b release --depth 1 --branch ${BC_VCPKG_VERSION} https://github.com/microsoft/vcpkg.git ${BC_VCPKG_DIR}
ifneq (${BC_OS},windows)
	${BC_ENVRUN} ${BC_VCPKG_DIR}/bootstrap-vcpkg.sh
else
	${BC_ENVRUN} ${BC_VCPKG_DIR}/bootstrap-vcpkg.bat
endif

.PHONY: vcpkg-install
vcpkg-install:
ifneq (${BC_OS},windows)
	${BC_ENVRUN} ${BC_VCPKG_DIR}/vcpkg install ${BC_VCPKG_PKGS}
else
	${BC_ENVRUN} ${BC_VCPKG_DIR}/vcpkg install --triplet x64-windows ${BC_VCPKG_PKGS}
endif

else ifdef USE_CONAN # USE_CONAN ################################################

.PHONY: setup-conan
conan-config:
	${BC_ENVRUN} conan profile new ${BC_PROJECT_NAME} --detect --force
ifeq ($(BC_OS),linux)
	${BC_ENVRUN} conan profile update settings.compiler.libcxx=libstdc++11 ${BC_PROJECT_NAME}
else
	${BC_ENVRUN} conan profile update settings.compiler.cppstd=20 ${BC_PROJECT_NAME}
ifeq ($(BC_OS),windows)
	${BC_ENVRUN} conan profile update settings.compiler.runtime=static ${BC_PROJECT_NAME}
endif
endif
.PHONY: conan
conan:
	${BC_ENVRUN} ${BC_PYBB} conan-install ${BC_PROJECT_NAME}
endif # USE_CONAN ###############################################

ifeq (${BC_OS},darwin)
.PHONY: configure-xcode
configure-xcode:
	${BC_ENVRUN} ${BC_SETUP_BUILD} ${BC_VCPKG_TOOLCHAIN} --build_tool=xcode --current_build=0 --build_root=${BC_BUILD_PATH}
endif

.PHONY: configure-release
configure-release:
	${BC_ENVRUN} ${BC_SETUP_BUILD} ${BC_VCPKG_TOOLCHAIN} --build_type=release --build_root=${BC_BUILD_PATH}

.PHONY: configure-debug
configure-debug:
	${BC_ENVRUN} ${BC_SETUP_BUILD} ${BC_VCPKG_TOOLCHAIN} --build_type=debug --build_root=${BC_BUILD_PATH}

.PHONY: configure-asan
configure-asan:
	${BC_ENVRUN} ${BC_SETUP_BUILD} ${BC_VCPKG_TOOLCHAIN} --build_type=asan --build_root=${BC_BUILD_PATH}

