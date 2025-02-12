/*  dff_rn
    作用：标准dff模块，带异步resetn，复位默认值为0
    日期：2024/9/20
    作者：景绿川
    版本：1.0 */
module dff_rn #(
    parameter WIDTH = 32
)(
    input                   clk,
    input                   rst_n,

    input [WIDTH-1:0]       rst_data,
    input [WIDTH-1:0]       data_i,
    output reg[WIDTH-1:0]   data_o

);

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            data_o <= rst_data;
        else
            data_o <= data_i; 
    end

endmodule