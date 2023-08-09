PROJECT_NAME=CppProject
BUILDCORE_PATH=deps/buildcore
VCPKG_PKGS=
include ${BUILDCORE_PATH}/base.mk

ifeq ($(OS),darwin)
	PROJECT_EXECUTABLE=./build/${CURRENT_BUILD}/${PROJECT_NAME}.app/Contents/MacOS/${PROJECT_NAME}
else
	PROJECT_EXECUTABLE=./build/${CURRENT_BUILD}/bin/${PROJECT_NAME}
endif

.PHONY: run
run: build
	${ENV_RUN} ${PROJECT_EXECUTABLE}
.PHONY: debug
debug: build
	${ENV_RUN} ${DEBUGGER} ${PROJECT_EXECUTABLE}
