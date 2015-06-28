#!/usr/bin/env swift
/*
    Hex dump command line utility.

    This code was written to target Swift 1.1 (November 2014), an early
    and surprisingly immature release of the language. It won't compile
    with later versions as 1.2 introduced backwards-compatibility-breaking
    changes.

    Author: Darren Mulholland <dmulholland@outlook.ie>
    License: Public Domain
*/

import Foundation


let version = "0.2.0"


let usage =
    "Usage: hexdump [FLAGS] [OPTIONS] ARGUMENTS\n" +
    "\n" +
    "Arguments:\n" +
    "  <file>     file to dump (default: stdin)\n" +
    "\n" +
    "Options:\n" +
    "  -l <int>   bytes per line in output (default: 16)\n" +
    "  -n <int>   number of bytes to read\n" +
    "  -o <int>   byte offset at which to begin reading\n" +
    "\n" +
    "Flags:\n" +
    "  --help     display this help text and exit\n" +
    "  --version  display version number and exit"


func main() {

    var offset = 0
    var bytesToRead = -1
    var bytesPerLine = 16

    for arg in Process.arguments {
        if arg == "--help" {
            println(usage)
            exit(0)
        } else if arg == "--version" {
            println(version)
            exit(0)
        }
    }

    loop: while true {
        switch getopt(C_ARGC, C_ARGV, Array("o:n:l:".utf8).map { Int8($0) }) {
            case  -1: // no more options to process
                break loop
            case  63: // ascii "?" - the getopt error signal
                println()
                println(usage)
                exit(1)
            case 108: // ascii "l"
                bytesPerLine = String.fromCString(optarg)!.toInt()!
            case 110: // ascii "n"
                bytesToRead = String.fromCString(optarg)!.toInt()!
            case 111: // ascii "o"
                offset = String.fromCString(optarg)!.toInt()!
            default:
                println(usage)
                exit(1)
        }
    }

    if (optind < C_ARGC) {
        let path = String.fromCString(C_ARGV[Int(optind)])!
        let file = NSFileHandle(forReadingAtPath: path)
        if file == nil {
            println("Error: cannot open file '\(path)'.")
            exit(1)
        }
        dump(file!, offset, bytesToRead, bytesPerLine)
        file?.closeFile()
    } else {
        dump(NSFileHandle.fileHandleWithStandardInput(), offset, bytesToRead, bytesPerLine)
    }
}


func dump(file: NSFileHandle, var offset: Int, var bytesToRead: Int, bytesPerLine: Int) {

    var data: NSData

    // Attempting to seek into an unseekable stream will throw an exception
    // that we have no way of handling.
    if offset != 0 {
        file.seekToFileOffset(UInt64(offset))
    }

    // Read operations can throw exceptions that we have no way of handling.
    while true {
        if bytesToRead > -1 && bytesToRead < bytesPerLine {
            data = file.readDataOfLength(bytesToRead)
        } else {
            data = file.readDataOfLength(bytesPerLine)
        }
        if data.length > 0 {
            writeln(data, offset, bytesPerLine)
            offset += data.length
            bytesToRead -= data.length
        } else {
            break
        }
    }
}


func writeln(data: NSData, offset: Int, bytesPerLine: Int) {

    let bytes = UnsafePointer<UInt8>(data.bytes)

    print(String(format: "%6X |", offset))

    for i in 0 ..< bytesPerLine {
        if i < data.length {
            print(String(format: " %02X", bytes[i]))
        } else {
            print("   ")
        }
        if ((i + 1) % 4 == 0 && i != bytesPerLine - 1) {
            print(" ")
        }
    }

    print(" | ")
    for i in 0 ..< data.length {
        if bytes[i] >= 32 && bytes[i] <= 126 {
            print(String(format: "%c", bytes[i]))
        } else {
            print(".")
        }
    }
    println()
}


main()
