/*
    Hexdump command line utility.

    Author: Darren Mulholland <dmulholland@outlook.ie>
    License: Public Domain
*/

using System;
using System.IO;
using System.Collections.Generic;


class Hexdump {

    // Application version number.
    static string version = "0.3.0";


    // Command line help text.
    static string helptext =

@"Usage: hexdump [FLAGS] [OPTIONS] ARGUMENTS

Arguments:
  <file>     file to dump (default: stdin)

Options:
  -l <int>   bytes per line in output (default: 16)
  -n <int>   number of bytes to read
  -o <int>   byte offset at which to begin reading

Flags:
  --help     display this help text and exit
  --version  display version number and exit";


    // Application entry point.
    static void Main(string[] args) {

        // File offset at which to begin reading.
        int offset = 0;

        // Total number of bytes to read (-1 to read the entire file).
        int bytesToRead = -1;

        // Number of bytes per line to display in the output.
        int bytesPerLine = 16;

        // Name of the file to read. Default to reading from stdin.
        string filename = null;

        // Index for looping over the command line arguments.
        int index = -1;

        // Check for the presence of a --help or --version flag.
        foreach (string arg in args) {
            if (arg == "--help") {
                Console.WriteLine(helptext);
                Environment.Exit(0);
            }
            else if (arg == "--version") {
                Console.WriteLine(version);
                Environment.Exit(0);
            }
        }

        // Check for the presence of any command line options.
        while (++index < args.Length) {

            // Check for the -l <bytes-per-line> option.
            if (args[index] == "-l") {
                if (++index < args.Length) {
                    try {
                        bytesPerLine = Int32.Parse(args[index]);
                    }
                    catch (FormatException) {
                        Console.WriteLine("Error: invalid argument for the -l option.");
                        Environment.Exit(1);
                    }
                } else {
                    Console.WriteLine("Error: missing argument for -l option.");
                    Environment.Exit(1);
                }
            }

            // Check for the -n <bytes-to-read> option.
            else if (args[index] == "-n") {
                if (++index < args.Length) {
                    try {
                        bytesToRead = Int32.Parse(args[index]);
                    }
                    catch (FormatException) {
                        Console.WriteLine("Error: invalid argument for the -n option.");
                        Environment.Exit(1);
                    }
                } else {
                    Console.WriteLine("Error: missing argument for -n option.");
                    Environment.Exit(1);
                }
            }

            // Check for the -o <offset> option
            else if (args[index] == "-o") {
                if (++index < args.Length) {
                    try {
                        offset = Int32.Parse(args[index]);
                    }
                    catch (FormatException) {
                        Console.WriteLine("Error: invalid argument for the -o option.");
                        Environment.Exit(1);
                    }
                } else {
                    Console.WriteLine("Error: missing argument for -o option.");
                    Environment.Exit(1);
                }
            }

            // Assume a non-option argument is a filename.
            else {
                filename = args[index];
            }
        }

        // Default to reading from stdin if no filename has been specified.
        try {
            if (filename == null) {
                DumpFile(Console.OpenStandardInput(), offset, bytesToRead, bytesPerLine);
            } else {
                using (Stream file = new FileStream(filename, FileMode.Open)) {
                    DumpFile(file, offset, bytesToRead, bytesPerLine);
                }
            }
        }
        catch (Exception e) {
            Console.Error.WriteLine("Error: {0}.", e.Message);
            Environment.Exit(1);
        }
    }


    // Dump the specified file to stdout.
    static void DumpFile(Stream file, int offset, int bytesToRead, int bytesPerLine) {

        // Buffer for storing a single line of input read from the file.
        byte[] buffer = new byte[bytesPerLine];

        // Maximum number of bytes to attempt to read per call to file.Read().
        int maxBytes;

        // Number of bytes read by a call to file.Read().
        int numBytes = 0;

        // If an offset has been specified, attempt to seek to it.
        if (offset != 0) {
            if (file.CanSeek) {
                try {
                    file.Seek(offset, SeekOrigin.Begin);
                }
                catch (IOException) {
                    Console.Error.WriteLine("Error: cannot seek to offset {0}.", offset);
                    Environment.Exit(1);
                }
            } else {
                Console.Error.WriteLine("Error: file is not seekable.");
                Environment.Exit(1);
            }
        }

        // Read and dump one line of output per iteration.
        while (true) {

            // If bytesToRead < 0 (read all), try to read one full line.
            if (bytesToRead < 0) {
                maxBytes = bytesPerLine;
            }

            // Else if line length < bytesToRead, try to read one full line.
            else if (bytesPerLine < bytesToRead) {
                maxBytes = bytesPerLine;
            }

            // Otherwise, try to read all the remaining bytes in one go.
            else {
                maxBytes = bytesToRead;
            }

            // Attempt to read up to maxBytes from the file.
            numBytes = file.Read(buffer, 0, maxBytes);

            // Write a line of output.
            if (numBytes > 0) {
                WriteLine(buffer, numBytes, offset, bytesPerLine);
                offset += numBytes;
                bytesToRead -= numBytes;
            } else {
                break;
            }
        }
    }


    // Write a single line of output to stdout.
    static void WriteLine(byte[] buffer, int numBytes, int offset, int bytesPerLine) {

        // Write the line number.
        Console.Write("{0,6:X} |", offset);

        for (int i = 0; i < bytesPerLine; i++) {

            // Write an extra space in front of every fourth byte except the first.
            if (i > 0 && i % 4 == 0) {
                Console.Write(" ");
            }

            // Write the byte in hex form, or a spacer if we're out of bytes.
            if (i < numBytes) {
                Console.Write(" {0:X2}", buffer[i]);
            } else {
                Console.Write("   ");
            }
        }

        Console.Write(" | ");

        // Write a character for each byte in the printable ascii range.
        for (int i = 0; i < numBytes; i++) {
            if (buffer[i] >= 32 && buffer[i] <= 126) {
                Console.Write((char)buffer[i]);
            } else {
                Console.Write(".");
            }
        }

        Console.WriteLine();
    }
}
