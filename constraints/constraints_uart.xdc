## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

# Clock signal
set_property PACKAGE_PIN W5 [get_ports clkgen]							
	set_property IOSTANDARD LVCMOS33 [get_ports clkgen]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clkgen]
 


#Pmod Header JA
#Sch name = JA1
set_property PACKAGE_PIN J1 [get_ports {data_tx[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_tx[0]}]
#Sch name = JA2
set_property PACKAGE_PIN L2 [get_ports {data_tx[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_tx[1]}]
#Sch name = JA3
set_property PACKAGE_PIN J2 [get_ports {data_tx[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_tx[2]}]
#Sch name = JA4
set_property PACKAGE_PIN G2 [get_ports {data_tx[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_tx[3]}]
#Sch name = JA7
set_property PACKAGE_PIN H1 [get_ports {data_tx[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_tx[4]}]
#Sch name = JA8
set_property PACKAGE_PIN K2 [get_ports {data_tx[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_tx[5]}]
#Sch name = JA9
set_property PACKAGE_PIN H2 [get_ports {data_tx[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_tx[6]}]
#Sch name = JA10
set_property PACKAGE_PIN G3 [get_ports {data_tx[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_tx[7]}]



##Pmod Header JB
##Sch name = JB1
set_property PACKAGE_PIN A14 [get_ports {data_rx[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[0]}]
#Sch name = JB2
set_property PACKAGE_PIN A16 [get_ports {data_rx[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[1]}]
#Sch name = JB3
set_property PACKAGE_PIN B15 [get_ports {data_rx[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[2]}]
#Sch name = JB4
set_property PACKAGE_PIN B16 [get_ports {data_rx[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[3]}]
#Sch name = JB7
set_property PACKAGE_PIN A15 [get_ports {data_rx[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[4]}]
#Sch name = JB8
set_property PACKAGE_PIN A17 [get_ports {data_rx[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[5]}]
#Sch name = JB9
set_property PACKAGE_PIN C15 [get_ports {data_rx[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[6]}]
#Sch name = JB10 
set_property PACKAGE_PIN C16 [get_ports {data_rx[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[7]}]
 


##Pmod Header JC
##Sch name = JC1
set_property PACKAGE_PIN K17 [get_ports {rx}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {rx}]
#Sch name = JC2
set_property PACKAGE_PIN M18 [get_ports {tx}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {tx}]
#Sch name = JC3
set_property PACKAGE_PIN N17 [get_ports {reset}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {reset}]
#Sch name = JC4
set_property PACKAGE_PIN P18 [get_ports {tx_enable}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {tx_enable}]
#Sch name = JC7
set_property PACKAGE_PIN L17 [get_ports {parity_err}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {parity_err}]
#Sch name = JC8
set_property PACKAGE_PIN M19 [get_ports {error_flag}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {error_flag}]
#Sch name = JC9
set_property PACKAGE_PIN P17 [get_ports {rx_done}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {rx_done}]
