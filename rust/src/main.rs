extern crate getopts;

use std::io;
use std::io::Seek;
use std::fs::File;


fn version() {
    println!("0.1.0");
}


fn help() {
    println!("\
Usage: hexdump [FLAGS] [OPTIONS] ARGUMENTS

Arguments:
  <file>     file to dump (default: stdin)

Options:
  -l <int>   bytes per line in output (default: 16)
  -n <int>   number of bytes to read
  -o <int>   byte offset at which to begin reading

Flags:
  --help     display this help text and exit
  --version  display version number and exit");
}


fn main() {
    let mut offset: i64 = 0;
    let mut bytes_per_line: i64 = 16;
    let mut bytes_to_read: i64 = -1;

    let mut parser = getopts::Options::new();
    parser.optflag("", "help", "print this help text and exit");
    parser.optflag("", "version", "print version number and exit");
    parser.optopt("l", "", "bytes per line (default: 16)", "<int>");
    parser.optopt("n", "", "number of bytes to read", "<int>");
    parser.optopt("o", "", "byte offset at which to begin reading", "<int>");

    let args: Vec<String> = std::env::args().collect();
    let matches = match parser.parse(&args[1..]) {
        Ok(matches) => matches,
        Err(fail) => {
            println!("Error: {:?}", fail);
            std::process::exit(1);
        }
    };

    if matches.opt_present("help") {
        help();
        std::process::exit(0);
    }

    if matches.opt_present("version") {
        version();
        std::process::exit(0);
    }

    match matches.opt_str("l") {
        Some(argstr) => {
            match argstr.parse::<i64>() {
                Ok(argint) => {
                    bytes_per_line = argint;
                },
                Err(_) => {
                    println!("Error: invalid argument to -l option.");
                    std::process::exit(1);
                }
            }
        },
        None => ()
    };

    match matches.opt_str("n") {
        Some(argstr) => {
            match argstr.parse::<i64>() {
                Ok(argint) => {
                    bytes_to_read = argint;
                },
                Err(_) => {
                    println!("Error: invalid argument to -n option.");
                    std::process::exit(1);
                }
            }
        },
        None => ()
    }

    match matches.opt_str("o") {
        Some(argstr) => {
            match argstr.parse::<i64>() {
                Ok(argint) => {
                    offset = argint;
                },
                Err(_) => {
                    println!("Error: invalid argument to -o option.");
                    std::process::exit(1);
                }
            }
        },
        None => ()
    }

    if matches.free.is_empty() {
        if offset > 0 {
            println!("Error: cannot seek into stdin.");
            std::process::exit(1);
        }
        let mut file = io::stdin();
        dump(file, offset, bytes_to_read, bytes_per_line);
    } else {
        let filename = matches.free[0].clone();
        let filepath = std::path::Path::new(&filename);

        let mut file = match File::open(&filepath) {
            Ok(file) => file,
            Err(_) => {
                println!("Error: cannot open the specified file.");
                std::process::exit(1);
            }
        };

        if offset > 0 {
            match file.seek(io::SeekFrom::Start(offset as u64)) {
                Ok(_) => (),
                Err(_) => {
                    println!("Error: cannot seek the specified offset.");
                    std::process::exit(1);
                }
            }
        }
        dump(file, offset, bytes_to_read, bytes_per_line);
    }
}


fn dump<T>(mut file: T,
           mut offset: i64,
           mut bytes_to_read:
           i64, bytes_per_line: i64) where T: io::Read {

    let mut max_bytes;
    let mut buffer: Vec<u8> = vec![0; bytes_per_line as usize];

    // Read and dump one line per iteration.
    loop {

        // If bytes_to_read < 0 (read all), try to read one full line.
        // If line length < bytes_to_read, try to read one full line.
        // Otherwise, try to read all the remaining bytes in one go.
        if bytes_to_read < 0 {
            max_bytes = bytes_per_line;
        } else if bytes_per_line < bytes_to_read {
            max_bytes = bytes_per_line;
        } else {
            max_bytes = bytes_to_read;
        }

        let bytes = &mut buffer[0..max_bytes as usize];

        match file.read(bytes) {
            Ok(num_bytes) => {
                if num_bytes > 0 {
                    writeln(bytes, num_bytes, offset, bytes_per_line);
                    offset += num_bytes as i64;
                    bytes_to_read -= num_bytes as i64;
                } else {
                    break;
                }
            },
            Err(e) => {
                print!("Error: {:?}", e);
                std::process::exit(1);
            }
        }
    }
}

fn writeln(bytes: &[u8], num_bytes: usize, offset: i64, bytes_per_line: i64) {

    // Write the line number.
    print!(" {:6X} |", offset);

    for i in 0..bytes_per_line {

        // Write an extra space in front of every fourth byte except the first.
        if i > 0 && i % 4 == 0 {
            print!(" ");
        }

        // Write the byte in hex form, or a spacer if we're out of bytes.
        if i < num_bytes as i64 {
            print!(" {:02X}", bytes[i as usize]);
        } else {
            print!("   ");
        }
    }

    print!(" | ");

    // Write a character for each byte in the printable ascii range.
    for i in 0..num_bytes {
        if bytes[i as usize] > 31 && bytes[i as usize] < 127 {
            print!("{}", bytes[i as usize] as char);
        } else {
            print!(".");
        }
    }

    println!("");
}
