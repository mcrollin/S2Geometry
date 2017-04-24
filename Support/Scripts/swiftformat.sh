#!/bin/sh

swiftformat --version || (echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat" && exit 1)
swiftformat --disable trailingCommas ${@:1}