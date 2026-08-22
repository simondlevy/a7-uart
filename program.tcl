# Catch the Top Module name passed from the Makefile
if { $argc != 1 } {
    puts "Error: Expected 1 argument (Top Module). Got $argc."
    exit 1
}

set TOP_MODULE [lindex $argv 0]
set BITSTREAM  "./build/${TOP_MODULE}.bit"

# Open the Vivado Hardware Manager
open_hw_manager

# Connect to the local hardware server (hw_server must be running, or Vivado will launch it)
connect_hw_server -url localhost:3121
refresh_hw_server

# Find and open the target programming cable/target board
if { [get_hw_targets] == "" } {
    puts "Error: No hardware targets found. Check your JTAG cable connections and power."
    exit 1
}

open_hw_target

# Grab the first available FPGA device on the JTAG chain
set DEVICE [lindex [get_hw_devices] 0]
current_hw_device $DEVICE
refresh_hw_device -update_hw_probes false $DEVICE

# Associate the compiled bitstream with the physical device
set_property PROGRAM.FILE $BITSTREAM $DEVICE

# Optional: Add debug probes file if you are using an ILA (Integrated Logic Analyzer)
# set PROBES "./build/${TOP_MODULE}.ltx"
# if { [file exists $PROBES] } { set_property PROGRAM.PROBES.FILE $PROBES $DEVICE }

# Program the FPGA
puts "Programming device $DEVICE with $BITSTREAM..."
program_hw_devices $DEVICE
refresh_hw_device $DEVICE

# Clean up connections
close_hw_target
disconnect_hw_server
close_hw_manager

puts "Device programmed successfully!"
exit 0
