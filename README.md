# appdb Install Reporter

A dynamic library for iOS applications that automatically reports installation data to appdb.

## Overview

This project creates a dynamic library (`dbservices.dylib`) that can be injected into iOS applications to automatically report installation information to the appdb backend.

## Features

- **Automatic Installation Reporting**: Reports app installations with metadata
- **Thread-Safe Operations**: Uses serial dispatch queues for safe concurrent access
- **Error Handling**: Comprehensive error handling and logging
- **iOS Compatibility**: Supports iOS 12.0 and later

## Architecture

The project consists of two main components:

### 1. InstallReporter (`Tweak.m`)
- Main reporting logic implemented in Objective-C
- Collects installation metadata from the app's Info.plist
- Sends HTTPS requests to the appdb
- Thread-safe with proper queue management

### 2. Constructor (`constructor.m`)
- Automatic initialization when the dylib is loaded
- Uses `__attribute__((constructor))` for immediate execution
- Bridges C and Objective-C components

## Data Collected

The library collects the following information:
- Installation UUID
- Apple Team Identifier
- iOS System Version
- Bundle Identifier
- Process ID and Thread Information

## Building

### Prerequisites
- Xcode command line tools
- iOS SDK (default path: `$HOME/theos/sdks/iPhoneOS12.4.sdk`)
- clang compiler

### Build Instructions

1. **Using the build script:**
   ```bash
   ./build.sh
   ```

## Usage

⚠️ **Security Notice**: This library is intended for security research and transparency purposes only. Unauthorized use or redistribution is prohibited.

1. Build the dynamic library using the instructions above
2. Inject the library into target applications using appropriate tools
3. Monitor logs for installation reporting activity

## Logging

The library provides detailed logging with the `appdb:` prefix. All operations are logged for debugging and monitoring purposes.

Example log output:
```
appdb: dylib constructor called in process 1234, thread 0x1a2b3c4d
appdb: reporting install (Objective-C)
appdb: installationUUID: ABC123-DEF456
appdb: iOS version: 15.0
appdb: Bundle identifier: com.example.app
```

## Technical Details

- **Language**: Objective-C with C components
- **Frameworks**: Foundation, UIKit
- **Threading**: Serial dispatch queue for thread safety
- **Network**: NSURLSession with 30-second timeout
- **Error Handling**: Comprehensive exception handling

## Security Considerations

- All network communications use HTTPS
- Data is tokenized
- Thread-safe implementation prevents race conditions
- Comprehensive error handling prevents crashes

## File Structure

```
src/
├── README.md                    # This file
├── LICENSE.md                   # License and usage restrictions
├── build.sh                     # Build script
└── Sources/
    └── dbservices/
        ├── Tweak.m             # Main reporting logic
        └── constructor.m       # Automatic initialization
```

## License

Copyright (c) appdb. All rights reserved. See LICENSE.md for usage restrictions.

## Disclaimer

This software is provided for security research and transparency purposes only.