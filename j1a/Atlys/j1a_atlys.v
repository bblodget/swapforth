`default_nettype none

module bram_tdp #(
    parameter DATA = 16,
    parameter ADDR = 12
) (
    // Port A
    input   wire                a_clk,
    input   wire                a_wr,
    input   wire    [ADDR-1:0]  a_addr,
    input   wire    [DATA-1:0]  a_din,
    output  reg     [DATA-1:0]  a_dout,
     
    // Port B
    input   wire                b_clk,
    input   wire                b_wr,
    input   wire    [ADDR-1:0]  b_addr,
    input   wire    [DATA-1:0]  b_din,
    output  reg     [DATA-1:0]  b_dout
);
 
// Shared memory
reg [DATA-1:0] mem [(2**ADDR)-1:0];
  initial begin
    $readmemh("../build/nuc.hex", mem);
    // $readmemh("../build/hello.hex", mem);
  end
 
// Port A
always @(posedge a_clk) begin
    a_dout      <= mem[a_addr];
    if(a_wr) begin
        a_dout      <= a_din;
        mem[a_addr] <= a_din;
    end
end
 
// Port B
always @(posedge b_clk) begin
    b_dout      <= mem[b_addr];
    if(b_wr) begin
        b_dout      <= b_din;
        mem[b_addr] <= b_din;
    end
end
 
endmodule

// A 8Kbyte RAM (4096x16) with two ports:
//   port a, 16 bits read/write 
//   port b, 16 bits read-only, lower 16K only

module ram16k(
  input wire        clk,

  input  wire[15:0] a_addr,
  output wire[15:0] a_q,
  input  wire[15:0] a_d,
  input  wire       a_wr,

  input  wire[12:0] b_addr,
  output wire[15:0] b_q);

  wire [15:0] insn16;

  bram_tdp #(.DATA(16), .ADDR(12)) nram (
    .a_clk(clk),
    .a_wr(a_wr),
    .a_addr(a_addr[11:0]),
    .a_din(a_d),
    .a_dout(a_q),

    .b_clk(clk),
    .b_wr(1'b0),
    .b_addr(b_addr[11:0]),
    .b_din(16'd0),
    .b_dout(insn16));

  assign b_q = insn16[15:0];

endmodule


module top(
  input wire CLK,
  input  wire DUO_SW1,
  input  wire RXD,
  output wire TXD,
  input  wire DTR
  );

  localparam MHZ = 50;

  reg  DUO_LED;
  wire fclk;

  DCM_CLKGEN #(
  .CLKFX_MD_MAX(0.0),     // Specify maximum M/D ratio for timing anlysis
  // .CLKFX_DIVIDE(32),      // Divide value - D - (1-256)
  // .CLKFX_MULTIPLY(MHZ),   // Multiply value - M - (2-256)

  // .CLKFX_DIVIDE(15),      // Divide value - D - (1-256)
  // .CLKFX_MULTIPLY(59),   // Multiply value - M - (2-256)
  .CLKFX_DIVIDE(100),      // Divide value - D - (1-256)
  .CLKFX_MULTIPLY(MHZ),   // Multiply value - M - (2-256)

  // .CLKIN_PERIOD(31.25),   // Input clock period specified in nS
  .CLKIN_PERIOD(10),   // Input clock period specified in nS
  .STARTUP_WAIT("FALSE")  // Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
  )
  DCM_CLKGEN_inst (
  .CLKFX(fclk),           // 1-bit output: Generated clock output
  .CLKIN(CLK),            // 1-bit input: Input clock
  .FREEZEDCM(0),          // 1-bit input: Prevents frequency adjustments to input clock
  .PROGCLK(0),            // 1-bit input: Clock input for M/D reconfiguration
  .PROGDATA(0),           // 1-bit input: Serial data input for M/D reconfiguration
  .PROGEN(0),             // 1-bit input: Active high program enable
  .RST(0)                 // 1-bit input: Reset input pin
  );

  reg [63:0] counter;
  always @(posedge fclk)
    counter <= counter + 64'd1;

  reg [31:0] ms;
  reg [17:0] subms;
  localparam [17:0] lim = (MHZ * 1000) - 1;
  always @(posedge fclk) begin
    subms <= (subms == lim) ? 18'd0 : (subms + 18'd1);
    if (subms == lim)
      ms <= ms + 32'd1;
  end

  // ------------------------------------------------------------------------

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_rd, uart0_wr;
  // XXX reg [31:0] uart_baud = 32'd921600;
  reg [31:0] uart_baud = 32'd115200;
  wire UART0_RX;
  buart #(.CLKFREQ(MHZ * 1000000)) _uart0 (
     .clk(fclk),
     .resetq(resetq),
     .baud(uart_baud),
     .rx(RXD),
     .tx(TXD),
     .rd(uart0_rd),
     .wr(uart0_wr),
     .valid(uart0_valid),
     .busy(uart0_busy),
     .tx_data(dout_[7:0]),
     .rx_data(uart0_data));

  wire [15:0] mem_addr;
  wire [15:0] mem_din;
  wire mem_wr;
  wire [15:0] dout;
  reg  [15:0] din;

  wire [12:0] code_addr;
  wire [15:0] insn;

  wire io_rd, io_wr;

  wire resetq = DTR;

  j1 _j1 (
     .clk(fclk),
     .resetq(resetq),
     .io_rd(io_rd),
     .io_wr(io_wr),
     .mem_wr(mem_wr),
     .dout(dout),
     .io_din(din),
     .mem_addr(mem_addr),
     // XXX .mem_din(mem_din),
     .code_addr(code_addr),
     .insn(insn)
     );

  ram16k ram(
	  		.clk(fclk),
	  		// write port 
			// FIXME (brandon) : The write port
			// should be byte addressible but it
			// is 16-bits word.  Currently dividing the byte
			// address by two to get the word address.
			// Should change port A to be byte addressable.
             .a_addr({1'b0,mem_addr[14:1]}),
             .a_q(mem_din),
             .a_wr(mem_wr),
             .a_d(dout),
			// read port
             .b_addr(code_addr),
             .b_q(insn));

  reg io_wr_, io_rd_;
  reg [15:0] mem_addr_;
  reg [15:0] dout_;
  always @(posedge fclk)
    {io_wr_, io_rd_, mem_addr_, dout_} <= {io_wr, io_rd, mem_addr, dout};

  /*      READ            WRITE
    00xx  GPIO rd         GPIO wr
    01xx                  GPIO direction

    1008  baudrate        baudrate
    1000  UART RX         UART TX
    2000  UART status 

    1010  master freq     snapshot clock
    1014  clock[31:0]
    1018  clock[63:32]
    101c  millisecond uptime

  */

  reg [63:0] counter_;


  always @(posedge fclk) begin
    casez (mem_addr)

    16'h1008: din <= uart_baud;
    16'h1000: din <= {24'd0, uart0_data};
    16'h2000: din <= {30'd0, uart0_valid, !uart0_busy};

    16'h1010: din <= MHZ * 1000000;
    16'h1014: din <= counter_[15:0];
    16'h1018: din <= counter_[31:16];
    16'h101c: din <= ms;

    default:  din <= 16'bx;
    endcase

    if (io_wr_) begin
      casez (mem_addr_)

        16'h1008: uart_baud <= dout_;

        16'h1010: counter_ <= counter;

      endcase
    end
  end

  assign uart0_wr = io_wr_ & (mem_addr_ == 16'h1000);
  assign uart0_rd = io_rd_ & (mem_addr_ == 16'h1000);


endmodule
