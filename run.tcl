# ---------------------------------------------------------------------
# run.tcl - Vivado Non-Project Mode Execution Script
# ---------------------------------------------------------------------

# 1. Parse arguments passed from the Makefile
if { $argc != 3 } {
    puts "Error: Invalid number of arguments."
    puts "Usage: vivado -mode batch -source run.tcl -tclargs <top_module> <part_number> <build_dir>"
    exit 1
}

set TOP_MODULE  [lindex $argv 0]
set PART_NUMBER [lindex $argv 1]
set BUILD_DIR   [lindex $argv 2]

puts "Starting build for Top: $TOP_MODULE, Part: $PART_NUMBER"

# 2. Read design source assets
# Add -sv flag for SystemVerilog files if necessary
foreach file [glob -nocomplain src/*.v]  { read_verilog $file }
foreach file [glob -nocomplain src/*.sv] { read_verilog -sv $file }
foreach file [glob -nocomplain *.xdc] { read_xdc $file }

# 3. Synthesis
synth_design -top $TOP_MODULE -part $PART_NUMBER
write_checkpoint -force $BUILD_DIR/post_synth.dcp

# 4. Optimizaton & Implementation
opt_design
place_design
write_checkpoint -force $BUILD_DIR/post_place.dcp

route_design
write_checkpoint -force $BUILD_DIR/post_route.dcp

# 5. Generate Reports
report_timing_summary -file $BUILD_DIR/timing_summary.rpt
report_utilization    -file $BUILD_DIR/utilization.rpt

# 6. Generate Bitstream
write_bitstream -force $BUILD_DIR/$TOP_MODULE.bit

puts "Build successfully completed! Bitstream located at: $BUILD_DIR/$TOP_MODULE.bit"
exit 0
