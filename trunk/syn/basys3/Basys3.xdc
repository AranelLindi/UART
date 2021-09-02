## Constraints for Hardware Implementation on Digilent Basys 3 FPGA

## Clock signal (10 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 100.00 -waveform {0 50} [get_ports clk]

## LEDs
#set_property PACKAGE_PIN U16 [get_ports {led[0]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
#set_property PACKAGE_PIN E19 [get_ports {led[1]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
#set_property PACKAGE_PIN U19 [get_ports {led[2]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
#set_property PACKAGE_PIN V19 [get_ports {led[3]}]					
	#set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
	
##Buttons
#set_property PACKAGE_PIN U18 [get_ports btnC]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnC]
#set_property PACKAGE_PIN T18 [get_ports btnU]						
	#set_property IOSTANDARD LVCMOS33 [get_ports btnU]

##USB-RS232 Interface
set_property PACKAGE_PIN B18 [get_ports rxstream]						
	set_property IOSTANDARD LVCMOS33 [get_ports rxstream]
set_property PACKAGE_PIN A18 [get_ports txstream]						
	set_property IOSTANDARD LVCMOS33 [get_ports txstream]
