# -----------------------------------------------------------------------
# Hexdump command line utility in x86 Linux assembly. AT&T syntax.
#
# Author: Darren Mulholland <dmulholland@outlook.ie>
# License: Public Domain
# -----------------------------------------------------------------------

# -----------------------------------------------------------------------
# Numerical Constants
# -----------------------------------------------------------------------

# Linux system call numbers.
.equ sys_exit, 1
.equ sys_read, 3
.equ sys_write, 4
.equ sys_open, 5
.equ sys_close, 6
.equ sys_lseek, 19
.equ sys_brk, 45

# Linux system call interrupt number.
.equ linux_syscall, 0x80

# Standard file descriptors.
.equ stdin, 0
.equ stdout, 1
.equ stderr, 2

# End of file indicator.
.equ eof, 0

# Stack positions.
.equ st_argc, 0
.equ st_argv, 4

.section .data

# -----------------------------------------------------------------------
# String Constants
# -----------------------------------------------------------------------

version:
    .ascii "0.1.0\0"

helptext:
    .ascii "Usage: hexdump [FLAGS] [OPTIONS] [ARGUMENTS]\n"
    .ascii "\n"
    .ascii "Arguments:\n"
    .ascii "  <file>     file to dump (default: stdin)\n"
    .ascii "\n"
    .ascii "Options:\n"
    .ascii "  -l <int>   bytes per line in output (default: 16)\n"
    .ascii "  -n <int>   number of bytes to read\n"
    .ascii "  -o <int>   byte offset at which to begin reading\n"
    .ascii "\n"
    .ascii "Flags:\n"
    .ascii "  --help     display this help text and exit\n"
    .ascii "  --version  display version number and exit"
    .ascii "\0"

option_err_msg:
    .ascii "Error: an option flag is missing a required argument.\0"

file_open_err_msg:
    .ascii "Error: cannot open file.\0"

file_seek_err_msg:
    .ascii "Error: cannot seek to the specified offset.\0"

mem_alloc_err_msg:
    .ascii "Error: out of memory.\0"

helpflag:
    .ascii "--help\0"

versionflag:
    .ascii "--version\0"

bplflag:
    .ascii "-l\0"

btrflag:
    .ascii "-n\0"

offsetflag:
    .ascii "-o\0"

argtest:
    .ascii "-l: %d\n"
    .ascii "-n: %d\n"
    .ascii "-o: %d\n"
    .ascii "fd: %d\n"
    .ascii "\0"

lineno_fmt_str:
    .ascii "%6X |\0"

hex_fmt_str:
    .ascii " %02X\0"

blank_fmt_str:
    .ascii "   \0"

chr_fmt_str:
    .ascii "%c\0"

spacer_fmt_str:
    .ascii " | \0"

nl_fmt_str:
    .ascii "\n\0"

space_fmt_str:
    .ascii " \0"

# -----------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------

offset:
    .long 0

bytes_to_read:
    .long -1

bytes_per_line:
    .long 16

input_fd:
    .long 0

heap_base:
    .long 0

# -----------------------------------------------------------------------
# Entry Point
# -----------------------------------------------------------------------

.section .text
.globl _start
_start:

    # Save the stack pointer.
    movl %esp, %ebp

    # Parse the commmand line arguments.
    # Begin by initializing a loop index.
    movl $0, %edi

begin_parse_args:

    # Increment the loop index and check if we're out of arguments.
    incl %edi
    cmp %edi, st_argc(%ebp)
    je end_parse_args

    # Is the argument at the current index the --help flag?
    pushl %edi
    pushl $helpflag
    pushl st_argv(%ebp, %edi, 4)
    call strcmp
    addl $8, %esp
    popl %edi
    cmp $0, %eax
    je exit_with_help_text

    # Is the argument at the current index the --version flag?
    pushl %edi
    pushl $versionflag
    pushl st_argv(%ebp, %edi, 4)
    call strcmp
    addl $8, %esp
    popl %edi
    cmp $0, %eax
    je exit_with_version_number

try_parse_l_option:

    # Is the argument at the current index the -l option?
    pushl %edi
    pushl $bplflag
    pushl st_argv(%ebp, %edi, 4)
    call strcmp
    addl $8, %esp
    popl %edi
    cmp $0, %eax
    jne try_parse_n_option
    incl %edi
    cmp %edi, st_argc(%ebp)
    je exit_with_option_error
    pushl %edi
    push st_argv(%ebp, %edi, 4)
    call atol
    addl $4, %esp
    popl %edi
    movl %eax, bytes_per_line
    jmp begin_parse_args

try_parse_n_option:

    # Is the argument at the current index the -n option?
    pushl %edi
    pushl $btrflag
    pushl st_argv(%ebp, %edi, 4)
    call strcmp
    addl $8, %esp
    popl %edi
    cmp $0, %eax
    jne try_parse_o_option
    incl %edi
    cmp %edi, st_argc(%ebp)
    je exit_with_option_error
    pushl %edi
    push st_argv(%ebp, %edi, 4)
    call atol
    addl $4, %esp
    popl %edi
    movl %eax, bytes_to_read
    jmp begin_parse_args

try_parse_o_option:

    # Is the argument at the current index the -o option?
    pushl %edi
    pushl $offsetflag
    pushl st_argv(%ebp, %edi, 4)
    call strcmp
    addl $8, %esp
    popl %edi
    cmp $0, %eax
    jne try_parse_filename_arg
    incl %edi
    cmp %edi, st_argc(%ebp)
    je exit_with_option_error
    pushl %edi
    push st_argv(%ebp, %edi, 4)
    call atol
    addl $4, %esp
    popl %edi
    movl %eax, offset
    jmp begin_parse_args

try_parse_filename_arg:

    # We have an argument that isn't a flag or an option,
    # so it should be the name of a file to dump.
    movl $sys_open, %eax
    movl st_argv(%ebp, %edi, 4), %ebx       # filename
    movl $0, %ecx                           # readonly flag
    movl $0666, %edx                        # mode - not relevant here
    int $linux_syscall
    movl %eax, input_fd                     # save the file descriptor
    cmp $0, %eax                            # check for an error code
    jl exit_with_file_open_error            # negative eax means error

    # Continue looping until we run out of arguments.
    jmp begin_parse_args

end_parse_args:

begin_seek_to_offset:

    # If an offset has been specified, attempt to seek into the file.
    cmp $0, offset
    je end_seek_to_offset
    movl $sys_lseek, %eax
    movl input_fd, %ebx
    movl offset, %ecx
    movl $0, %edx                           # absolute positioning
    int $linux_syscall
    cmp $0, %eax
    jl exit_with_file_seek_error

end_seek_to_offset:

begin_allocate_buffer:

    # We need to allocate a buffer on the heap to hold data from
    # the input file. First we determine the base address of the heap by
    # passing 0 to brk. This returns the last valid memory address;
    # adding 1 gives us the beginning of the heap.
    movl $sys_brk, %eax
    movl $0, %ebx
    int $linux_syscall
    incl %eax
    movl %eax, heap_base

    # Move the system break to allocate memory.
    movl $sys_brk, %eax
    movl heap_base, %ebx
    addl bytes_per_line, %ebx
    int $linux_syscall
    cmp $0, %eax
    je exit_with_mem_alloc_error

end_allocate_buffer:

begin_read_file:

    # File reading loop. We read one line of input per pass.
    movl $sys_read, %eax
    movl input_fd, %ebx
    movl heap_base, %ecx

    # If bytes_to_read < 0 (read all), try to read one full line.
    cmp $0, bytes_to_read
    jl try_read_bpl

    # If line length < bytes_to_read, try to read one full line.
    movl bytes_per_line, %edi
    cmp bytes_to_read, %edi
    jl try_read_bpl

try_read_btr:

    # Try to read less than a full line of bytes.
    movl bytes_to_read, %edx
    jmp read_file

try_read_bpl:

    # Try to read one full line of bytes.
    movl bytes_per_line, %edx

read_file:

    # The read syscall returns the number of bytes read.
    int $linux_syscall

    # 0 bytes read means we're done.
    cmp $0, %eax
    je end_read_file

    # Print a line of output.
    pushl %eax
    call writeln
    popl %eax

    # Update our offset and bytes_to_read variables to account for
    # the number of bytes read.
    addl %eax, offset
    subl %eax, bytes_to_read

    # Loop until we reach our target byte count or the end of the file.
    jmp begin_read_file

end_read_file:

exit_normally:

    pushl $0
    jmp exit_app

exit_with_help_text:

    pushl $helptext
    call puts
    pushl $0
    jmp exit_app

exit_with_version_number:

    pushl $version
    call puts
    pushl $0
    jmp exit_app

exit_with_option_error:

    pushl $option_err_msg
    call puts
    pushl $1
    jmp exit_app

exit_with_file_open_error:

    pushl $file_open_err_msg
    call puts
    pushl $1
    jmp exit_app

exit_with_file_seek_error:

    pushl $file_seek_err_msg
    call puts
    pushl $1
    jmp exit_app

exit_with_mem_alloc_error:

    pushl $mem_alloc_err_msg
    call puts
    pushl $1
    jmp exit_app

exit_app:

    # If we have an open file, close it.
    cmp $0, input_fd
    jle exit_now
    movl $sys_close, %eax
    movl input_fd, %ebx
    int $linux_syscall

exit_now:

    # We should have pushed a status code on the stack by now.
    call exit

# -----------------------------------------------------------------------
# Function: dump variables
#
# Prints out the program's variables as a debugging aid.
# No arguments, no return value.
# -----------------------------------------------------------------------

dump_vars:

    pushl %ebp
    movl %esp, %ebp

    pushl input_fd
    pushl offset
    pushl bytes_to_read
    pushl bytes_per_line
    pushl $argtest
    call printf
    addl $20, %esp

    movl %ebp, %esp
    popl %ebp
    ret

# -----------------------------------------------------------------------
# Function: write a single line of output.
#
# This function takes a single argument: an integer specifying the
# number of bytes in the buffer to print. It has no return value.
# -----------------------------------------------------------------------

# Offset of the num_bytes parameter on the function stack.
.equ st_num_bytes, 8

writeln:

    pushl %ebp
    movl %esp, %ebp

    # Print the line number.
    pushl offset
    pushl $lineno_fmt_str
    call printf
    addl $8, %esp

    # Initialize a loop counter.
    movl $0, %edi

begin_print_hex_loop:

    # First, check if we need to print an extra space.
    # We print one extra space before every fourth byte.
    # We don't print the space before the first byte.
    cmp $0, %edi
    je print_blank_or_hex

    # If the index is a multiple of 4, print the space.
    movl $0, %edx
    movl %edi, %eax
    movl $4, %esi
    divl %esi
    cmp $0, %edx
    jne print_blank_or_hex
    pushl $space_fmt_str
    call printf
    addl $4, %esp

print_blank_or_hex:

    # Print the byte at the current index in hex form,
    # or a blank spacer if we've run out of bytes.
    cmp st_num_bytes(%ebp), %edi
    jl print_byte_as_hex

print_blank:

    # Print a "   " spacer.
    pushl $blank_fmt_str
    call printf
    addl $4, %esp
    jmp inc_hex_loop_counter

print_byte_as_hex:

    # Print a byte in hex form.
    movl heap_base, %esi
    movb (%esi, %edi, 1), %al
    pushl %eax
    pushl $hex_fmt_str
    call printf
    addl $8, %esp

inc_hex_loop_counter:

    # Increment and test the loop counter.
    incl %edi
    cmp bytes_per_line, %edi
    jl begin_print_hex_loop

end_print_hex_loop:

    # Print the " | " spacer.
    pushl $spacer_fmt_str
    call printf
    addl $4, %esp

    # Initialize a loop counter.
    movl $0, %edi

begin_print_char_loop:

    # Loop over the buffer and print a character for each byte
    # in the printable ascii range. Print a dot for each byte
    # outside that range.
    movl heap_base, %esi
    movb (%esi, %edi, 1), %al

    cmp $' ', %eax
    jl print_dot

    cmp $'~', %eax
    jg print_dot

print_ascii_char:

    pushl %eax
    jmp print_char_or_dot

print_dot:

    pushl $'.'

print_char_or_dot:

    pushl $chr_fmt_str
    call printf
    addl $8, %esp

    # Increment the loop counter and check if we're done.
    incl %edi
    cmp st_num_bytes(%ebp), %edi
    jl begin_print_char_loop

end_print_char_loop:

    # Print a newline.
    pushl $nl_fmt_str
    call printf
    addl $4, %esp

    movl %ebp, %esp
    popl %ebp
    ret
