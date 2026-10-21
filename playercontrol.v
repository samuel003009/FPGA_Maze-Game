module PlayerControl (
    input clk,
    input reset,
    input btn_up,
    input btn_down,
    input btn_left,
    input btn_right,
    input [29:0] pattern_row_up,
    input [29:0] pattern_row_down,
    input [29:0] pattern_row_curr,
    output reg [4:0] player_x,
    output reg [4:0] player_y
);
    always @(posedge clk or posedge reset) begin        //reset 為1，回到初始位置，上緣觸發
        if (reset) begin
            player_x <= 5'd0;           //初始位置(0,3)
            player_y <= 5'd3;
        end else begin
            if (btn_up && player_y > 0 && pattern_row_up[29 - player_x] == 1'b0)
                player_y <= player_y - 1;       //y座標減1，向上一格
            else if (btn_down && player_y < 29 && pattern_row_down[29 - player_x] == 1'b0)
                player_y <= player_y + 1;       //y座標加1，向下一格
            else if (btn_left && player_x > 0 && pattern_row_curr[29 - (player_x - 1)] == 1'b0)
                player_x <= player_x - 1;       //x座標減1，向左          
            else if (btn_right && player_x < 29 && pattern_row_curr[29 - (player_x + 1)] == 1'b0)
                player_x <= player_x + 1;       //x座標加1，向右一格
        end
    end
endmodule
