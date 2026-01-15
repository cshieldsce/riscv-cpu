# Vivado Project Creation Script for PYNQ-Z2
set project_name "riscv_cpu"
set project_dir "./vivado_project"
set part_number "xc7z020clg400-1"

# Create project
create_project $project_name $project_dir -part $part_number -force

# Add Source Files
add_files [glob ./src/*.sv]
add_files ./riscv_pkg.sv

# Add Constraints
add_files -fileset constrs_1 ./pynq_z2.xdc

# Set Top Level
set_property top pynq_z2_top [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "Project created successfully! Open $project_dir/${project_name}.xpr in Vivado GUI."
