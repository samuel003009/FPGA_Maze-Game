module PixelGen 
(
    input clk,
    input reset,
    input [9:0] pixel_x,
    input [9:0] pixel_y,
    input [9:0] player_x,
    input [9:0] player_y,
    output [3:0] R,
    output [3:0] G,
    output [3:0] B
);


    reg [3:0] r, g, b;
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

    parameter PosX = 260;       //迷宮左上角x座標
    parameter PosY = 180;       //迷宮左上角y座標
    parameter PixelSize = 4;    //每個格子的像素大小

    wire in_display_area = (pixel_x >= PosX && pixel_x < (PosX + 30 * PixelSize) &&
                            pixel_y >= PosY && pixel_y < (PosY + 30 * PixelSize));

    wire [4:0] mat_x = (pixel_x - PosX) / PixelSize;  // 欄位 (0~29)
    wire [4:0] mat_y = (pixel_y - PosY) / PixelSize;  // 列 (0~29)
    
    wire is_goal_block = (mat_x == 29) && (mat_y >= 23 && mat_y <= 25);         //判斷是否到達終點
    wire reached_goal  = (player_x == 29) && (player_y >= 23 && player_y <= 25);

  always @(*) begin
    // 判斷是否通關
    if (in_display_area) begin
        if (mat_x == player_x && mat_y == player_y) begin
            r = 4'h0; g = 4'hF; b = 4'h0;  // 綠色玩家
        end else if (is_goal_block && reached_goal) begin
            r = 4'hF; g = 4'h0; b = 4'h0;  // 紅色終點線
        end else if (pattern[mat_y][29 - mat_x] == 1'b1) begin
            r = 4'h0; g = 4'h0; b = 4'hF;  // 藍色牆
        end else begin
            r = 4'hF; g = 4'hF; b = 4'hF;  // 白色地板
        end
    end else begin
        r = 4'h0; g = 4'h0; b = 4'h0;      // 黑色畫面
    end
end

    assign R = r;
    assign G = g;
    assign B = b;

endmodule


