`include "riscv\src\defines.v"

module MemCtrl (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from & to ram
    input wire [`MEMDATA_TYPE] data_from_ram,
    output reg [`MEMDATA_TYPE] data_to_ram,
    output reg[`ADDR_TYPE] addr_to_ram,
    output reg read_write_sign_to_ram,
    
    // from & to fetcher
    input wire [`ADDR_TYPE] pc_from_fch,
    input wire start_sign_from_fch,
    output reg finish_sign_to_fch,
    output reg [`INST_TYPE] inst_to_fch,

    // from & to LSU
    // TODO
    input wire [`DATA_TYPE] store_data_from_LSU,
    input wire [`ADDR_TYPE] addr_from_LSU,
    input wire start_sign_from_LSU,
    input wire read_write_sign_from_LSU,
    output reg finish_sign_to_LSU,
    output reg[`DATA_TYPE] load_data_to_LSU
);

    // memctrl status
    parameter 
    IDLE = 0, FETCH = 1, LOAD = 2, STORE = 3;
    reg [`STATUS_TYPE] status;

    // data
    reg [`ADDR_TYPE] ram_access_pc;
    reg [`DATA_TYPE] writing_data;
    reg [`INT_TYPE] ram_current_access, ram_access_end;

    always @(posedge clk) begin
        if (rst) begin
            status <= IDLE;

        end
        else if (!rdy) begin
        end
        else begin
            if (status == FETCH) begin
                // fetch
                addr_to_ram <= ram_access_pc;
                read_write_sign_to_ram <= `RAM_READ;
                case (ram_current_access)
                    32'h1 : inst_to_fch[7:0] <= data_from_ram;
                    32'h2 : inst_to_fch[15:8] <= data_from_ram;
                    32'h3 : inst_to_fch[23:16] <= data_from_ram;
                    32'h4 : inst_to_fch[31:24] <= data_from_ram;
                endcase
                ram_access_pc <= (ram_current_access >= ram_access_end - `RAM_PC_BIT) ? `NULL : ram_access_pc + `RAM_PC_BIT;
                // stop
                if (ram_current_access == ram_access_end) begin
                    status <= IDLE;
                    ram_access_pc <= `NULL;
                    ram_current_access <= `NULL;
                end
                else begin
                    ram_current_access <= ram_current_access + `RAM_PC_BIT;
                end
            end
            else if (status == LOAD) begin
                // load
                addr_to_ram <= ram_access_pc;
                read_write_sign_to_ram <= `RAM_READ;
                case (ram_current_access)
                    32'h1 : load_data_to_LSU[7:0] <= data_from_ram;
                    32'h2 : load_data_to_LSU[15:8] <= data_from_ram;
                    32'h3 : load_data_to_LSU[23:16] <= data_from_ram;
                    32'h4 : load_data_to_LSU[31:24] <= data_from_ram;
                endcase
                ram_access_pc <= (ram_current_access >= ram_access_end - `RAM_PC_BIT) ? `NULL : ram_access_pc + `RAM_PC_BIT;
                // stop
                if (ram_current_access == ram_access_end) begin
                    status <= IDLE;
                    ram_access_pc <= `NULL;
                    ram_current_access <= `NULL;
                end
                else begin
                    ram_current_access <= ram_current_access + `RAM_PC_BIT;
                end
            end
            else if (status == STORE) begin
                // store
                addr_to_ram <= ram_access_pc;
                read_write_sign_to_ram <= `RAM_WRITE;
                case (ram_current_access)
                    32'h1 : data_to_ram <= store_data_from_LSU[7:0];
                    32'h2 : data_to_ram <= store_data_from_LSU[15:8];
                    32'h3 : data_to_ram <= store_data_from_LSU[23:16];
                    32'h4 : data_to_ram <= store_data_from_LSU[31:24];
                endcase
                ram_access_pc <= (ram_current_access >= ram_access_end - `RAM_PC_BIT) ? `NULL : ram_access_pc + `RAM_PC_BIT;
                // stop
                if (ram_current_access == ram_access_end) begin
                    status <= IDLE;
                    ram_access_pc <= `NULL;
                    ram_current_access <= `NULL;
                    addr_to_ram <= `NULL;
                    read_write_sign_to_ram <= `RAM_READ;
                end
                else begin
                    ram_current_access <= ram_current_access + `RAM_PC_BIT;
                end
            end
        end
    end

endmodule