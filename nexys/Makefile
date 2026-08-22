# Configuration variables
TOP_MODULE  ?= top_12mhz
PART_NUMBER ?= xc7a100ticsg324-1L
BUILD_DIR   ?= build
PORT = /dev/ttyUSB1

# Executable definitions
VIVADO      := vivado -mode batch -journal $(BUILD_DIR)/vivado.jou -log $(BUILD_DIR)/vivado.log

# Find all source files to trace dependencies
SRCS        := $(wildcard src/*.v) $(wildcard src/*.sv)
CONSTRAINTS := src/nexys.xdc

.PHONY: all bitstream clean

# Default target
all: bitstream

# Rule to generate the final bitstream
bitstream: $(BUILD_DIR)/$(TOP_MODULE).bit

$(BUILD_DIR)/$(TOP_MODULE).bit: ../run.tcl $(SRCS) $(CONSTRAINTS)
	@mkdir -p $(BUILD_DIR)
	$(VIVADO) -source ../run.tcl -tclargs "$(TOP_MODULE)" "$(PART_NUMBER)" "$(BUILD_DIR)"

program: build/$(TOP_MODULE).bit
	$(VIVADO) -source ../program.tcl -tclargs $(TOP_MODULE)

test: build/$(TOP_MODULE).bit
	miniterm.py $(PORT) 115200 --exit-char 3 # exit on CTRL-C

# Clean up build artifacts
clean:
	rm -rf $(BUILD_DIR) clockInfo.txt
