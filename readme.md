
Hexdump
=======

A simple hexdump command line utility, implemented in a variety of languages including C, C#, Go, Java, Python, Rust, Swift, and x86 assembly.

The output and command line interface are the same in all implementations.

Sample output:

    $ hexdump -n 128 sample.txt
         0 | 47 61 6C 6C  69 61 20 65  73 74 20 6F  6D 6E 69 73 | Gallia est omnis
        10 | 20 64 69 76  69 73 61 20  69 6E 20 70  61 72 74 65 |  divisa in parte
        20 | 73 20 74 72  65 73 2C 20  71 75 61 72  75 6D 20 75 | s tres, quarum u
        30 | 6E 61 6D 20  69 6E 63 6F  6C 75 6E 74  20 42 65 6C | nam incolunt Bel
        40 | 67 61 65 2C  20 61 6C 69  61 6D 20 41  71 75 69 74 | gae, aliam Aquit
        50 | 61 6E 69 2C  20 74 65 72  74 69 61 6D  20 71 75 69 | ani, tertiam qui
        60 | 20 69 70 73  6F 72 75 6D  20 6C 69 6E  67 75 61 20 |  ipsorum lingua
        70 | 43 65 6C 74  61 65 2C 20  6E 6F 73 74  72 61 20 47 | Celtae, nostra G


## Interface

    Usage: hexdump [FLAGS] [OPTIONS] ARGUMENTS

    Arguments:
      <file>     file to dump (default: stdin)

    Options:
      -l <int>   bytes per line in output (default: 16)
      -n <int>   number of bytes to read
      -o <int>   byte offset at which to begin reading

    Flags:
      --help     display this help text and exit
      --version  display version number and exit


## License

Public domain, unless indicated otherwise. The C# version includes MIT-licensed option-parsing code from the [Mono](https://github.com/mono/mono) project.
