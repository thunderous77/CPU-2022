`include "riscv\src\defines.v"

module LS_EX (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from & to ls
    input enable_sign_from_ls,
    input wire [`OPNUM_TYPE] opnum_from_ls,
    input wire [`ADDR_TYPE] address_from_ls,
    input wire [`DATA_TYPE] store_data_from_ls,
    output wire full_sign_to_ls,

    // to Memctrl
    input wire finish_sign_from_memctrl,
    input wire [`DATA_TYPE] load_data_from_memctrl,    
    output reg enable_sign_to_memctrl,
    output reg [`ADDR_TYPE] address_to_memctrl,
    output reg [`DATA_TYPE] store_data_to_memctrl,
    output reg [2:0] size_to_memctrl,
    output reg load_store_sign_to_memctrl,

    // from rob
    input wire rollback_sign_from_rob,

    // global output
    output reg valid_sign,
    output reg [`DATA_TYPE] data
);

endmodule