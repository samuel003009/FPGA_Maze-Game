# FPGA_Maze-Game

## VGAClk252.xci : 產生VGA時脈
將板子上的 100 MHz 時脈轉換成 VGA 需要的 25.2 MHz 像素時脈

## vga_sync.v : VGA畫面顯示
以 25.2 MHz 時脈產生 640×480 @ 60 Hz 的 VGA 同步訊號，並輸出目前掃描位置的座標
```
//640*480，總共 800*525 ，剩下是換列跟換一幀所需時間
	parameter H_sync_end = 96;		
	parameter V_sync_end = 2;		
	parameter H_sysc_Total = 800;	
	parameter V_sysc_Total = 525;	
	parameter H_Show_Start = 144;	
	parameter V_Show_Start = 35;
```
## pixel_generation.v : 決定每個像素的顏色
儲存 30×30 的迷宮地圖，依目前掃描座標判斷所在格子，畫出藍色牆壁、白色地板與綠色玩家，玩家到達終點時將終點顯示為紅色

```
reg [29:0] pattern [0:29];          //30*30矩陣
    initial begin           //迷宮結構
        pattern[0]  = 30'b111111111111111111111111111111;
        pattern[1]  = 30'b111111111111111111111111111111;
        pattern[2]  = 30'b111111111111111111111111111111;
        pattern[3]  = 30'b000000000000000000000000011111;
        pattern[4]  = 30'b000000000000000000000000011111;
        pattern[5]  = 30'b000000000000000000000000011111;
        pattern[6]  = 30'b111111111111111110001111111111;
        pattern[7]  = 30'b111111111111111110001111111111;
        pattern[8]  = 30'b111111111111111110001111111111;
        pattern[9]  = 30'b111111111111111110001111111111;
        pattern[10] = 30'b111111111111111110001111111111;
        pattern[11] = 30'b111111111111111110001111111111;
        pattern[12] = 30'b111111111111111110001111111111;
        pattern[13] = 30'b111111111111111110001111111111;
        pattern[14] = 30'b000000000000000000001111111111;
        pattern[15] = 30'b000000000000000000001111111111;
        pattern[16] = 30'b000000000000000000001111111111;
        pattern[17] = 30'b111000111111111110001111111111;
        pattern[18] = 30'b111000111111111110001100011111;
        pattern[19] = 30'b111000111111111111111100011111;
        pattern[20] = 30'b111000111111111111111100011111;
        pattern[21] = 30'b111000111111111111111100011111;
        pattern[22] = 30'b111000111111111111111100011111;
        pattern[23] = 30'b111000000000000000000000000000;
        pattern[24] = 30'b111000000000000000000000000000;
        pattern[25] = 30'b111000000000000000000000000000;
        pattern[26] = 30'b111111111111111111111111111111;
        pattern[27] = 30'b111111111111111111111111111111;
        pattern[28] = 30'b111111111111111111111111111111;
        pattern[29] = 30'b111111111111111111111111111111;
      
    end
```

```
  always @(*) begin
    // 判斷是否通關
    if (in_display_area) begin
        if (mat_x == player_x && mat_y == player_y) begin
            r = 4'h0; g = 4'hF; b = 4'h0;  // 綠色玩家
        end else if (is_goal_block && reached_goal) begin
            r = 4'hF; g = 4'h0; b = 4'h0;  // 紅色終點線
        end else if (pattern[mat_y][29 - mat_x] == 1'b1) begin
            r = 4'h0; g = 4'h0; b = 4'hF;  // 藍色牆，Verilog的編號從右邊開始數，所以pattern[0][29]是地圖最左上的地方
        end else begin
            r = 4'hF; g = 4'hF; b = 4'hF;  // 白色地板
        end
    end else begin
        r = 4'h0; g = 4'h0; b = 4'h0;      // 黑色畫面
    end
end
```

## db_fsmd_imp.v : 按鈕去彈跳
以狀態機搭配計數器，確認按鈕訊號穩定後才輸出一個時脈寬的脈衝，讓每按一次按鈕只移動一格

```
case (state_reg)
         zero:
            begin
               db_level = 1'b0;
               if (sw)
                  begin
                     state_next = wait1;
                     q_next = {N{1'b1}}; // load 1..1
                  end
            end
         wait1:
            begin
               db_level = 1'b0;
               if (sw)
                  begin
                     q_next = q_reg - 1;
                     if (q_next==0)
                        begin
                           state_next = one;
                           db_tick = 1'b1;
                        end
                  end
               else // sw==0
                  state_next = zero;
            end
         one:
            begin
               db_level = 1'b1;
               if (~sw)
                  begin
                     state_next = wait0;
                     q_next = {N{1'b1}}; // load 1..1
                  end
            end
         wait0:
            begin
               db_level = 1'b1;
               if (~sw)
                  begin
                     q_next = q_reg - 1;
                     if (q_next==0)
                        state_next = zero;
                  end
               else // sw==1
                  state_next = one;

            end
         default: state_next = zero;
      endcase
```
	  
## playercontrol.v : 移動與撞牆判斷
玩家可使用4個按鍵控制上下左右移動，依按下的方向檢查目標格是否為牆壁或超出邊界，可以通行時才更新玩家座標，按下 reset 時回到起點 (0, 3)

```
always @(posedge clk or posedge reset) begin        //reset 為1，回到初始位置，上緣觸發
        if (reset) begin
            player_x <= 5'd0;           //初始位置(0,3)
            player_y <= 5'd3;
        end else begin
            if (btn_up && player_y > 0 && pattern_row_up[29 - player_x] == 1'b0)
                player_y <= player_y - 1;       //y座標減1，向上一格，pattern_row_up[29 - player_x] : 上一列的值是不是0
            else if (btn_down && player_y < 29 && pattern_row_down[29 - player_x] == 1'b0)
                player_y <= player_y + 1;       //y座標加1，向下一格，pattern_row_up[29 + player_x] : 下一列的值是不是0
            else if (btn_left && player_x > 0 && pattern_row_curr[29 - (player_x - 1)] == 1'b0)
                player_x <= player_x - 1;       //x座標減1，向左一格，curr[29 - (player_x - 1)] : 左邊是不是0        
            else if (btn_right && player_x < 29 && pattern_row_curr[29 - (player_x + 1)] == 1'b0)
                player_x <= player_x + 1;       //x座標加1，向右一格，curr[29 - (player_x + 1)] : 右邊是不是0 
        end
    end
```

## vga_controller.v : 把所有模組串接在一起
將時脈產生、VGA 同步、像素產生、按鈕去彈跳與玩家控制等模組串接在一起

```
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
		.reset(~RESET),       //reset 為active high，所以用~RESET
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
			db_up_reg    <= db_up;           //把tick暫存進 db_reg，把值存起來保存到下一個上緣觸發
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
```

## vga_controller.xdc : 指定實體腳位
指定時脈、reset、四個方向按鈕，以及 VGA 輸出對應的 FPGA 實體腳位
