/*  名称：ID2EX
    作用：与1.0相比添加了与ctrl模块的互连，增加了流水线冲刷机制
    日期：2024/9/22
    作者：景绿川
    版本：1.1 */
`include "defines.v"
module ID2EX #(
    parameter WIDTH = 32
) (
    input                       clk,
    input                       rst_n,

    input [WIDTH-1:0]           inst_i,
    input [WIDTH-1:0]           inst_addr_i,

    input [WIDTH-1:0]           op1_i,
    input [WIDTH-1:0]           op2_i,

    input [WIDTH-1:0]           base_addr_i,
    input [WIDTH-1:0]           addr_offset_i,

    input [log2n(WIDTH)-1:0]    rd_addr_i,
    input                       reg_wen_i,

    output [WIDTH-1:0]          inst_o,
    output [WIDTH-1:0]          inst_addr_o,

    output [WIDTH-1:0]          op1_o,
    output [WIDTH-1:0]          op2_o,

    output [WIDTH-1:0]          base_addr_o,
    output [WIDTH-1:0]          addr_offset_o,

    output [log2n(WIDTH)-1:0]   rd_addr_o,
    output                      reg_wen_o,

    // from ctrl
    input                       hold_flag_i


);  
    // inst
    dff_rnl #(WIDTH)         dff1(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data(`INST_NOP),.data_i(inst_i),.data_o(inst_o));

    // inst_addr
    dff_rnl #(WIDTH)         dff2(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data('d0),.data_i(inst_addr_i),.data_o(inst_addr_o));

    // op1
    dff_rnl #(WIDTH)         dff3(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data('d0),.data_i(op1_i),.data_o(op1_o));

    // op2
    dff_rnl #(WIDTH)         dff4(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data('d0),.data_i(op2_i),.data_o(op2_o));

    // rd_addr
    dff_rnl #(log2n(WIDTH))  dff5(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data(5'd0),.data_i(rd_addr_i),.data_o(rd_addr_o));

    // reg_wen
    dff_rnl #(1'b1)          dff6(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data(1'b0),.data_i(reg_wen_i),.data_o(reg_wen_o));

    // base_addr
    dff_rnl #(WIDTH)         dff7(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data('d0),.data_i(base_addr_i),.data_o(base_addr_o));

    // addr_offset
    dff_rnl #(WIDTH)         dff8(.clk(clk),.rst_n(rst_n),.hold_flag(hold_flag_i),.rst_data('d0),.data_i(addr_offset_i),.data_o(addr_offset_o));


    /* always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            inst_o <= `INST_NOP;
            inst_addr_o <= 'd0;
            op1_o <= 'd0;
            op2_o <= 'd0; 
            rd_addr_o <= 'd0;
            reg_wen_o <= 1'b0;
        end 
        else begin
            inst_o <= inst_i;
            inst_addr_o <= inst_addr_i;
            op1_o <= op1_i;
            op2_o <= op2_i;
            rd_addr_o <= rd_addr_i;
            reg_wen_o <= reg_wen_i; 
        end
    end */




    /* *****************function****************** */

    function integer log2n;
        input integer length;
        integer tmp;
    begin
        tmp = length;
        for(log2n = 0; tmp > 1;log2n = log2n + 1)
            tmp = tmp >> 1;
    end
        
    endfunction
    
endmodule