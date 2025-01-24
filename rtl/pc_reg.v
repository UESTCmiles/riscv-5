/*  名称：pc_reg
    作用：相比较宇1.0新增了与ctrl模块的链接，增加了流水线冲刷功能
    日期：2024/9/22
    作者：景绿川
    版本：1.1 */

module pc_reg #(
    parameter WIDTH = 32
) (
    input                   clk,
    input                   rst_n,

    output reg[WIDTH-1:0]   inst_addr,

    // from ctrl
    input [WIDTH-1:0]       jump_addr_i,
    input                   jump_en_i
);

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            inst_addr <= 'd0;
        else if(jump_en_i)
            inst_addr <= jump_addr_i;
        else
            inst_addr <= inst_addr + 'd4;
    end
    
endmodule