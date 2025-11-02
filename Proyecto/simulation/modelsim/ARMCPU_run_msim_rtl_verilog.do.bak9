transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/arm.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/controller.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/decoder.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/condlogic.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/datapath.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/regfile.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/adder.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/extend.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/flopr.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/flopenr.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/mux2.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/top.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/dmem.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/alu.sv}
vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/imem.sv}

vlog -sv -work work +incdir+D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto {D:/ARMCPU_Dig_Design/FGonzalez_JZheng_JDiaz_JRodriguez_digital_design_lab_2025/Proyecto/testbench.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  testbench

add wave *
view structure
view signals
run -all
