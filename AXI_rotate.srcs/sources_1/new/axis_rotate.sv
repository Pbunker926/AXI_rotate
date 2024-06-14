module axis_rotate #(
    parameter DATA_WIDTH = 32,    // Width of the data bus
    parameter USER_WIDTH = 8,     // Width of the tuser signal
    parameter ADDR_WIDTH = 10,     // Address width for Block RAM
    parameter BURST_WIDTH = 2,     // Burst width for selecting burst type
    parameter TRANSFER_WIDTH = 8, // Width of the number of beats(transfers) per burst
    parameter SIZE_WIDTH = 3  	  // Width used to determine the size of a single transfer (number of bytes per transfer)
)(
    input wire aclk,              // Clock input
    input wire aresetn,           // Active low reset
	
	// Slave AXI write signals
    input wire [ADDR_WIDTH-1:0] s_axi_awaddr, // Address input for write
    input wire [DATA_WIDTH-1:0] s_axi_wdata, // Slave write data bus
    input wire [USER_WIDTH-1:0] s_axi_tuser, // Slave user signal
    input wire [BURST_WIDTH-1:0] s_axi_awburst, // Slave write burst mode
    input wire [TRANSFER_WIDTH-1:0] s_axi_awlen, // Slave write burst mode
    input wire [SIZE_WIDTH-1:0] s_axi_awsize, // Slave write burst mode
    input wire s_axi_awvalid,       		 // Slave write valid signal
    output reg s_axi_awready,       		 // Slave write ready signal
    output reg s_axi_awlast,       			 // Slave write last transfer signal
	
	// Slave AXI read signals
    input wire [ADDR_WIDTH-1:0] s_axi_araddr, // Address input for read
    output reg [DATA_WIDTH-1:0] s_axi_rdata, // Slave read data bus 
    input wire [BURST_WIDTH-1:0] s_axi_arburst, // Slave read burst mode
    input wire [TRANSFER_WIDTH-1:0] s_axi_arlen, // Slave read burst mode
    input wire [SIZE_WIDTH-1:0] s_axi_arsize, // Slave read burst mode 
    input wire s_axi_arvalid,     			 // Slave read valid signal
    output reg s_axi_arready,     			 // Slave read ready signal
    output reg s_axi_arlast,       			 // Slave read last transfer signal
			
    output reg m_axi_tvalid,     // Master valid signal
    output reg [DATA_WIDTH-1:0] m_axi_tdata, // Master data bus
    input wire m_axi_tready     // Master ready signal
);

// Internal signals for Block RAM
wire [DATA_WIDTH-1:0] doutb;     // Data output from Block RAM
reg [DATA_WIDTH-1:0] dina;       // Data input to Block RAM
reg [DATA_WIDTH-1:0] d_buff;       // Data Buffer to hold the input data
reg ena, enb;                    // Enable signals for Block RAM
reg wea;                         // Write enable for Block RAM

// Internal signals 
reg rotate_right;                  // Direction of rotation
int num_positions;                 // Calculate the number of positions to rotate

// Assign statements
assign m_axi_tdata = doutb; // Update Master data bus and Slave read data bus
assign s_axi_rdata = doutb; // Update Master data bus and Slave read data bus

// Instantiate Block RAM
Block_Ram internal_mem (
    .clka(aclk),      // Use the same clock for the entire module
    .ena(ena),        // Enable signal for port A
    .wea(wea),        // Write enable for port A
    .addra(s_axi_awaddr),    // Address for writing
    .dina(dina),      // Data input for port A
    .clkb(aclk),      // Use the same clock for the entire module
    .enb(s_axi_arvalid & s_axi_arready),        // Enable signal for port B
    .addrb(s_axi_araddr),    // Address for reading
    .doutb(doutb)     // Data output from port B
);

always @(posedge aclk) begin
    if (!aresetn) begin
        m_axi_tvalid <= 1'b0; 
        ena <= 0;
        enb <= 0;
        wea <= 0;
        rotate_right <= 0;
        s_axi_awready <= 0;
        s_axi_arready <= 0;
        d_buff <= 0;
		dina <= 0; 
    end else begin
        // Specify that the slave is ready to accept data for both read and write
        s_axi_awready <= 1;
        s_axi_arready <= 1;
        // Load data into the buffer and determine rotation direction
        if (s_axi_awvalid && s_axi_awready) begin
            d_buff <= s_axi_wdata;
            rotate_right <= s_axi_tuser[USER_WIDTH-1];  // Use MSB of tuser to determine direction
            ena <= 1'b1;  // Enable writing to Block RAM
            wea <= 1'b1;  // Enable write operation
            
            // Calculate the number of positions to rotate based on the last 2 bits of tuser
            num_positions <= s_axi_tuser[1:0] * 8; // Each unit represents 8 bits or 1 byte
            if (rotate_right) begin
                dina <= (d_buff >> num_positions) | (d_buff << (DATA_WIDTH - num_positions));
            end
            else begin
                dina <= (d_buff << num_positions) | (d_buff >> (DATA_WIDTH - num_positions));
            end
        end 
        else begin
            ena <= 1'b0;
            wea <= 1'b0;
        end 
    end
end

endmodule
