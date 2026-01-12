#!/bin/bash
# Script to run RIS-V Compliance Tests using RISCOF

# Ensure we are in the project root
cd "$(dirname "$0")"

# Ensure riscof_work is clean to force regeneration
rm -rf riscof_work

# Set PYTHONPATH to include the compliance folder so RISCOF can find the plugins
export PYTHONPATH=$PYTHONPATH:$(pwd)/compliance:$(pwd)/compliance/spike_sim

# Run RISCOF using relative paths from the root
riscof run --config compliance/config.ini \
           --suite riscv-arch-test/riscv-test-suite/ \
           --env riscv-arch-test/riscv-test-suite/env

# Check for success in logs
if [ -f riscof_work/rv32i_m/I/src/add-01.S/dut/signature.txt ]; then
    echo "---------------------------------------------------"
    echo "SUCCESS: Compliance tests executed."
    echo "---------------------------------------------------"
else
    echo "---------------------------------------------------"
    echo "WARNING: Check logs. Signature files not found."
    echo "---------------------------------------------------"
fi