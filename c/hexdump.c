/*
    Hexdump command line utility.

    Author: Darren Mulholland <dmulholland@outlook.ie>
    License: Public Domain
*/

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <string.h>


// Application version number.
char* version = "0.3.0";


// Command line help text.
char* helpText = 
	"Usage: hexdump [FILE] [OPTIONS]\n"
    "\n"
    "Arguments:\n"
    "  [FILE]                 File to read (default: STDIN)\n"
    "\n"
    "Options:\n"
    "  -l, --line <int>       Bytes per line in output (default: 16)\n"
    "  -b, --bytes <int>      Number of bytes to read (default: all)\n"
    "  -o, --offset <int>     Byte offset at which to begin reading\n"
    "\n"
    "Flags:\n"
    "  -h, --help             Display this help text and exit\n"
    "  -v, --version          Display the version number and exit\n";

// Write a single line of output to stdout.
void writeln(unsigned char* buffer, size_t numBytes, int offset, int bytesPerLine)
{
    // Write the line number.
    printf("%6X |", offset);

    for (int i = 0; i < bytesPerLine; i++) {

        // Write an extra space in front of every fourth byte except the first.
        if (i > 0 && i % 4 == 0) {
            printf(" ");
        }

        // Write the byte in hex form, or a spacer if we're out of bytes.
        if (i < numBytes) {
            printf(" %02X", buffer[i]);
        } else {
            printf("   ");
        }
    }

    printf(" | ");

    // Write a character for each byte in the printable ascii range.
    for (int i = 0; i < numBytes; i++) {
        printf("%c", isprint(buffer[i]) ? buffer[i] : '.');
    }

    printf("\n");
}

// Dump the specified file to stdout.
void dump(FILE* file, int offset, int bytesToRead, int bytesPerLine)
{
    // If an offset has been specified, attempt to seek to it.
    if (offset < 0) {
        // Get the file size.
        fseek(file, 0, SEEK_END);
        long file_size = ftell(file);
        if (file_size == -1) {
            fprintf(stderr, "Error: cannot determine file size.\n");
            exit(1);
        }

        // Adjust the offset to a positive value.
        offset = file_size + offset;
    }
    
    if (offset != 0) {
        if (fseek(file, offset, 0) != 0) {
            fprintf(stderr, "error: cannot locate offset in file\n");
            exit(1);
        }
    }

    // Allocate a buffer to hold one line of input from the file.
    unsigned char* buffer = (unsigned char*)malloc(bytesPerLine);
    if (buffer == NULL) {
        fprintf(stderr, "error: insufficient memory\n");
        exit(1);
    }

    // Number of bytes read by the last call to fread().
    size_t numBytes;

    // Maximum number of bytes to attempt to read per call to fread();
    size_t maxBytes;

    // Read and dump one line of input per iteration.
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
        numBytes = fread(buffer, sizeof(char), maxBytes, file);

        // Reading zero bytes means we've reached the end of the file.
        if (numBytes > 0) {
            writeln(buffer, numBytes, offset, bytesPerLine);
            offset += numBytes;
            bytesToRead -= numBytes;
        } else {
            break;
        }
    }

    free(buffer);
}


// Application entry point.
int main(int argc, char* argv[])
{
    // File offset at which to begin reading.
    int offset = 0;

    // Total number of bytes to read (-1 to read the entire file).
    int bytesToRead = -1;

    // Number of bytes per line to display in the output.
    int bytesPerLine = 16;

    // Input file.
    FILE* file;

    // Getopt variable for parsing command line arguments.
    int c;

    // Check for the presence of a --help or --version flag.
    for (int i = 0; i < argc; i++) {
        if (strcmp(argv[i], "--help") == 0) {
            printf("%s", helpText);
            exit(0);
        }
        else if (strcmp(argv[i], "--version") == 0) {
            printf("%s\n", version);
            exit(0);
        }
    }

    // Check for the presence of any command line options.
    while ((c = getopt(argc, argv, "o:n:l:")) != -1) {
        switch (c) {
            case 'o':
                offset = atoi(optarg);
                break;
            case 'n':
                bytesToRead = atoi(optarg);
                break;
            case 'l':
                bytesPerLine = atoi(optarg);
                break;
            case '?':
                fprintf(stderr, "\n%s", helpText);
                exit(1);
        }
    }

    // Default to reading from stdin if no filename has been specified.
    if (optind < argc) {
        file = fopen(argv[optind], "rb");
        if (file == NULL) {
            fprintf(stderr, "error: cannot open file '%s'\n", argv[optind]);
            exit(1);
        }
        dump(file, offset, bytesToRead, bytesPerLine);
        fclose(file);
    } else {
        dump(stdin, offset, bytesToRead, bytesPerLine);
    }

    return 0;
}