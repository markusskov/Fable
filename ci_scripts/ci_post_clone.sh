#!/bin/sh
# Xcode Cloud post-clone hook: the .xcodeproj is generated, never committed
# (see ADR 0002), so every cloud build regenerates it before Xcode looks
# for the project.
set -e
brew install xcodegen
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate
