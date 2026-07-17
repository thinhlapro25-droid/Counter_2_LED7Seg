//Frequency input clock = 27MHz 
module chia_tan_2kenh(
    input i_clk,
    input i_rst_n, 
    output reg en_1hz,
    output reg en_1khz
);
    reg [24:0] cnt_1hz;
    reg [14:0] cnt_1khz;

    // Frequency divide 1Khz
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            cnt_1khz <= 15'd0;
            en_1khz  <= 1'b0;
        end else if (cnt_1khz == 15'd5) begin //In this code and testbench, i wanna show you objective view, so we set cnt_1khz == 15'd5
            cnt_1khz <= 15'd0;		// But when you embed the code onto an FPGA, you need set cnt_1khz == 15'26_999. That is (27M - 1)/1000.
            en_1khz  <= 1'b1;
        end else begin
            cnt_1khz <= cnt_1khz + 1'b1;
            en_1khz  <= 1'b0;
        end
    end

    // Freeqency divide 1Hz
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            cnt_1hz <= 25'd0;
            en_1hz  <= 1'b0;
        end else if (cnt_1hz == 25'd50) begin // This one is the same. When you embed the code onto an FPGA, you need set cnt_1hz == 25'd26_999_999
            cnt_1hz <= 25'd0;
            en_1hz  <= 1'b1;
        end else begin
            cnt_1hz <= cnt_1hz + 1'b1;
            en_1hz  <= 1'b0;
        end
    end
endmodule

module Dem_2so(		//Module counter 00-99
    input i_clk,
    input en_1hz,
    input i_rst_n,
    output reg [3:0] donvi,
    output reg [3:0] chuc
);
	always @(posedge i_clk or negedge i_rst_n)begin
		if(!i_rst_n)begin
			chuc <= 4'b0;
			donvi <= 4'b0;
		end
		else if(en_1hz)begin	//This module will use the en_1hz, that mean 1s this module will count once
			if(donvi == 4'd9)begin
				donvi <= 4'd0;
					if(chuc == 4'd9)begin
						chuc <= 4'd0;
					end 
					else begin
						chuc <= chuc + 1'b1;
					end
			end 
			else begin
				donvi <= donvi + 1'b1;			
			end
		end
	end
endmodule

module Dem_1bit(	//This module will scan your LED 7 seg with 1KHz, so it will trick your eyes
    input i_clk,	//That mean Led 1 ON Led 2 OFF, LED 1 OFF LED 2 ON with 1 KHz, Ur eyes can't perceive them constantly switching on and off.
    input i_rst_n,
    input en_1khz,
    output reg q
);
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            q <= 1'b0;
        end else if (en_1khz) begin
            q <= ~q;
        end
    end
endmodule

module mux_21(	//Module Mux will choose the output
    input [3:0] I0,
    input [3:0] I1,
    input sel,
    output [3:0] BCD_out
);
    assign BCD_out = (sel == 1'b0) ? I0 : I1;
endmodule

module giaima_12h(	//01 for LED 1 and 10 for LED 2
    input i,
    output [1:0] o_12h
);
    assign o_12h = (i == 1'b0) ? 2'b01 :  2'b10;
endmodule

module led_7seg(	//Module LED 7 Seg
    input [3:0] BCD_in,
    output reg [6:0] LED
);
    always @(*)begin
		case(BCD_in)
			4'd0: LED = 7'b0111111;
			4'd1: LED = 7'b0000110;
			4'd2: LED = 7'b1011011;
			4'd3: LED = 7'b1001111;
			4'd4: LED = 7'b1100110;
			4'd5: LED = 7'b1101101;
			4'd6: LED = 7'b1111101;
			4'd7: LED = 7'b0000111;
			4'd8: LED = 7'b1111111;
			4'd9: LED = 7'b1101111;
			default: LED = 7'b0000000;
		endcase
	end
endmodule

module Top(	//Module Top
    input i_clk,
    input i_rst_n,
    output [6:0] LED,
    output [1:0] cathode
);
    wire [3:0] donvi;
    wire [3:0] chuc;
    wire [3:0] BCD_in;
    wire en_1khz;
    wire en_1hz;
    wire s1b;
chia_tan_2kenh ic1(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .en_1hz(en_1hz),
    .en_1khz(en_1khz)
);
Dem_2so ic2(
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .en_1hz(en_1hz),
    .chuc(chuc),
    .donvi(donvi)
);
Dem_1bit ic3(
    .en_1khz(en_1khz),
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .q(s1b)
);
mux_21 ic4(
    .I0(donvi),
    .I1(chuc),
    .BCD_out(BCD_in),
    .sel(s1b)
);
giaima_12h ic5(
    .i(s1b),
    .o_12h(cathode)
);
led_7seg ic6(
    .BCD_in(BCD_in),
    .LED(LED)
);
endmodule