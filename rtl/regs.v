/*  Ä£¿éÃû£ºregs
    ×÷ÓÃ£º¼Ä´æÆ÷×é
    ÈÕÆÚ£º2024/9/12
    ×÷Õß£º¾°ÂÌ´¨
    °æ±¾£º1.0 */

module regs #(
    parameter WIDTH = 32
) (
    input                   clk,
    input                   rst_n,

    // from id
    input [log2n(WIDTH)-1:0]rs1_raddr_i,
    input [log2n(WIDTH)-1:0]rs2_raddr_i,

    // to id
    output reg[WIDTH-1:0]   rs1_rdata_o,
    output reg[WIDTH-1:0]   rs2_rdata_o,

    // from ex
    input [log2n(WIDTH)-1:0]reg_waddr_i,
    input [WIDTH-1:0]       reg_wdata_i,
    input                   reg_wen_i
);  
    /* *************temp signal****************** */
    // ¼Ä´æÆ÷×é
    reg [31:0]regs[0:31];

    /* ****************logic****************** */
    // rs1
    always@(*) begin
        if(!rst_n)
            rs1_rdata_o = 'd0; 
        else if(rs1_raddr_i == 'd0)
            rs1_rdata_o = 'd0;
        else if (reg_wen_i && (reg_waddr_i == rs1_raddr_i))   // ·ÀÖ¹Ö¸Áî³åÍ»
            rs1_rdata_o = reg_wdata_i;
        else
            rs1_rdata_o = regs[rs1_raddr_i];
    end

    // rs2
    always@(*) begin
        if(!rst_n)
            rs2_rdata_o = 'd0;
        else if(rs2_raddr_i == 'd0)
            rs2_rdata_o = 'd0;
        else if (reg_wen_i && (reg_waddr_i == rs2_raddr_i))   // ·ÀÖ¹Ö¸Áî³åÍ»
            rs2_rdata_o = reg_wdata_i;
        else
            rs2_rdata_o = regs[rs2_raddr_i]; 
    end

    // Ğ´¼Ä´æÆ÷
    integer i;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0; 
            end 
        end
        else if(reg_wen_i && (reg_waddr_i != 'd0))
            regs[reg_waddr_i] <= reg_wdata_i;

    end


    /* ******************function****************** */
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