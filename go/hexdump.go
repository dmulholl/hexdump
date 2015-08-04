/*
    Hexdump command line utility.

      * Author: Darren Mulholland <dmulholland@outlook.ie>
      * License: Public Domain

*/
package main


import (
    "io"
    "fmt"
    "flag"
    "os"
)


// Application version number.
const version = "0.3.0"


// Command line help text.
const usage = `Usage: godump [FLAGS] [OPTIONS] ARGUMENTS

Arguments:
  <file>     file to dump (default: stdin)

Options:
  -l <int>   bytes per line in output (default: 16)
  -n <int>   number of bytes to read
  -o <int>   byte offset at which to begin reading

Flags:
  --help     display this help text and exit
  --version  display version number and exit`


// Write a single line of output to stdout.
func writeln(buffer []byte, numBytes int, offset int, bytesPerLine int) {

    // Write the line number.
    fmt.Printf("% 6X |", offset)

    for i := 0; i < bytesPerLine; i++ {

        // Write an extra space in front of every fourth byte except the first.
        if i > 0 && i % 4 == 0 {
            fmt.Printf(" ")
        }

        // Write the byte in hex form, or a spacer if we're out of bytes.
        if i < numBytes {
            fmt.Printf(" %02X", buffer[i])
        } else {
            fmt.Printf("   ")
        }
    }

    fmt.Printf(" | ")

    // Write a character for each byte in the printable ascii range.
    for i, b := range buffer {
        if i < numBytes {
            if b >= 32 && b <= 126 {
                fmt.Printf("%c", b)
            } else {
                fmt.Printf(".")
            }
        }
    }

    fmt.Printf("\n")
}


// Dump the specified file to stdout.
func dump(file *os.File, offset int, bytesToRead int, bytesPerLine int) {

    // If an offset has been specified, attempt to seek to it.
    if offset != 0 {
        _, err := file.Seek(int64(offset), 0)
        if err != nil {
            fmt.Println(err)
            os.Exit(1)
        }
    }

    // Allocate a buffer to hold one line of input from the file.
    buffer := make([]byte, bytesPerLine)

    // Read and dump one line of input per iteration.
    for {
        if bytesToRead > -1 && bytesToRead < bytesPerLine {
            buffer = make([]byte, bytesToRead)
        }
        n, err := file.Read(buffer)
        if err != nil && err != io.EOF {
            fmt.Println(err)
            os.Exit(1)
        }
        if n > 0 {
            writeln(buffer, n, offset, bytesPerLine)
            offset += n
            bytesToRead -= n
        } else {
            break
        }
    }
}


// Application entry point.
func main() {

    // Command line options.
    var offset = flag.Int("o", 0, "offset into file")
    var bytesToRead = flag.Int("n", -1, "number of bytes to read")
    var bytesPerLine = flag.Int("l", 16, "bytes per line in output")

    // Command line flags.
    var printHelp = flag.Bool("help", false, "print help and exit")
    var printVersion = flag.Bool("version", false, "print version and exit")

    // Called if an error occurs while parsing flags.
    flag.Usage = func() {
        fmt.Println()
        fmt.Println(usage)
    }

    // Parse the command line arguments.
    flag.Parse()

    // Check if the --help flag is present.
    if *printHelp {
        fmt.Println(usage)
        os.Exit(0)
    }

    // Check if the --version flag is present.
    if *printVersion {
        fmt.Println(version)
        os.Exit(0)
    }

    // Default to reading from stdin if no filename has been specified.
    if flag.NArg() > 0 {
        file, err := os.Open(flag.Arg(0))
        if err != nil {
            fmt.Println(err)
            os.Exit(1)
        }
        defer file.Close()
        dump(file, *offset, *bytesToRead, *bytesPerLine)
    } else {
        dump(os.Stdin, *offset, *bytesToRead, *bytesPerLine)
    }
}
