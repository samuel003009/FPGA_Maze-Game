# FPGA_Maze-Game

## VGAClk252.xci : 產生VGA時脈
## vga_sync.v : VGA畫面顯示
‵‵‵
//640*480，總共 800*525 ，剩下是換行時間
	parameter H_sync_end = 96;		
	parameter V_sync_end = 2;		
	parameter H_sysc_Total = 800;	
	parameter V_sysc_Total = 525;	
	parameter H_Show_Start = 144;	
	parameter V_Show_Start = 35;
‵‵‵
## pixel_generation.v : 決定每個像素的顏色
## db_fsmp_imp.v : 按鈕去彈跳
## playercontrol.v : 移動與撞牆判斷
## vga_controller.v : 把所有模組串接在一起
## vga_controller.xdc : 指定實體腳位
