import os
import subprocess
import sys
import glob

# Configuration
OUTPUT_FILE = "sim.out"
MEM_DIR = "mem"

def compile_cpu():
    print("🔧 Compiling CPU...")
    
    # 1. Manually find all .sv files in src/
    src_files = glob.glob("src/*.sv")
    
    # 2. Construct the file list explicitly
    # Order matters: Package first!
    source_files = ["riscv_pkg.sv"] + src_files + ["test/pipelined_cpu_tb.sv"]
    
    # 3. Join them into the command string
    cmd_str = f"iverilog -g2012 -o {OUTPUT_FILE} " + " ".join(source_files)
    
    print(f"Executing: {cmd_str}") # Debug print
    
    result = subprocess.run(cmd_str, shell=True, capture_output=True, text=True)
    
    if result.returncode != 0:
        print("❌ Compilation Failed!")
        print(result.stderr)
        sys.exit(1)
    print("✅ Compilation Successful.\n")

def run_test(mem_file):
    print(f"▶️  Running test: {mem_file}")
    
    # We need to tell the testbench WHICH mem file to load.
    # Since your TB uses $readmemh, we can pass a definition flag to iverilog 
    # OR (easier for now) rely on your TB looking for a specific file, 
    # but ideally, we modify the TB to accept a parameter.
    #
    # FOR NOW: We will assume the TB loads 'mem/pipeline_test.mem' or similar.
    # To make this dynamic, we need to modify the TB to use a parameter!
    # Let's Skip dynamic loading for a second and just run the sim.
    
    result = subprocess.run(["vvp", OUTPUT_FILE], capture_output=True, text=True)
    
    output = result.stdout
    if "[FAIL]" in output:
        print(f"❌ Test Failed: {mem_file}")
        print(output)
        return False
    elif "[PASS]" in output:
        print(f"✅ Test Passed: {mem_file}")
        return True
    else:
        print(f"⚠️  No Pass/Fail detected for {mem_file}")
        print(output)
        return False

# --- CRITICAL UPDATE NEEDED FOR YOUR TESTBENCH ---
# You need to modify test/pipelined_cpu_tb.sv to accept a filename via CLI 
# or we just run the current hardcoded one. 
# For this script to be useful, it implies we fixed the TB.

if __name__ == "__main__":
    compile_cpu()
    # Currently just runs the compiled sim (whatever is hardcoded in TB)
    if run_test("Current Config"):
        sys.exit(0)
    else:
        sys.exit(1)