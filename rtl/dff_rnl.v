/*  ģ������dff_rne
    ���ã�  ��׼dffģ�飬���첽resetn����ͬ����ʹ�ܣ���λĬ��ֵΪ0
    ���ڣ�  2024/9/20
    ���ߣ�  ���̴�
    �汾��  1.0 */
module dff_rnl #(
    parameter WIDTH = 32
)(
    input                   clk,
    input                   rst_n,
    input                   hold_flag,

    input [WIDTH-1:0]       rst_data,
    input [WIDTH-1:0]       data_i,
    output reg[WIDTH-1:0]   data_o

);

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            data_o <= rst_data;
        else if(hold_flag)
            data_o <= rst_data;
        else
            data_o <= data_i; 
    end

endmodule