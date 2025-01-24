/*  名称：Inst_Decode
    作用：相比1.2增加了load store指令，增加了对data_ram的读请求
    日期：2024/9/22
    作者：景绿川
    版本：1.3 */
    
`include "defines.v"
module Inst_Decode #(
    parameter WIDTH = 32
) (
    input [WIDTH-1:0]           inst_addr_i,
    input [WIDTH-1:0]           inst_i,

    // from regs
    input [WIDTH-1:0]           rs1_data_i,         
    input [WIDTH-1:0]           rs2_data_i,         

    // to regs
    output reg[log2n(WIDTH)-1:0]rs1_addr_o,         
    output reg[log2n(WIDTH)-1:0]rs2_addr_o,         

    // to next level
    output [WIDTH-1:0]          inst_o,
    output [WIDTH-1:0]          inst_addr_o,
    output reg[WIDTH-1:0]       op1_o,
    output reg[WIDTH-1:0]       op2_o,
    output reg[log2n(WIDTH)-1:0]rd_addr_o,
    output reg                  regs_wen_o,
    output reg[WIDTH-1:0]       addr_offset_o,
    output reg[WIDTH-1:0]       base_addr_o,

    // to data_ram
    output reg[WIDTH-1:0]       mem_rd_addr_o,
    output reg                  mem_rd_req_o

);      
    /* ***********temp signal************* */
    wire [6:0]opcode;
    wire [4:0]rd;
    wire [2:0]funct3;
    wire [4:0]rs1;
    wire [4:0]rs2;
    wire [6:0]funct7;
    wire [11:0]imm;
    wire [4:0]shamt;
    
    wire [31:0]b_imm;
    wire [31:0]jal_imm;
    wire [31:0]jalr_imm;

    /* *************logic***************** */
    assign opcode   = inst_i[6:0];
    assign rd       = inst_i[11:7];
    assign funct3   = inst_i[14:12];
    assign rs1      = inst_i[19:15];
    assign rs2      = inst_i[24:20];
    assign funct7   = inst_i[31:25];
    assign imm      = inst_i[31:20];
    assign shamt    = inst_i[24:20];

    assign b_imm    = {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
    assign jal_imm  = {{12{inst_i[31]}},inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};      // jal的立即数imm
    assign jalr_imm = {{20{imm[11]}},imm};
    always@(*) begin
        case (opcode)
            // I
            `INST_TYPE_I:   begin
                base_addr_o     = 'd0;
                addr_offset_o   = 'd0;
                mem_rd_addr_o   = 'd0;
                mem_rd_req_o    = 1'b0;
                case (funct3)
                    `INST_ADDI,`INST_SLTI,`INST_SLTIU,`INST_XORI,`INST_ORI,`INST_ANDI: begin
                        rs1_addr_o  = rs1;
                        rs2_addr_o  = 'd0;

                        op1_o       = rs1_data_i;
                        op2_o       = {{20{imm[11]}},imm};

                        rd_addr_o   = rd;
                        regs_wen_o  = 1'b1;
                            
                    end
                    `INST_SLLI,`INST_SRI: begin
                        rs1_addr_o  = rs1;
                        rs2_addr_o  = 'd0;

                        op1_o       = rs1_data_i;
                        op2_o       = {27'd0,shamt};

                        rd_addr_o   = rd;
                        regs_wen_o  = 1'b1;
                    end 
                    default: begin
                        rs1_addr_o  = 5'd0;
                        rs2_addr_o  = 5'd0;

                        op1_o       = 32'd0;
                        op2_o       = 32'd0;

                        rd_addr_o   = 5'd0;
                        regs_wen_o  = 1'b0;
                    end
                endcase
            end
            `INST_TYPE_R_M: begin
                base_addr_o     = 'd0;
                addr_offset_o   = 'd0;
                mem_rd_addr_o   = 'd0;
                mem_rd_req_o    = 1'b0;
                case (funct3)
                    `INST_ADD_SUB,`INST_XOR,`INST_OR,`INST_AND,`INST_SLT,`INST_SLTU: begin
                        rs1_addr_o  = rs1;
                        rs2_addr_o  = rs2;

                        op1_o       = rs1_data_i;
                        op2_o       = rs2_data_i;

                        rd_addr_o   = rd;
                        regs_wen_o  = 1'b1;
                    end
                    `INST_SLL,`INST_SR: begin
                        rs1_addr_o  = rs1;
                        rs2_addr_o  = rs2;

                        op1_o       = rs1_data_i;
                        op2_o       = {27'd0,rs2_data_i[4:0]};

                        rd_addr_o   = rd;
                        regs_wen_o  = 1'b1; 
                    end
                    default: begin
                        rs1_addr_o  = 'd0;
                        rs2_addr_o  = 'd0;

                        op1_o       = 'd0;
                        op2_o       = 'd0;

                        rd_addr_o   = 'd0;
                        regs_wen_o  = 1'b0; 
                    end
                endcase
            end
            `INST_TYPE_B:   begin
                mem_rd_addr_o   = 'd0;
                mem_rd_req_o    = 1'b0;
                case (funct3)
                    `INST_BNE,`INST_BEQ,`INST_BLT,`INST_BGE,`INST_BLTU,`INST_BGEU: begin
                        rs1_addr_o      = rs1;
                        rs2_addr_o      = rs2;

                        op1_o           = rs1_data_i;
                        op2_o           = rs2_data_i;

                        rd_addr_o       = 'd0;
                        regs_wen_o      = 1'b0;

                        base_addr_o     = inst_addr_i;
                        addr_offset_o   = b_imm;
                    end 
                    default: begin
                        rs1_addr_o      = 'd0;
                        rs2_addr_o      = 'd0;

                        op1_o           = 'd0;
                        op2_o           = 'd0;

                        rd_addr_o       = 'd0;
                        regs_wen_o      = 1'b0; 

                        base_addr_o     = 'd0;
                        addr_offset_o   = 'd0;
                    end
                endcase 
            end
            `INST_JAL:      begin
                rs1_addr_o      = 'd0;
                rs2_addr_o      = 'd0;

                op1_o           = inst_addr_i;
                op2_o           = 'd4;

                rd_addr_o       = rd;
                regs_wen_o      = 1'b1;

                base_addr_o     = inst_addr_i;
                addr_offset_o   = jal_imm;

                mem_rd_addr_o   = 'd0;
                mem_rd_req_o    = 1'b0;
            end 
            `INST_JALR:     begin
                rs1_addr_o      = rs1;
                rs2_addr_o      = 5'd0;

                op1_o           = inst_addr_i;
                op2_o           = 'd4;

                rd_addr_o       = rd;
                regs_wen_o      = 1'b1; 

                base_addr_o     = rs1_data_i;
                addr_offset_o   = jalr_imm;

                mem_rd_addr_o   = 'd0;
                mem_rd_req_o    = 1'b0;
            end
            `INST_LUI:      begin
                rs1_addr_o  = 'd0;
                rs2_addr_o  = 'd0;

                op1_o       = {inst_i[31:12],12'b0};      // lui的立即数imm
                op2_o       = 'd0;

                rd_addr_o   = rd;
                regs_wen_o  = 1'b1;

                base_addr_o     = 'd0;
                addr_offset_o   = 'd0;

                mem_rd_addr_o   = 'd0;
                mem_rd_req_o    = 1'b0;
            end
            `INST_AUIPC:    begin
                rs1_addr_o  = 'd0;
                rs2_addr_o  = 'd0;

                op1_o       = {inst_i[31:12],12'b0};      // lui的立即数imm
                op2_o       = inst_addr_i;

                rd_addr_o   = rd;
                regs_wen_o  = 1'b1;

                base_addr_o     = 'd0;
                addr_offset_o   = 'd0;

                mem_rd_addr_o   = 'd0;
                mem_rd_req_o    = 1'b0;
            end
            `INST_TYPE_L:   begin
                case (funct3)
                    `INST_LB,`INST_LH,`INST_LW,`INST_LBU,`INST_LHU: begin
                        rs1_addr_o      = rs1;
                        rs2_addr_o      = 5'd0;

                        op1_o           = 32'd0;
                        op2_o           = 32'd0;

                        rd_addr_o       = rd;
                        regs_wen_o      = 1'b1;

                        base_addr_o     = rs1_data_i;
                        addr_offset_o   = {{20{imm[11]}},imm};

                        mem_rd_addr_o   = rs1_data_i + {{20{imm[11]}},imm};
                        mem_rd_req_o    = 1'b1;
                    end 
                    default: begin
                        rs1_addr_o      = 5'd0;
                        rs2_addr_o      = 5'd0;

                        op1_o           = 32'd0;
                        op2_o           = 32'd0;

                        rd_addr_o       = 5'd0;
                        regs_wen_o      = 1'b0;

                        base_addr_o     = 'd0;
                        addr_offset_o   = 'd0;

                        mem_rd_addr_o   = 'd0;
                        mem_rd_req_o    = 1'b0;
                    end
                endcase
            end
            `INST_TYPE_S:   begin
                case (funct3)
                    `INST_SB,`INST_SH,`INST_SW: begin
                        rs1_addr_o  = rs1;
                        rs2_addr_o  = rs2;

                        op1_o       = 'd0;
                        op2_o       = rs2_data_i;

                        rd_addr_o   = 'd0;
                        regs_wen_o  = 1'b0;

                        base_addr_o     = rs1_data_i;
                        addr_offset_o   = {{20{inst_i[31]}},inst_i[31:25],inst_i[11:7]};

                        mem_rd_addr_o   = 'd0;
                        mem_rd_req_o    = 1'b0;
                    end 
                    default: begin     
                        rs1_addr_o  = 5'd0;
                        rs2_addr_o  = 5'd0;

                        op1_o       = 32'd0;
                        op2_o       = 32'd0;

                        rd_addr_o   = 5'd0;
                        regs_wen_o  = 1'b0;

                        base_addr_o     = 'd0;
                        addr_offset_o   = 'd0;

                        mem_rd_addr_o   = 'd0;
                        mem_rd_req_o    = 1'b0;
                    end
                endcase
                 
            end
            default: begin
                rs1_addr_o  = 5'd0;
                rs2_addr_o  = 5'd0;

                op1_o       = 32'd0;
                op2_o       = 32'd0;

                rd_addr_o   = 5'd0;
                regs_wen_o  = 1'b0;

                base_addr_o     = 'd0;
                addr_offset_o   = 'd0;

                mem_rd_addr_o   = 'd0;
                mem_rd_req_o    = 1'b0;
            end
        endcase 
    end
    assign inst_o = inst_i;
    assign inst_addr_o = inst_addr_i;

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
    