# riscof_riscv_cpu.py

import os
import re
import shutil
import subprocess
import shlex
import logging

from riscof.pluginTemplate import pluginTemplate

logger = logging.getLogger()

class riscv_cpu(pluginTemplate):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        config = kwargs.get('config')
        self.dut_exe = 'sim.out'
        if config:
            self.pluginpath = os.path.abspath(config['pluginpath'])
            self.isa_spec = os.path.abspath(config['ispec'])
            self.platform_spec = os.path.abspath(config['pspec'])

    def initialise(self, suite, work_dir, arch_test_dir):
        logger.info("Initialise DUT Plugin")
        self.work_dir = work_dir
        self.suite_dir = suite
        
        # Determine the root of the project to locate src/ and test/
        plugin_path = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.abspath(os.path.join(plugin_path, '..'))
        
        self.src_dir = os.path.join(project_root, 'src')
        self.test_dir = os.path.join(project_root, 'test')
        self.linker_script = os.path.join(plugin_path, 'link.ld')
        self.elf2hex_script = os.path.join(plugin_path, 'elf2hex.py')
        
        # Include path for the test suite macros
        self.iverilog_include_path = os.path.abspath(os.path.join(self.suite_dir, 'env'))
        
        # Compiler command (GCC) to build the test ELF
        # We need to use the linker script to ensure code is at 0x0 and data at 0x800
        # Added -I{3} for pluginpath (model_test.h)
        self.compile_cmd = 'riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -T {0} {1} -I{2} -I{3}'

    def build(self, isa_yaml, platform_yaml):
        logger.info("Building DUT")
        # Compile the Verilog simulator once if possible, or per test if arguments change.
        # Since the TB takes +TEST arg, we can compile once.
        
        # Get all SV files in src/
        src_files = [os.path.join(self.src_dir, f) for f in os.listdir(self.src_dir) if f.endswith('.sv')]
        tb_file = os.path.join(self.test_dir, 'pipelined_cpu_tb.sv')
        pkg_file = os.path.join(os.path.dirname(self.src_dir), 'riscv_pkg.sv')
        
        self.sim_compile_cmd = ['iverilog', '-g2012', '-o', self.dut_exe] + [pkg_file] + src_files + [tb_file]
        
        logger.debug("Compiling simulator: " + " ".join(self.sim_compile_cmd))
        subprocess.run(self.sim_compile_cmd, check=True, cwd=self.work_dir)

    def runTests(self, testList):
        logger.info("Running Tests")
        for test_name in testList:
            test = testList[test_name]
            test_dir = test['work_dir']
            test_src = test['test_path']
            test_macros = test['macros'] # List of macros
            test_elf = os.path.join(test_dir, test_name + ".elf")
            macro_args = ' -D' + ' -D'.join(test_macros)
            
            cmd_compile = self.compile_cmd.format(
                self.linker_script,
                test_src,
                self.iverilog_include_path,
                self.pluginpath
            ) + macro_args + ' -o ' + test_elf
            
            # Add macros if needed (usually handled by the include file in the suite)
            # But we might need -D flags if the suite expects them.
            # For now, let's assume the include path is enough.
            
            logger.debug("Compiling Test: " + cmd_compile)
            subprocess.run(shlex.split(cmd_compile), check=True, cwd=test_dir)
            
            # 2. Convert ELF to Hex
            hex_file = os.path.abspath(os.path.join(test_dir, os.path.basename(test_name) + ".hex"))
            cmd_elf2hex = 'python3 {0} {1} {2}'.format(self.elf2hex_script, test_elf, hex_file)
            subprocess.run(shlex.split(cmd_elf2hex), check=True, cwd=test_dir)
            
            # 3. Run the Simulation
            # Copy the simulator to the test dir or run from work_dir
            sim_path = os.path.join(self.work_dir, self.dut_exe)
            
            run_cmd = 'vvp {0} +TEST={1}'.format(sim_path, hex_file)
            logger.debug("Running Simulation: " + run_cmd)
            
            # We expect the simulation to produce 'signature.txt' in the CWD (test_dir)
            try:
                subprocess.run(shlex.split(run_cmd), check=True, cwd=test_dir, timeout=60)
            except subprocess.TimeoutExpired:
                logger.error(f"Test {test_name} timed out")
            
            # 4. Copy Signature and Extract relevant part
            signature_file = os.path.join(test_dir, 'signature.txt')
            # define dut_sig_file for fallback (using clean name)
            clean_name = self.name.replace(":", "")
            dut_sig_file = os.path.join(test_dir, clean_name + ".signature")

            if os.path.exists(signature_file):
                # 4.1 Get symbols from ELF
                cmd_nm = 'nm -n ' + test_elf
                output = subprocess.check_output(shlex.split(cmd_nm)).decode('utf-8')
                
                begin_sig = 0
                end_sig = 0
                
                for line in output.splitlines():
                    if 'begin_signature' in line:
                        begin_sig = int(line.split()[0], 16)
                    if 'end_signature' in line:
                        end_sig = int(line.split()[0], 16)
                
                # 4.2 Calculate indices relative to dump base (0x200000)
                # Word size is 4 bytes
                dump_base = 0x200000
                start_index = (begin_sig - dump_base) // 4
                end_index = (end_sig - dump_base) // 4
                
                # 4.3 Read full dump
                with open(signature_file, 'r') as f:
                    lines = f.readlines()
                
                # 4.4 Extract slice
                # Ensure indices are within bounds
                if start_index >= 0 and end_index <= len(lines):
                    sig_lines = lines[start_index:end_index]
                else:
                    logger.error(f"Signature indices out of bounds: {start_index} to {end_index}, total lines: {len(lines)}")
                    sig_lines = []

                # 4.5 Write processed signature
                with open(dut_sig_file, 'w') as f:
                    f.writelines(sig_lines)
                
                # Copy to expected names for RISCOF
                # We create multiple variants to be absolutely sure RISCOF finds it
                for name_variant in ["DUT-Template.signature", "DUT-riscv_cpu.signature", "riscv_cpu.signature", "Template.signature"]:
                    dst = os.path.join(test_dir, name_variant)
                    if os.path.abspath(dut_sig_file) != os.path.abspath(dst):
                        shutil.copy(dut_sig_file, dst)
            else:
                logger.error(f"Signature file not generated for {test_name}")
                # Create empty signature to avoid crash, or fail?
                # Better to fail or let riscof report mismatch
                with open(dut_sig_file, 'w') as f:
                    f.write("")

        pass
