/*  名称：Inst_Fetch
    作用：向ROM中输入指令地址，获取指令信息，并对inst_addr打拍，以保持时序与inst相同
    日期：2024/9/12
    作者：景绿川
    版本：1.1 */
`include "defines.v"
module Inst_Fetch #(
    parameter WIDTH = 32
) (
    input               clk,
    input               rst_n,

    // from pc
    input [WIDTH-1:0]   inst_addr_i,

    // from rom
    input [WIDTH-1:0]   inst_i,
    
    // to ID
    output [WIDTH-1:0]  inst_addr_o,    // also to rom
    output [WIDTH-1:0]  inst_o,

    // from ctrl
    input               hold_flag_i
);  

    reg inst_valid_flag;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            inst_valid_flag <= 1'b0;
        else if(hold_flag_i)
            inst_valid_flag <= 1'b0;
        else
            inst_valid_flag <= 1'b1;
    end

    assign inst_o = inst_valid_flag ? inst_i : `INST_NOP;

    dff_rnl #(WIDTH) u_dff1(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data('d0),.data_i(inst_addr_i),.data_o(inst_addr_o));
    
endmodule