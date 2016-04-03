export BUILDTYPE ?= Release
export ENABLE_COVERAGE ?= 0

ifeq ($(shell uname -s), Darwin)
  export JOBS ?= $(shell sysctl -n hw.ncpu)
else ifeq ($(shell uname -s), Linux)
  export JOBS ?= $(shell grep --count processor /proc/cpuinfo)
else
  $(error Cannot determine host platform)
endif

RUN = +$(MAKE) -f scripts/main.mk

default:
	@printf "You must specify a valid target\n"

#### OS X targets ##############################################################

.PHONY: osx
osx:
	$(RUN) PLATFORM=osx Xcode/osxapp

.PHONY: Xcode/osx
Xcode/osx:
	$(RUN) PLATFORM=osx Xcode/__project__

.PHONY: xproj
xproj: Xcode/osx
	open ./build/osx-x86_64/platform/osx/platform.xcodeproj

.PHONY: xpackage
xpackage: Xcode/osx
	./platform/osx/scripts/package.sh

.PHONY: xpackage-strip
xpackage-strip: Xcode/osx
	./platform/osx/scripts/package.sh strip

.PHONY: xctest
xctest: Xcode/osx
	./platform/osx/scripts/test.sh

#### iOS targets ##############################################################

.PHONY: ios
ios:
	$(RUN) PLATFORM=ios XCODEBUILD_ARGS='-sdk iphoneos ARCHS="arm64 armv7 armv7s"' Xcode/iosapp

.PHONY: isim
isim:
	$(RUN) PLATFORM=ios XCODEBUILD_ARGS='-sdk iphonesimulator ARCHS="x86_64 i386"' Xcode/iosapp

.PHONY: Xcode/ios
Xcode/ios:
	$(RUN) PLATFORM=ios Xcode/__project__

.PHONY: iproj
iproj: Xcode/ios
	open ./build/ios-all/gyp/ios.xcodeproj

.PHONY: ibench
ibench:
	$(RUN) PLATFORM=ios XCODEBUILD_ARGS='-sdk iphoneos ARCHS="arm64"' Xcode/ios-bench

.PHONY: ipackage
ipackage: Xcode/ios
	BITCODE=$(BITCODE) FORMAT=$(FORMAT) BUILD_DEVICE=$(BUILD_DEVICE) SYMBOLS=$(SYMBOLS) \
	BUNDLE_RESOURCES=YES PLACE_RESOURCE_BUNDLES_OUTSIDE_FRAMEWORK=YES \
	./platform/ios/scripts/package.sh

.PHONY: ipackage-strip
ipackage-strip: Xcode/ios
	BITCODE=$(BITCODE) FORMAT=$(FORMAT) BUILD_DEVICE=$(BUILD_DEVICE) SYMBOLS=NO \
	BUNDLE_RESOURCES=YES PLACE_RESOURCE_BUNDLES_OUTSIDE_FRAMEWORK=YES \
	./platform/ios/scripts/package.sh

.PHONY: ipackage-sim
ipackage-sim: Xcode/ios
	BUILDTYPE=Debug BITCODE=$(BITCODE) FORMAT=dynamic BUILD_DEVICE=false SYMBOLS=$(SYMBOLS) \
	BUNDLE_RESOURCES=YES PLACE_RESOURCE_BUNDLES_OUTSIDE_FRAMEWORK=YES \
	./platform/ios/scripts/package.sh

.PHONY: iframework
iframework: Xcode/ios
	BITCODE=$(BITCODE) FORMAT=dynamic BUILD_DEVICE=$(BUILD_DEVICE) SYMBOLS=$(SYMBOLS) \
	./platform/ios/scripts/package.sh

.PHONY: ifabric
ifabric: Xcode/ios
	BITCODE=$(BITCODE) FORMAT=$(FORMAT) BUILD_DEVICE=$(BUILD_DEVICE) SYMBOLS=NO BUNDLE_RESOURCES=YES \
	./platform/ios/scripts/package.sh

.PHONY: itest
itest: ipackage-sim
	./platform/ios/scripts/test.sh

.PHONY: idocument
idocument:
	OUTPUT=$(OUTPUT) ./platform/ios/scripts/document.sh

#### Android targets #####################################################

# Builds a particular android architecture.
android-lib-%:
	$(RUN) PLATFORM=android SUBPLATFORM=$* Makefile/all

# Builds the default Android library
.PHONY: android-lib
android-lib: android-lib-arm-v7

# Builds the selected/default Android library
.PHONY: android
android: android-lib
	cd platform/android && ./gradlew --parallel --max-workers=$(JOBS) assemble$(BUILDTYPE)

# Builds all android architectures for distribution.
.PHONY: apackage
apackage: android-lib-arm-v5 android-lib-arm-v7 android-lib-arm-v8 android-lib-x86 android-lib-x86-64 android-lib-mips
	cd platform/android && ./gradlew --parallel-threads=$(JOBS) assemble$(BUILDTYPE)

#### Node targets #####################################################

node_modules: package.json
	npm update # Install dependencies but don't run our own install script.

.PHONY: node
node: node_modules
	$(RUN) PLATFORM=node Makefile/node

.PHONY: xnode
xnode:
	$(RUN) Xcode/node
	./platform/node/scripts/create_node_scheme.sh "node test" "`npm bin tape`/tape platform/node/test/js/**/*.test.js"
	./platform/node/scripts/create_node_scheme.sh "npm run test-suite" "platform/node/test/render.test.js"
	open ./build/binding.xcodeproj

.PHONY: test-node
test-node: node
	npm test
	npm run test-suite

#### Miscellaneous targets #####################################################

.PHONY: linux
linux: glfw-app render offline

.PHONY: test-linux
test-linux: test-*

.PHONY: glfw-app
glfw-app:
	$(RUN) Makefile/glfw-app

.PHONY: run-glfw-app
run-glfw-app:
	$(RUN) run-glfw-app

.PHONY: run-valgrind-glfw-app
run-valgrind-glfw-app:
	$(RUN) run-valgrind-glfw-app

.PHONY: test
test:
	$(RUN) Makefile/test

test-%:
	$(RUN) test-$*

.PHONY: check
check:
	$(RUN) BUILDTYPE=Debug ENABLE_COVERAGE=1 check

coveralls:
	$(RUN) BUILDTYPE=Debug ENABLE_COVERAGE=1 coveralls

.PHONY: render
render:
	$(RUN) Makefile/mbgl-render

.PHONY: offline
offline:
	$(RUN) Makefile/mbgl-offline

# Generates a compilation database with ninja for use in clang tooling
.PHONY: compdb
compdb:
	$(RUN) Ninja/compdb

.PHONY: tidy
tidy:
	$(RUN) tidy

clean:
	-find ./deps/gyp -name "*.pyc" -exec rm {} \;
	-find ./build -type f -not -path '*/*.xcodeproj/*' -exec rm {} \;
	-rm -rf ./platform/*/build/ \
	        ./platform/android/MapboxGLAndroidSDK/build \
	        ./platform/android/MapboxGLAndroidSDKTestApp/build \
	        ./platform/android/MapboxGLAndroidSDK/src/main/jniLibs \
	        ./platform/android/MapboxGLAndroidSDKTestApp/src/main/jniLibs \
	        ./platform/android/MapboxGLAndroidSDK/src/main/assets

distclean: clean
	-rm -rf ./mason_packages
