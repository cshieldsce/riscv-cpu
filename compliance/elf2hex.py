#!/usr/bin/env python3
import argparse
import os
import subprocess

def elf_to_hex(elf_file, hex_file):
    """
    Converts an ELF file to a hex file compatible with Verilog's $readmemh.
    Uses riscv-gnu-toolchain's objcopy.
    """
    # Use objcopy to convert ELF to binary
    bin_file = hex_file + ".bin"
    objcopy_cmd = [
        "riscv64-unknown-elf-objcopy",
        "-O", "binary",
        elf_file,
        bin_file
    ]
    subprocess.run(objcopy_cmd, check=True)

    # Convert binary to hex
    with open(bin_file, "rb") as f_bin, open(hex_file, "w") as f_hex:
        while True:
            word = f_bin.read(4)
            if not word:
                break
            # Ensure word is 4 bytes, pad if necessary
            word = word.ljust(4, b'\x00')
            # Write as 32-bit hex value in big-endian format
            f_hex.write(f"{int.from_bytes(word, 'little'):08x}\n")

    os.remove(bin_file)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert ELF to Verilog hex format")
    parser.add_argument("elf_file", help="Input ELF file")
    parser.add_argument("hex_file", help="Output hex file")
    args = parser.parse_args()

    elf_to_hex(args.elf_file, args.hex_file)
