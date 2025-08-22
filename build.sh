#!/bin/bash

# Build script for appdb install reporter dylib
# This script compiles the Objective-C sources into a dynamic library

set -e  # Exit on any error

# Configuration
SDK_PATH="$HOME/theos/sdks/iPhoneOS12.4.sdk"
OUTPUT_FILE="dbservices.dylib"
MIN_IOS_VERSION="12.0"
ARCH="arm64"

# Source files
SOURCES=(
    "Sources/dbservices/Tweak.m"
    "Sources/dbservices/constructor.m"
)

# Check if SDK exists
if [ ! -d "$SDK_PATH" ]; then
    echo "Error: iOS SDK not found at $SDK_PATH"
    echo "Please ensure the SDK is installed or update the SDK_PATH variable"
    exit 1
fi

# Check if source files exist
for source in "${SOURCES[@]}"; do
    if [ ! -f "$source" ]; then
        echo "Error: Source file not found: $source"
        exit 1
    fi
done

echo "Building $OUTPUT_FILE..."
echo "SDK: $SDK_PATH"
echo "Architecture: $ARCH"
echo "Minimum iOS version: $MIN_IOS_VERSION"

# Build command
clang -dynamiclib \
    -o "$OUTPUT_FILE" \
    -framework Foundation \
    -framework UIKit \
    -isysroot "$SDK_PATH" \
    -arch "$ARCH" \
    -mios-version-min="$MIN_IOS_VERSION" \
    "${SOURCES[@]}"

if [ $? -eq 0 ]; then
    echo "✅ Build successful: $OUTPUT_FILE"
    
    # Show file info
    if command -v file >/dev/null 2>&1; then
        echo "File info:"
        file "$OUTPUT_FILE"
    fi
    
    # Show file size
    if command -v ls >/dev/null 2>&1; then
        echo "File size:"
        ls -lh "$OUTPUT_FILE"
    fi
else
    echo "❌ Build failed"
    exit 1
fi
