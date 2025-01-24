
/*  名称：riscv_soc
    作用：riscv cpu + 外设
    日期：2024/12/1
    作者：景绿川
    版本：4.0 */
    
`include "defines.v"
module riscv_soc #(
    parameter WIDTH = 'd32
) (
    input clk,
    input rst_n,

    inout[7:0] gpio,

    // uart
    input rx,

    
    //debug
    output [1:0]led         // bit0:烧录完成    bit1:cpu代码开始运行
);
    
    

    /* ****************temp signal**************** */
    // gpio
    wire [7:0]gpio_i;
    wire [7:0]gpio_o;
    wire [7:0]gpio_t;

    // riscv - rom
    wire [WIDTH-1:0]riscv_inst_i;
    wire [WIDTH-1:0]rom_inst_o;
    wire [WIDTH-1:0]riscv_inst_addr_o;

    //riscv - data_ram
    // wire [WIDTH-1:0]riscv_mem_rd_addr_o;
    // wire            riscv_mem_rd_req_o;
    // wire [WIDTH-1:0]data_ram_mem_rd_data_o;

    // wire [WIDTH-1:0]riscv_mem_wr_addr_o;
    // wire [3:0]      riscv_mem_wr_sel_o;
    // wire [WIDTH-1:0]riscv_mem_wr_data_o;

    // riscv - data_ram/gpio addr & wrdata0~4095 DATA_RAM 4096~4096+8 GPIO
    wire [WIDTH-1:0]riscv_perip_rd_addr_o;
    wire [WIDTH-1:0]riscv_perip_wr_addr_o;
    wire [WIDTH-1:0]riscv_perip_wr_data_o;


    // riscv - addr_decode
    wire            riscv_ad_rd_req_o;
    wire [3:0]      riscv_ad_wr_sel_o;

    // addr_decode - data_ram
    wire            ad_mem_rd_req_o;
    wire [3:0]      ad_mem_wr_sel_o;

    // addr_decode - gpio
    wire            ad_gpio_rd_en_o;
    wire            ad_gpio_wr_en_o;

    // data_ram - rdmux
    wire [WIDTH-1:0]mem_rdmux_rd_data_o;

    // gpio - rdmux
    wire [WIDTH-1:0]gpio_rdmux_rd_data_o;

    //rdmux - riscv
    wire [WIDTH-1:0]rd_mux_rd_data_o;

    //uart - rom
    wire [WIDTH-1:0]uart_rom_inst_o;
    wire [WIDTH-1:0]uart_rom_inst_addr_o;
    wire            uart_rom_inst_valid_o;

    wire            uart_rom_inst_tran_done_o;

    /* ************例化***************** */
    riscv #(
        .WIDTH(WIDTH)
    ) u_cpu(
        .clk            (clk),
        .rst_n          (rst_n),

        .inst_i         (riscv_inst_i),

        .inst_addr_o    (riscv_inst_addr_o),

        .mem_rd_addr_o  (riscv_perip_rd_addr_o),
        .mem_rd_req_o   (riscv_ad_rd_req_o),
        .mem_rd_data_i  (rd_mux_rd_data_o),

        // 写数据存储器
        .mem_wr_addr_o  (riscv_perip_wr_addr_o),
        .mem_wr_data_o  (riscv_perip_wr_data_o),
        .mem_wr_sel_o   (riscv_ad_wr_sel_o)
    );

    assign riscv_inst_i = ~uart_rom_inst_tran_done_o ? `INST_NOP : rom_inst_o; 

    rom #(
        .WIDTH(WIDTH)
    ) u_rom(
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (uart_rom_inst_valid_o),
        .wr_addr_i  (uart_rom_inst_addr_o),
        .wr_data_i  (uart_rom_inst_o),


        // rd
        .rd_en      (uart_rom_inst_tran_done_o),
        .rd_addr_i  (riscv_inst_addr_o),
        .rd_data_o  (rom_inst_o)
    );

    uart_debug #(
        .CLK_FREQ       (50_000_000),
        .BAUD_RATE      (1_000_000),
        .DW             (WIDTH)
    ) u_uart_debug(
        .clk            (clk),
        .rst_n          (rst_n),
        .rx             (rx),

        .inst           (uart_rom_inst_o),
        .inst_valid     (uart_rom_inst_valid_o),     //wren
        .inst_addr      (uart_rom_inst_addr_o),

        .inst_tran_done (uart_rom_inst_tran_done_o)  //rden
    );

    addr_decode #(
        .DW(WIDTH),
        .AW(WIDTH),
        .ADDR_END1('d4096)
    ) u_ad(
        .rd_en_i    (riscv_ad_rd_req_o),
        .rd_addr_i  (riscv_perip_rd_addr_o),
        
        .wr_en_i    (riscv_ad_wr_sel_o),
        .wr_addr_i  (riscv_perip_wr_addr_o),

        .rd_en_o    ({ad_gpio_rd_en_o,ad_mem_rd_req_o}),
        .wr_en_o    ({ad_gpio_wr_en_o,ad_mem_wr_sel_o})
    );

    data_ram #(
        .WIDTH(WIDTH)
    ) u_data_ram(
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (ad_mem_wr_sel_o),
        .wr_addr_i  (riscv_perip_wr_addr_o),
        .wr_data_i  (riscv_perip_wr_data_o),

        // rd
        .rd_en      (ad_mem_rd_req_o),
        .rd_addr_i  (riscv_perip_rd_addr_o),
        .rd_data_o  (mem_rdmux_rd_data_o)
    );

    gpio #(
        .AW(WIDTH),
        .DW(WIDTH),
        .GPIO_WIDTH(8)              // GPIO位宽(1~32)
    ) u_gpio(
        // 时钟和复位
        .clk        (clk),
        .rst_n      (rst_n),

        // wr
        .wr_en      (ad_gpio_wr_en_o),
        .wr_addr_i  (riscv_perip_wr_addr_o),
        .wr_data_i  (riscv_perip_wr_data_o),

        // rd
        .rd_en      (ad_gpio_rd_en_o),
        .rd_addr_i  (riscv_perip_rd_addr_o),
        .rd_data_o  (gpio_rdmux_rd_data_o),

        //gpio
        .gpio_i     (gpio_i), 
        .gpio_o     (gpio_o), 
        .gpio_t     (gpio_t)
    );

    rd_data_mux #(
        .AW(WIDTH),
        .DW(WIDTH),
        .ADDR_END1('d4096)
    ) u_rxmux(
        .clk        (clk),
        .rd_addr_i  (riscv_perip_rd_addr_o),

        .rd_data1_i (mem_rdmux_rd_data_o),
        .rd_data2_i (gpio_rdmux_rd_data_o),

        .rd_data_o  (rd_mux_rd_data_o)
    );

    //gpio
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign gpio[i]     = gpio_t[i] ? 1'bz : gpio_o[i];
            assign gpio_i[i]   = gpio[i]; 
        end
    endgenerate
    

    assign led = {~uart_rom_inst_tran_done_o,1'b0};
    
endmodule
