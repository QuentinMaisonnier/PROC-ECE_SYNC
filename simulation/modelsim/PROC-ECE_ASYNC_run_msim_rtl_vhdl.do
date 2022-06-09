transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/quent/Desktop/RSICV\ code/VHDL/PROC-ECE_SYNC\ GALOPE\ V3/db {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/db/clock1m_altpll.v}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/custom_lib/simul_var_pkg.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/ProgramCounter.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/Processor.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/InstructionDecoder.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/Displays.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/Counter.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/Alu.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/RAM_2PORT.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/clock1M.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/Top.vhd}
vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/RegisterFile.vhd}

vcom -93 -work work {C:/Users/quent/Desktop/RSICV code/VHDL/PROC-ECE_SYNC GALOPE V3/vhdl_files/TestBench.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  TestBenchTop

add wave *
view structure
view signals
run -all
