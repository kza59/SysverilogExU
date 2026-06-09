vlib work
# UVM is really hard to run with Modelsim...
# Randomize() function doesnt even work unless I have license??? 
vlog -sv +define+UVM_NO_DPI +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm_pkg.sv
vlog -sv +define+UVM_NO_DPI +incdir+$env(UVM_HOME)/src uvmfa.sv
vlog -sv ../SourceCode/fa.sv
vsim work.fa_tb_top

run -all