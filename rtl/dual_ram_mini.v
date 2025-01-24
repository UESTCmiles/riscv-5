/*  ģ������dual_ram_mini
    ���ã�  ��˫��ram������д��ͻʱ��ȡ�����⣬��Ҫ����һ��
    ���ڣ�  2024/10/9
    ���ߣ�  ���̴�
    �汾��  1.0 */

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