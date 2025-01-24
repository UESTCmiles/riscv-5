/*  模块名：dual_ram_mini
    作用：  真双口ram，但读写冲突时读取有问题，需要外套一层
    日期：  2024/10/9
    作者：  景绿川
    版本：  1.0 */

module dual_ram_mini #(
    parameter DW = 'd32,
    parameter AW = 'd12,
    parameter MEM_NUM = 'd4096
) (
    input               clk,
    input               rst_n,

    // wr
    input               wr_en,
    input [AW-1:0]      wr_addr_i,
    input [DW-1:0]      wr_data_i,


    // rd
    input               rd_en,
    input [AW-1:0]      rd_addr_i,
    output reg [DW-1:0] rd_data_o
);

    /* ********mem******* */
    reg [DW-1:0]mem[0:MEM_NUM-1];
    


    /* *********logic******** */
    // rd
    always@(posedge clk) begin
        if(rd_en)
            rd_data_o <= mem[rd_addr_i];
         
    end

    // wr
    always@(posedge clk) begin
        if(wr_en)
            mem[wr_addr_i] <= wr_data_i; 
    end


    
endmodule