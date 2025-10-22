module	alu
	#(parameter	BusWidth	= 32)
	(input logic[(BusWidth - 1):0]	i_ALU_Src1, i_ALU_Src2,
	input logic[1:0]				i_ALU_Control,
	output logic[(BusWidth - 1):0]	o_ALU_Result,
	output logic[3:0]				o_ALU_Flags);

	logic[(BusWidth - 1):0]			s_ALU_Result;
	logic							s_Flag_Negative, s_Flag_Zero;
	logic							s_Flag_Carry, s_Flag_Overflow;

	typedef enum logic[1:0] {ADD, SUB, AND, ORR}	ALU_Operation;


	//	Result logic
	always_comb
	begin
		case (i_ALU_Control[1:0])
			ADD:	s_ALU_Result <= i_ALU_Src1 + i_ALU_Src2;
			SUB:	s_ALU_Result <= i_ALU_Src1 - i_ALU_Src2;
			AND:	s_ALU_Result <= i_ALU_Src1 & i_ALU_Src2;
			ORR:	s_ALU_Result <= i_ALU_Src1 | i_ALU_Src2;
			
			default:	s_ALU_Result = 32'b0;
		endcase
	end

	//	Flags logic
	always_comb
	begin
		s_Flag_Negative = (s_ALU_Result[BusWidth - 1] == 1'b1) ?	1'b1 : 1'b0;
		s_Flag_Zero = (s_ALU_Result == 0) ?							1'b1 : 1'b0;
		case (i_ALU_Control[1:0])
			ADD:
			begin
				s_Flag_Carry = (i_ALU_Src1 >= i_ALU_Src2) ?					1'b1 : 1'b0;
				s_Flag_Overflow =	((~i_ALU_Src1[BusWidth - 1] & ~i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]) |
									(i_ALU_Src1[BusWidth - 1] & i_ALU_Src2[BusWidth - 1] & ~s_ALU_Result[BusWidth - 1]));
			end
			SUB:
			begin
				s_Flag_Carry = (i_ALU_Src1 < i_ALU_Src2) ?					1'b1 : 1'b0;
				s_Flag_Overflow =	((i_ALU_Src1[BusWidth - 1] & ~i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]) |
									(~i_ALU_Src1[BusWidth - 1] & i_ALU_Src2[BusWidth - 1] & s_ALU_Result[BusWidth - 1]));
			end
			
			default:
			begin
				s_Flag_Carry = 1'bx;
				s_Flag_Overflow = 1'bx;
			end
		endcase
	end

	assign o_ALU_Result =	s_ALU_Result;
	assign o_ALU_Flags =	{s_Flag_Negative, s_Flag_Zero,
							s_Flag_Carry, s_Flag_Overflow};

endmodule