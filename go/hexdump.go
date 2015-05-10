/*
    Hex dump command line utility.

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


const version = "0.2.0"


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


func writeln(buffer []byte, numBytes int, offset int, bytesPerLine int) {

    fmt.Printf("% 6X |", offset)

    for i := 0; i < bytesPerLine; i++ {
        if i < numBytes {
            fmt.Printf(" %02X", buffer[i])
        } else {
            fmt.Printf("   ")
        }
        if (i + 1) % 4 == 0 && i != bytesPerLine - 1 {
            fmt.Printf(" ")
        }
    }

    fmt.Printf(" | ")
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


func dump(file *os.File, offset int, bytesToRead int, bytesPerLine int) {

    if offset != 0 {
        _, err := file.Seek(int64(offset), 0)
        if err != nil {
            fmt.Println(err)
            os.Exit(1)
        }
    }

    buffer := make([]byte, bytesPerLine)

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


func main() {

    var offset = flag.Int("o", 0, "offset into file")
    var bytesToRead = flag.Int("n", -1, "number of bytes to read")
    var bytesPerLine = flag.Int("l", 16, "bytes per line in output")
    var printHelp = flag.Bool("help", false, "print help and exit")
    var printVersion = flag.Bool("version", false, "print version and exit")

    flag.Usage = func() {
        fmt.Println()
        fmt.Println(usage)
    }

    flag.Parse()

    if *printHelp {
        fmt.Println(usage)
        os.Exit(0)
    }

    if *printVersion {
        fmt.Println(version)
        os.Exit(0)
    }

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
