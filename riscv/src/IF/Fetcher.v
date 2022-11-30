`include "riscv\src\defines.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,


    // to commmander
    output reg [`ADDR_TYPE] pc_to_cmd,
    output reg [`ADDR_TYPE] rollback_pc_to_cmd,
    output reg predicted_jump_sign_to_cmd,
    output reg finish_sign_to_cmd,
    output reg [`INST_TYPE] inst_to_cmd,

    // from & to predictor
    input wire [`ADDR_TYPE] predicted_pc_from_pdt,
    input wire predicted_jump_sign_from_pdt,
    output wire [`ADDR_TYPE] pc_to_pdt,
    output wire [`INST_TYPE] inst_to_pdt,

    // from & to memctrl
    input wire finish_sign_from_memctrl,
    input wire [`ICACHE_INST_BLOCK_SIZE-1:0] inst_block_from_memctrl,
    output reg [`ADDR_TYPE] pc_to_memctrl,
    output reg enable_sign_to_memctrl,

    // from rob
    input wire rollback_sign_from_rob,
    input wire [`ADDR_TYPE] pc_from_rob,

    // from mutiple modules
    input wire full_sign
    
);

    // direct mapped icache
    reg valid [`ICACHE_SIZE-1:0];
    reg [`ICACHE_TAG_RANGE] tag_store[`ICACHE_SIZE-1:0];
    reg [`ICACHE_INST_BLOCK_SIZE-1:0] inst_block_in_cache[`ICACHE_SIZE-1:0];

    wire hit = valid[pc[`ICACHE_INDEX_RANGE]] && (tag_store[pc[`ICACHE_INDEX_RANGE]] == pc[`ICACHE_TAG_RANGE]);
    wire [`INST_TYPE] ret_inst = (hit) ? inst_block_in_cache[pc[`ICACHE_INDEX_RANGE]][pc[`ICACHE_OFFSET_RANGE]] : `NULL;

    // pc reg
    reg [`ADDR_TYPE] pc, mem_pc;

    // to predictor
    assign pc_to_pdt = pc;
    assign inst_to_pdt = ret_inst;

    // status--IDLE/FETCH
    parameter
    IDLE = 0, FETCH = 1;

    reg[`STATUS_TYPE] status;

    always @(posedge clk) begin
        if (rst) begin
            // pc initilize
            pc <= `NULL;
            mem_pc <= `NULL;
            // icache initilize
            for (integer i = 0; i < `ICACHE_SIZE; i = i + 1) begin
                valid[i] <= `FALSE;
                tag_store[i] <= `NULL;
                inst_block_in_cache[i] <= `NULL;
            end
            // output initialize
            pc_to_cmd <= `NULL;
            pc_to_memctrl <= `NULL;
            inst_to_cmd <= `NULL;
            finish_sign_to_cmd <= `FALSE;
            enable_sign_to_memctrl <= `FALSE;
            // status initialize
            status <= IDLE;
        end
        else if (!rdy) begin
        end
        else if (rollback_sign_from_rob) begin
            finish_sign_to_cmd <= `FALSE;
            pc <= pc_from_rob;
            mem_pc <= pc_from_rob;
            status <= IDLE;
            enable_sign_to_memctrl <= `FALSE;
        end
        else begin
            if (hit && full_sign == `FALSE) begin
                pc_to_cmd <= pc;
                predicted_jump_sign_to_cmd <= predicted_jump_sign_from_pdt;
                pc <= pc + (predicted_jump_sign_from_pdt ? predicted_pc_from_pdt : `PC_BIT);
                rollback_pc_to_cmd <= pc +`PC_BIT;
                inst_to_cmd <= ret_inst;
                finish_sign_to_cmd <= `TRUE;
            end
            else begin
                finish_sign_to_cmd <= `FALSE;
            end

            enable_sign_to_memctrl <= `FALSE;

            if (status == IDLE) begin
                enable_sign_to_memctrl <= `TRUE;
                // fetch instruction from xxx00, xxx01, xxx10, xxx11
                pc_to_memctrl <= mem_pc[`PC_TAG_AND_INDEX_RANGE] << 2;
                status <= FETCH;
            end
            else begin
                if (finish_sign_from_memctrl) begin
                    mem_pc <= ((mem_pc == pc) ? mem_pc + `PC_BIT : pc);
                    status <= FETCH;
                    valid[mem_pc[`ICACHE_INDEX_RANGE]] <= `TRUE;
                    tag_store[mem_pc[`ICACHE_INDEX_RANGE]] <= mem_pc[`ICACHE_TAG_RANGE];
                    inst_block_in_cache[mem_pc[`ICACHE_INDEX_RANGE]] <= inst_block_from_memctrl;            
                end
            end
        end
    end

endmodule