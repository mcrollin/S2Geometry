#!/bin/sh

swiftlint version || (echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint" && exit 1)
swiftlint ${@:1}