# Configuration variables
TOP_MODULE  ?= top
PART_NUMBER ?= xc7a100ticsg324-1L
BUILD_DIR   ?= build

# Executable definitions
VIVADO      := vivado -mode batch -journal $(BUILD_DIR)/vivado.jou -log $(BUILD_DIR)/vivado.log

# Find all source files to trace dependencies
SRCS        := $(wildcard src/*.v) $(wildcard src/*.sv)
CONSTRAINTS := $(wildcard src/*.xdc)

.PHONY: all bitstream clean

# Default target
all: bitstream

# Rule to generate the final bitstream
bitstream: $(BUILD_DIR)/$(TOP_MODULE).bit

$(BUILD_DIR)/$(TOP_MODULE).bit: run.tcl $(SRCS) $(CONSTRAINTS)
	@mkdir -p $(BUILD_DIR)
	$(VIVADO) -source run.tcl -tclargs "$(TOP_MODULE)" "$(PART_NUMBER)" "$(BUILD_DIR)"

program: build/$(TOP_MODULE).bit
	$(VIVADO) -source program.tcl -tclargs $(TOP_MODULE)

# Clean up build artifacts
clean:
	rm -rf $(BUILD_DIR)
