<img src="https://github.com/daisuke-t-jp/xxHash-Swift/blob/master/doc/header.png" width="700"></br>
------
![Platform](https://img.shields.io/badge/Platform-iOS%2010.0+%20%7C%20macOS%2010.12+%20%7C%20tvOS%2012.0+-blue.svg)
[![Language Swift%204.2](https://img.shields.io/badge/Language-Swift%204.2-orange.svg)](https://developer.apple.com/swift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-green.svg)](https://github.com/Carthage/Carthage)
[![Cocoapods](https://img.shields.io/cocoapods/v/xxHash-Swift.svg)](https://cocoapods.org/pods/xxHash-Swift)
[![Build Status](https://travis-ci.org/daisuke-t-jp/xxHash-Swift.svg?branch=master)](https://travis-ci.org/daisuke-t-jp/xxHash-Swift)


# Introduction

[xxHash](https://github.com/Cyan4973/xxHash/) framework in Swift.  
Framework include xxHash 32/64 bit functions.  
  
Original xxHash algorithm created by [Yann Collet](https://github.com/Cyan4973).
  
Reference:
- [cyan4973.github.io/xxHash](https://cyan4973.github.io/xxHash/)



# Install
## Carthage
`github "daisuke-t-jp/xxHash-Swift"`

## CocoaPods
```
use_frameworks!

target 'target' do
pod 'xxHash-Swift'
end
```


# Usage
## Import framework

```swift
import xxHash_Swift
```

## Generate Hash(One-shot)
### 32bit Version
```swift
let hash = xxHash32.digest("123456789ABCDEF")
// hash -> 0x576e3cf9

// Using seed.
let hash = xxHash32.digest("123456789ABCDEF", seed: 0x7fffffff)
// hash -> 0xa7f06f9d
```

### 64bit Version
```swift
let hash = xxHash64.digest("123456789ABCDEF")
// hash -> 0xa66df83f00e9202d

// Using seed.
let hash = xxHash64.digest("123456789ABCDEF", seed: 0x000000007fffffff)
// hash -> 0xe8d84202a16e482f
```


## Generate Hash(Streaming)
### 32bit Version
```swift
// Create xxHash instance
let xxh = xxHash32() // if using seed, e.g. "xxHash(0x7fffffff)"

// Get data from file
let bundle = Bundle(for: type(of: self))
let path = bundle.path(forResource: "alice29", ofType: "txt")!
let data = NSData(contentsOfFile: path)
let array = [UInt8](data! as Data)

let bufSize = 1024
var index = 0
var flag = true


repeat {
    // Prepare buffer
    var buf = [UInt8]()
    for _ in 0..<bufSize {
        buf.append(array[index])
        index += 1
        if index >= array.count {
            flag = false
            break
        }   
    }
 
    // xxHash update
    xxh.update(buf)

} while(flag)

let hash = xxh.digest()
// hash -> 0xafc8e0c2
```

### 64bit Version
```swift
// Create xxHash instance
let xxh = xxHash64() // if using seed, e.g. "xxHash(0x0000007fffffff)"

// Get data from file
let bundle = Bundle(for: type(of: self))
let path = bundle.path(forResource: "alice29", ofType: "txt")!
let data = NSData(contentsOfFile: path)
let array = [UInt8](data! as Data)

let bufSize = 1024
var index = 0
var flag = true


repeat {
    // Prepare buffer
    var buf = [UInt8]()
    for _ in 0..<bufSize {
        buf.append(array[index])
        index += 1
        if index >= array.count {
            flag = false
            break
        }   
    }
 
    // xxHash update
    xxh.update(buf)

} while(flag)

let hash = xxh.digest()
// hash -> 0x843c2c4ccfbfb749
```
