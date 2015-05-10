/*
    Hex dump command line utility.

    Author: Darren Mulholland <dmulholland@outlook.ie>
    License: Public Domain
*/

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include <string.h>


char* version = "0.2.0";


char* helpText =
    "Usage: hexdump [FLAGS] [OPTIONS] ARGUMENTS\n"
    "\n"
    "Arguments:\n"
    "  <file>     file to dump (default: stdin)\n"
    "\n"
    "Options:\n"
    "  -l <int>   bytes per line in output (default: 16)\n"
    "  -n <int>   number of bytes to read\n"
    "  -o <int>   byte offset at which to begin reading\n"
    "\n"
    "Flags:\n"
    "  --help     display this help text and exit\n"
    "  --version  display version number and exit\n";


void writeln(unsigned char* buffer, size_t numBytes, int offset, int bytesPerLine)
{
    printf("%6X |", offset);

    for (int i = 0; i < bytesPerLine; i++) {
        if (i < numBytes) {
            printf(" %02X", buffer[i]);
        } else {
            printf("   ");
        }
        if ((i + 1) % 4 == 0 && i != bytesPerLine - 1) {
            printf(" ");
        }
    }

    printf(" | ");
    for (int i = 0; i < numBytes; i++) {
        printf("%c", isprint(buffer[i]) ? buffer[i] : '.');
    }

    printf("\n");
}


void dump(FILE* file, int offset, int bytesToRead, int bytesPerLine)
{
    if (offset != 0) {
        if (fseek(file, offset, 0) != 0) {
            fprintf(stderr, "error: cannot locate offset in file\n");
            exit(1);
        }
    }

    unsigned char* buffer = (unsigned char*)malloc(bytesPerLine);
    if (buffer == NULL) {
        fprintf(stderr, "error: insufficient memory\n");
        exit(1);
    }

    size_t n;
    while (true) {
        if (bytesToRead > -1 && bytesToRead < bytesPerLine) {
            n = fread(buffer, sizeof(char), bytesToRead, file);
        } else {
            n = fread(buffer, sizeof(char), bytesPerLine, file);
        }
        if (n > 0) {
            writeln(buffer, n, offset, bytesPerLine);
            offset += n;
            bytesToRead -= n;
        } else {
            break;
        }
    }

    free(buffer);
}


int main(int argc, char* argv[])
{
    int offset = 0;
    int bytesToRead = -1;
    int bytesPerLine = 16;
    int c;
    FILE* file;

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
