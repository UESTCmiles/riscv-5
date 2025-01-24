module dff #(
    parameter DW = 'd32
) (
    input               clk,
    input [DW-1:0]      data_i,
    output reg [DW-1:0] data_o
);
    always@(posedge clk) data_o <= data_i;
    
endmodule