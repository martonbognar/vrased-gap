`include "X_stack.v"
`include "AC.v"
`include "atomicity.v"
`include "dma_AC.v"
`include "dma_detect.v"
`include "dma_X_stack.v"

`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif


module vrased (
    clk,
    pc,
    data_en,
    data_wr,
    data_addr,

    // DMA
    dma_addr,
    dma_en,

    irq,

    reset
);


/* unused, added for compatibility */
input           clk;
input           irq;

input   [15:0]  pc;
input           data_en;
input           data_wr;
input   [15:0]  data_addr;
input   [15:0]  dma_addr;
input           dma_en;
output          reset;

// MACROS ///////////////////////////////////////////
parameter SDATA_BASE = 16'h400;
parameter SDATA_SIZE = 16'hC00;
//
parameter HMAC_BASE = 16'h0230;
parameter HMAC_SIZE = 16'h0020;
//
parameter SMEM_BASE = `SMEM_BASE;
parameter SMEM_SIZE = `SMEM_SIZE;
//
parameter KMEM_BASE = `SKEY_BASE;
parameter KMEM_SIZE = `SKEY_SIZE;
//
/* NOTE: the original CTR_BASE value 0x9000 falls out of the RAM range. We
 * changed this here to the address used by RATA
 * (https://github.com/sprout-uci/RATA/blob/main/vrased/sw-att/wrapper.c#L3).
 */
parameter CTR_BASE = 16'h0270;
parameter CTR_SIZE = 16'h001F;
/////////////////////////////////////////////////////

parameter RESET_HANDLER = 16'h0000;

wire    X_stack_reset;
X_stack #(
    .SDATA_BASE (SDATA_BASE),
    .SDATA_SIZE (SDATA_SIZE),
    .HMAC_BASE  (HMAC_BASE),
    .HMAC_SIZE  (HMAC_SIZE),
    .SMEM_BASE  (SMEM_BASE),
    .SMEM_SIZE  (SMEM_SIZE),
    .KMEM_BASE  (KMEM_BASE),
    .KMEM_SIZE  (KMEM_SIZE),
    .CTR_BASE  (CTR_BASE),
    .CTR_SIZE  (CTR_SIZE),
    .RESET_HANDLER  (RESET_HANDLER)
) X_stack_0 (
    .pc         (pc),
    .data_addr  (data_addr),
    .data_en       (data_en),
    .data_wr       (data_wr),
    .reset      (X_stack_reset)
);

wire    AC_reset;
AC #(
    .SMEM_BASE  (SMEM_BASE),
    .SMEM_SIZE  (SMEM_SIZE),
    .KMEM_BASE  (KMEM_BASE),
    .KMEM_SIZE  (KMEM_SIZE),
    .RESET_HANDLER  (RESET_HANDLER)
) AC_0 (
    .pc         (pc),
    .data_addr  (data_addr),
    .data_en    (data_en),
    .reset      (AC_reset)
);

wire    atomicity_reset;
atomicity #(
    .SMEM_BASE  (SMEM_BASE),
    .SMEM_SIZE  (SMEM_SIZE),
    .RESET_HANDLER  (RESET_HANDLER)
) atomicity_0 (
    .pc         (pc),
    .reset      (atomicity_reset)
);

wire    dma_AC_reset;
dma_AC #(
    .KMEM_BASE  (KMEM_BASE),
    .KMEM_SIZE  (KMEM_SIZE),
    .RESET_HANDLER  (RESET_HANDLER)
) dma_AC_0 (
    .pc         (pc),
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),
    .reset      (dma_AC_reset)
);

wire   dma_detect_reset;
dma_detect #(
    .SMEM_BASE  (SMEM_BASE),
    .SMEM_SIZE  (SMEM_SIZE),
    .RESET_HANDLER  (RESET_HANDLER)
) dma_write_detect_0 (
    .pc         (pc),
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),
    .reset      (dma_detect_reset)
);

wire   dma_X_stack_reset;
dma_X_stack #(
    .SDATA_BASE  (SDATA_BASE),
    .SDATA_SIZE  (SDATA_SIZE),
    .CTR_BASE  (CTR_BASE),
    .CTR_SIZE  (CTR_SIZE),
    .RESET_HANDLER  (RESET_HANDLER)
) dma_X_stack_0 (
    .pc         (pc),
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),
    .reset      (dma_X_stack_reset)
);

/**
 * NOTE: added explicit clocking to avoid reset glitches in C-2-stack-pointer
 * simulation (this was also done by the original VRASED authors in
 * ../hw-mod/).
 */
reg vrased_res;
always @(posedge clk)
    vrased_res <= X_stack_reset | AC_reset | atomicity_reset | dma_AC_reset | dma_detect_reset | dma_X_stack_reset;

assign reset = vrased_res;

endmodule
