/*
    Hexdump command line utility.

    Author: Darren Mulholland <dmulholland@outlook.ie>
    License: Public Domain
*/

import java.io.*;


class Hexdump {

    // Application version number.
    static String version = "0.1.0";


    // Command line help text.
    static String helptext =
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
        "  --version  display version number and exit";


    // Application entry point.
    public static void main(String args[]) {

        // Number of bytes per line to display in the output.
        int bytesPerLine = 16;

        // Total number of bytes to read (-1 to read the entire file).
        int bytesToRead = -1;

        // File offset at which to begin reading.
        int offset = 0;

        // Name of the file to read. Default to reading from stdin.
        String filename = null;

        // Index for looping over the command line arguments.
        int index = -1;

        // Check for the presence of a --help or --version flag.
        for (String arg: args) {
            if (arg.equals("--help")) {
                System.out.println(helptext);
                System.exit(0);
            }
            else if (arg.equals("--version")) {
                System.out.println(version);
                System.exit(0);
            }
        }

        // Check for the presence of any command line options.
        while (++index < args.length) {

            // Check for the presence of the -l option.
            if (args[index].equals("-l")) {
                if (++index < args.length) {
                    try {
                        bytesPerLine = Integer.parseInt(args[index]);
                    }
                    catch (NumberFormatException e) {
                        System.out.println("Error: invalid argument for the -l option.");
                        System.exit(1);
                    }
                } else {
                    System.out.println("Error: missing argument for -l option.");
                    System.exit(1);
                }
            }

            // Check for the presence of the -n option.
            else if (args[index].equals("-n")) {
                if (++index < args.length) {
                    try {
                        bytesToRead = Integer.parseInt(args[index]);
                    }
                    catch (NumberFormatException e) {
                        System.out.println("Error: invalid argument for the -n option.");
                        System.exit(1);
                    }
                } else {
                    System.out.println("Error: missing argument for -n option.");
                    System.exit(1);
                }
            }

            // Check for the presence of the -o option.
            else if (args[index].equals("-o")) {
                if (++index < args.length) {
                    try {
                        offset = Integer.parseInt(args[index]);
                    }
                    catch (NumberFormatException e) {
                        System.out.println("Error: invalid argument for the -o option.");
                        System.exit(1);
                    }
                } else {
                    System.out.println("Error: missing argument for -o option.");
                    System.exit(1);
                }
            }

            // Assume a non-option argument is a filename.
            else {
                filename = args[index];
            }
        }

        // Default to reading from stdin if no filename has been specified.
        if (filename == null) {
            dumpFile(System.in, offset, bytesToRead, bytesPerLine);
        } else {
            try (FileInputStream file = new FileInputStream(filename)) {
                dumpFile(file, offset, bytesToRead, bytesPerLine);
            }
            catch (FileNotFoundException e) {
                System.out.println("Error: file not found.");
                System.exit(1);
            }
            catch (IOException e) {
                System.out.println(e);
                System.exit(1);
            }
        }
    }


    // Dump the specified file to stdout.
    static void dumpFile(InputStream file, int offset, int bytesToRead, int bytesPerLine) {

        // Buffer for storing bytes read from the file.
        byte[] buffer = new byte[bytesPerLine];

        // Maximum number of bytes to attempt to read per call to file.read().
        int maxBytes;

        // Number of bytes read by a call to file.read().
        int numBytes = 0;

        // If an offset has been specified, attempt to seek to it.
        if (offset != 0) {
            try {
                if (file.skip(offset) < offset) {
                    System.out.println("Error while attempting to seek to the specified offset.");
                    System.exit(1);
                }
            }
            catch (IOException e) {
                System.out.println("Error while attempting to seek to the specified offset.");
                System.exit(1);
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
            try {
                numBytes = file.read(buffer, 0, maxBytes);
            }
            catch (IOException e) {
                System.out.println(e);
                System.exit(1);
            }

            // Write a line of output.
            if (numBytes > 0) {
                writeLine(buffer, numBytes, offset, bytesPerLine);
                offset += numBytes;
                bytesToRead -= numBytes;
            } else {
                break;
            }
        }
    }


    // Write a single line of output to stdout.
    static void writeLine(byte[] buffer, int numBytes, int offset, int bytesPerLine) {

        // Write the line number.
        System.out.printf("%6X |", offset);

        for (int i = 0; i < bytesPerLine; i++) {

            // Write an extra space in front of every fourth byte except the first.
            if (i > 0 && i % 4 == 0) {
                System.out.print(" ");
            }

            // Write the byte in hex form, or a spacer if we're out of bytes.
            if (i < numBytes) {
                System.out.printf(" %02X", buffer[i]);
            } else {
                System.out.print("   ");
            }
        }

        System.out.print(" | ");

        // Write a character for each byte in the printable ascii range.
        for (int i = 0; i < numBytes; i++) {
            if (buffer[i] > 31 && buffer[i] < 127) {
                System.out.print((char)buffer[i]);
            } else {
                System.out.print(".");
            }
        }

        System.out.println();
    }
}
