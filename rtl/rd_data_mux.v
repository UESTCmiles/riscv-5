module rd_data_mux #(
    parameter AW = 'd32,
    parameter DW = 'd32,
    parameter ADDR_END1 = 'd4096
) (
    input clk,
    input [AW-1:0]rd_addr_i,

    input [DW-1:0]rd_data1_i,// data_ram rd data
    input [DW-1:0]rd_data2_i,// gpio rd data

    output [DW-1:0]rd_data_o
);
    wire [AW-1:0]rd_addr_d;
    dff #(DW) u_dff (.clk(clk),.data_i(rd_addr_i),.data_o(rd_addr_d));

    assign rd_data_o = rd_addr_d >= ADDR_END1 ? rd_data2_i : rd_data1_i;
    
endmodule