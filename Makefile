PRODUCT_NAME=S2Geometry
PROJECT_OPTION="$(PRODUCT_NAME).xcodeproj"
XCBUILD=xcodebuild -project $(PROJECT_OPTION)

.PHONY: build compile

all: re

build:
	$(XCBUILD) build | xcpretty

clean:
	$(XCBUILD) clean | xcpretty

re: clean build

lint:
	./Support/Scripts/swiftlint.sh

test: clean test_macOS test_iOS_10.3

test_macOS:
	$(XCBUILD) -scheme "$(PRODUCT_NAME) macOS" -destination "arch=x86_64" test | xcpretty

test_iOS_10.3:
	$(XCBUILD) -scheme "$(PRODUCT_NAME) iOS" -destination "OS=10.3,name=iPhone 7 Plus" test | xcpretty

# test_iOS_9.0:
# 	$(XCBUILD) -scheme "$(PRODUCT_NAME) iOS" -destination "OS=9.0,name=iPhone 6" test | xcpretty

# test_iOS_8.1:
# 	$(XCBUILD) -scheme "$(PRODUCT_NAME) iOS" -destination "OS=8.1,name=iPhone 4S" test | xcpretty