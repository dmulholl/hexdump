/*
    Hex dump command line utility.

    Option parsing code is taken from the Mono project
    (https://github.com/mono/mono) and is released under the MIT license.

    Author: Darren Mulholland <dmulholland@outlook.ie>
    License: Public Domain
*/

using System;
using System.IO;
using System.Collections.Generic;
using Mono.Options;


class Program
{
    static string version = "0.2.0";

    static string usage =

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


    static void Main(string[] argv)
    {
        int offset = 0;
        int bytesToRead = -1;
        int bytesPerLine = 16;
        bool debug = false;
        List<string> args = null;

        OptionSet options = new OptionSet()
            .Add("o=", v => offset = int.Parse(v))
            .Add("n=", v => bytesToRead = int.Parse(v))
            .Add("l=", v => bytesPerLine = int.Parse(v))
            .Add("debug", v => debug = true)
            .Add("help", v => ShowHelp())
            .Add("version", v => ShowVersion());

        try
        {
            args = options.Parse(argv);
        }
        catch (OptionException e)
        {
            Console.Error.WriteLine("Error: {0}", e.Message);
            Environment.Exit(1);
        }
        catch (FormatException)
        {
            Console.Error.WriteLine("Error: Invalid argument.");
            Environment.Exit(1);
        }
        catch (OverflowException)
        {
            Console.Error.WriteLine("Error: Invalid argument.");
            Environment.Exit(1);
        }

        try
        {
            if (args.Count > 0) {
                using (Stream file = new FileStream(args[0], FileMode.Open))
                {
                    Dump(file, offset, bytesToRead, bytesPerLine);
                }
            } else {
                Stream file = Console.OpenStandardInput();
                Dump(file, offset, bytesToRead, bytesPerLine);
            }
        }
        catch (Exception e)
        {
            if (debug) {
                Console.Error.WriteLine(e);
            } else {
                Console.Error.WriteLine("Error: {0}", e.Message);
            }
            Environment.Exit(1);
        }
    }


    static void Dump(Stream file, int offset, int bytesToRead, int bytesPerLine)
    {
        if (offset != 0) {
            if (file.CanSeek) {
                try
                {
                    file.Seek(offset, SeekOrigin.Begin);
                }
                catch (IOException)
                {
                    Console.Error.WriteLine("Error: cannot seek to offset {0}.", offset);
                    Environment.Exit(1);
                }
            } else {
                Console.Error.WriteLine("Error: file is not seekable.");
                Environment.Exit(1);
            }
        }

        byte[] buffer = new byte[bytesPerLine];
        int n;

        while (true)
        {
            if (bytesToRead > -1 && bytesToRead < bytesPerLine) {
                n = file.Read(buffer, 0, bytesToRead);
            } else {
                n = file.Read(buffer, 0, bytesPerLine);
            }
            if (n > 0) {
                WriteLine(buffer, n, offset, bytesPerLine);
                offset += n;
                bytesToRead -= n;
            } else {
                break;
            }
        }
    }


    static void WriteLine(byte[] buffer, int numBytes, int offset, int bytesPerLine)
    {
        Console.Write("{0,6:X} |", offset);

        for (int i = 0; i < bytesPerLine; i++) {
            if (i < numBytes) {
                Console.Write(" {0:X2}", buffer[i]);
            } else {
                Console.Write("   ");
            }
            if ((i + 1) % 4 == 0 && i != bytesPerLine - 1) {
                Console.Write(" ");
            }
        }

        Console.Write(" | ");
        for (int i = 0; i < numBytes; i++) {
            if (buffer[i] >= 32 && buffer[i] <= 126) {
                Console.Write((char)buffer[i]);
            } else {
                Console.Write(".");
            }
        }

        Console.WriteLine();
    }


    static void ShowHelp()
    {
        Console.WriteLine(usage);
        Environment.Exit(0);
    }


    static void ShowVersion()
    {
        Console.WriteLine(version);
        Environment.Exit(0);
    }
}
