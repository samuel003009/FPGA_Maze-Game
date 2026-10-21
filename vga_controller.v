module VGAController
(
	input CLK_100M,
	input RESET,
	input [3:0] BTN,
	output vga_hs_pin,
	output vga_vs_pin,
	output [3:0] vga_R_Data_pin,
	output [3:0] vga_G_Data_pin,
	output [3:0] vga_B_Data_pin
);

	wire VGA_clk;
	wire [9:0] pixel_x;
	wire [9:0] pixel_y;
	wire [9:0] player_x, player_y;

	VGAClk252 vga_clk_252      //把100MHz分成25.2MHz
	(
		.clk_in1(CLK_100M),
		.resetn(RESET),
		.clk_out1(VGA_clk),
		.locked()
	);

	
	VGASync vga_sync       //VGA訊號同步
	(          
		.clk(VGA_clk),
		.reset(RESET),
		.hsync(vga_hs_pin),
		.vsync(vga_vs_pin),
		.pixel_x(pixel_x),
		.pixel_y(pixel_y)
	);

	
	PixelGen pixel_gen     //產生像素及是否到達終點
	(
		.clk(VGA_clk),
		.reset(RESET),
		.pixel_x(pixel_x),
		.pixel_y(pixel_y),
		.player_x(player_x),
		.player_y(player_y),
		.R(vga_R_Data_pin),
		.G(vga_G_Data_pin),
		.B(vga_B_Data_pin)
	);


	wire db_up, db_down, db_left, db_right;

	db_fsmd_imp db_up_inst      //去彈跳處理
	(      
		.clk(CLK_100M),
		.reset(~RESET),       //rest 為active high，所以用~RESET
		.sw(BTN[0]),
		.db_level(),
		.db_tick(db_up)
	);

	db_fsmd_imp db_down_inst 
	(
		.clk(CLK_100M),
		.reset(~RESET),
		.sw(BTN[1]),
		.db_level(),
		.db_tick(db_down)
	);

	db_fsmd_imp db_left_inst 
	(
		.clk(CLK_100M),
		.reset(~RESET),
		.sw(BTN[2]),
		.db_level(),
		.db_tick(db_left)
	);

	db_fsmd_imp db_right_inst 
	(
		.clk(CLK_100M),
		.reset(~RESET),
		.sw(BTN[3]),
		.db_level(),
		.db_tick(db_right)
	);

	//延長 tick 跨時脈給 VGA_clk
	reg db_up_reg, db_down_reg, db_left_reg, db_right_reg;

	always @(posedge VGA_clk or posedge RESET) begin           //debounce 在100MHz，pixelgen跟player contrl 在25.2MHz
		if (RESET) begin
			db_up_reg    <= db_up;           //把tick暫存進 db_reg
			db_down_reg  <= db_down;
			db_left_reg  <= db_left;
			db_right_reg <= db_right;
		end else begin
			db_up_reg    <= 1'b0;
			db_down_reg  <= 1'b0;
			db_left_reg  <= 1'b0;
			db_right_reg <= 1'b0;
		end
	end


	

    wire [29:0] pattern_row_up    = (player_y > 0)  ? pixel_gen.pattern[player_y - 1] : 30'b0;
    wire [29:0] pattern_row_down  = (player_y < 29) ? pixel_gen.pattern[player_y + 1] : 30'b0;
    wire [29:0] pattern_row_curr  = pixel_gen.pattern[player_y];
    
    	PlayerControl player_ctrl          //玩家位置更新
    	(
            .clk(CLK_100M),
            .reset(~RESET),
            .btn_up(db_up_reg),
            .btn_down(db_down_reg),
            .btn_left(db_left_reg),
            .btn_right(db_right_reg),
            .pattern_row_up(pattern_row_up),
            .pattern_row_down(pattern_row_down),
            .pattern_row_curr(pattern_row_curr),
            .player_x(player_x),
            .player_y(player_y)
	   );

endmodule
