`timescale 1ns / 1ps

module line_skipper(
		input wire clk,
		input wire rst,
		
		//pixel input
		input wire [15:0] raw_pixel_in,
		input wire raw_pixel_valid_in,
		input wire readout_busy_in,
		input wire line_sync,
		
		output wire [31:0] axi_data_buffer_o,
		output wire axi_send_pulse_o
);

reg line_sync_ff1;
reg line_sync_ff2;
wire line_sync_pulse = (line_sync_ff1 && ~line_sync_ff2) ? 1'b1 : 1'b0;

always @(posedge clk ) begin
	if(raw_pixel_valid_in) begin
		line_sync_ff1 <= line_sync;
		line_sync_ff2 <= line_sync_ff1;
	end
end

(* MARK_DEBUG="true" *)reg [15:0] skip_pixel_cnt;
(* MARK_DEBUG="true" *)reg [15:0] skip_line_cnt;

(* MARK_DEBUG="true" *)reg [7:0] pixel_cnt_x;
(* MARK_DEBUG="true" *)reg [7:0] pixel_cnt_y;

(* MARK_DEBUG="true" *) reg [3:0] state_q;
parameter SKIP_FIRST_55_PIX = 4'b0000;
parameter COUNT_24_PIXEL = 4'b0001;
parameter SEND_PIXEL = 4'b0011;
parameter SKIP_6_LINE = 4'b0010;
parameter DONE = 4'b0110;

localparam SKIP_INVALID_PIX = 55;
localparam TOTAL_LINE = 1024;
localparam PIXEL_PER_LINE = 5760;
localparam SKIPED_PIX = 24;
localparam SKIPED_LINE = 6;
localparam VIEWFINDER_X = 240;
localparam VIEWFINDER_Y = 160;

//gamma correction
reg [4:0] gamma_corrected_buf;
always @(posedge clk or posedge rst) begin
    if(rst || ~readout_busy_in)begin
        gamma_corrected_buf <= 0;
    end
    else if(raw_pixel_valid_in) begin
        case (raw_pixel_in[15:11])
            'd00: gamma_corrected_buf <= 'd00;
            'd01: gamma_corrected_buf <= 'd07;
            'd02: gamma_corrected_buf <= 'd09;
            'd03: gamma_corrected_buf <= 'd11;
            'd04: gamma_corrected_buf <= 'd12;
            'd05: gamma_corrected_buf <= 'd14;
            'd06: gamma_corrected_buf <= 'd15;
            'd07: gamma_corrected_buf <= 'd16;
            'd08: gamma_corrected_buf <= 'd17;
            'd09: gamma_corrected_buf <= 'd18;
            'd10: gamma_corrected_buf <= 'd19;
            'd11: gamma_corrected_buf <= 'd19;
            'd12: gamma_corrected_buf <= 'd20;
            'd13: gamma_corrected_buf <= 'd21;
            'd14: gamma_corrected_buf <= 'd22;
            'd15: gamma_corrected_buf <= 'd22;
            'd16: gamma_corrected_buf <= 'd23;
            'd17: gamma_corrected_buf <= 'd24;
            'd18: gamma_corrected_buf <= 'd24;
            'd19: gamma_corrected_buf <= 'd25;
            'd20: gamma_corrected_buf <= 'd25;
            'd21: gamma_corrected_buf <= 'd26;
            'd22: gamma_corrected_buf <= 'd27;
            'd23: gamma_corrected_buf <= 'd27;
            'd24: gamma_corrected_buf <= 'd28;
            'd25: gamma_corrected_buf <= 'd28;
            'd26: gamma_corrected_buf <= 'd29;
            'd27: gamma_corrected_buf <= 'd29;
            'd28: gamma_corrected_buf <= 'd30;
            'd29: gamma_corrected_buf <= 'd30;
            'd30: gamma_corrected_buf <= 'd31;
            'd31: gamma_corrected_buf <= 'd31;
        
            default: gamma_corrected_buf <= 0;
        endcase
    end

end

reg buffer_valid;
wire [15:0] rgb565_gray = {gamma_corrected_buf, gamma_corrected_buf, 1'b0 , gamma_corrected_buf};

always @(posedge clk or posedge rst) begin
	if(rst || ~readout_busy_in) begin
		state_q <= SKIP_FIRST_55_PIX;
		skip_pixel_cnt <= 0; 
		skip_line_cnt <= 0;
		pixel_cnt_x <= 0;
		pixel_cnt_y <= 0;
		buffer_valid <= 0;
	end
	else if(raw_pixel_valid_in) begin
		case (state_q)
			SKIP_FIRST_55_PIX: begin
				if (skip_pixel_cnt >= SKIP_INVALID_PIX) begin
					state_q <= COUNT_24_PIXEL;
					
					skip_pixel_cnt <= 0;
				end
				else begin
					skip_pixel_cnt <= skip_pixel_cnt + 1;
				end
			end

			COUNT_24_PIXEL: begin
				if (skip_pixel_cnt < SKIPED_PIX) begin
					skip_pixel_cnt <= skip_pixel_cnt + 1;
				end
				else begin
					state_q <= SEND_PIXEL;
					buffer_valid <= 1;

					skip_pixel_cnt <= 0;
				end
			end

			SEND_PIXEL: begin
				if (pixel_cnt_x < VIEWFINDER_X) begin
					pixel_cnt_x <= pixel_cnt_x + 1;
					buffer_valid <= 0;

					state_q <= COUNT_24_PIXEL;
				end
				else begin
					pixel_cnt_x <= 0;

					state_q <= SKIP_6_LINE;
				end
			end

			SKIP_6_LINE: begin
				if (line_sync_pulse) begin
					if (pixel_cnt_y >= VIEWFINDER_Y) begin
						state_q <= DONE;

						pixel_cnt_y <= 0;
					end
					else if (skip_line_cnt < SKIPED_LINE - 1) begin
						skip_line_cnt <= skip_line_cnt + 1;
					end
					else begin
						skip_line_cnt <= 0;
						pixel_cnt_y <= pixel_cnt_y + 1;

						state_q <= COUNT_24_PIXEL;
					end
				end	
			end

			DONE: begin
				
			end

			default: state_q <= DONE;
		endcase
	end
end

reg buffer_valid_ff;
wire buffer_valid_pulse = (buffer_valid && ~buffer_valid_ff) ? 1'b1 : 1'b0 ;

always @(posedge clk) begin
	buffer_valid_ff <= buffer_valid;
end

reg [31:0] axi_send_buffer;
reg axi_send_cnt;
reg axi_send_pulse;

assign axi_data_buffer_o = axi_send_buffer;
assign axi_send_pulse_o = axi_send_pulse;

always @(posedge clk or posedge rst) begin
	if (rst) begin
		axi_send_buffer <= 0;
		axi_send_pulse <= 0;
		axi_send_cnt <= 0;
	end
	else begin
		if (buffer_valid_pulse) begin
			axi_send_buffer <= {axi_send_buffer[15:0],rgb565_gray};
		end	
		
		if (buffer_valid_pulse) begin
			axi_send_cnt <= axi_send_cnt + 1;
		end

		if (axi_send_cnt && buffer_valid_pulse) begin
			axi_send_pulse <= 1;
		end
		else begin
			axi_send_pulse <= 0;
		end
	end 
end

endmodule
