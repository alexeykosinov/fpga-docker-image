puts "Compile sim libs"
compile_simlib -simulator questa -simulator_exec_path {/opt/questasim/bin} -family zynquplus -language all -library all -dir {/opt/questasim/xilinx} -force -quiet
