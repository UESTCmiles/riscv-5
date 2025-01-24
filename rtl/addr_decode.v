/*  名称：addr_decode
    作用：根据地址选择访存模块:0~4095 数据存储器    4096~4096+8 GPIO
    日期：2024/11/29
    作者：景绿川 */
module addr_decode #(
    parameter DW = 'd32,
    parameter AW = 'd32,
    parameter ADDR_END1 = 'd4096
) (
    input rd_en_i,
    input [AW-1:0]rd_addr_i,
    
    input [3:0]wr_en_i,
    input [AW-1:0]wr_addr_i,

    output [1:0]rd_en_o,            // bit1:gpio rden    bit0:dataram rden
    output [4:0]wr_en_o             // bit4:gpio wren    bit3:0:dataram wren
);
    assign rd_en_o = rd_addr_i[AW-1:2] >= ADDR_END1 ? {rd_en_i,1'b0} : {1'b0,rd_en_i};
    assign wr_en_o = wr_addr_i[AW-1:2] >= ADDR_END1 ? {|wr_en_i,4'd0} : {1'b0,wr_en_i};

    
endmodule