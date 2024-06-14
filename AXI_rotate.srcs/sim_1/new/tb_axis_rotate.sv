`timescale 1ns / 1ps

module tb_axis_rotate();

    // Parameters
    localparam DATA_WIDTH = 32;
    localparam USER_WIDTH = 8;
    localparam ADDR_WIDTH = 10;
    localparam BURST_WIDTH = 2;
    localparam TRANSFER_WIDTH = 8;
    localparam SIZE_WIDTH = 3;

    // Signals
    reg aclk;
    reg aresetn;

    // Slave AXI write signals
    reg [ADDR_WIDTH-1:0] s_axi_awaddr;
    reg [DATA_WIDTH-1:0] s_axi_wdata;
    reg [USER_WIDTH-1:0] s_axi_tuser;
    reg [BURST_WIDTH-1:0] s_axi_awburst;
    reg [TRANSFER_WIDTH-1:0] s_axi_awlen;
    reg [SIZE_WIDTH-1:0] s_axi_awsize;
    reg s_axi_awvalid;
    wire s_axi_awready;
    wire s_axi_awlast;

    // Slave AXI read signals
    reg [ADDR_WIDTH-1:0] s_axi_araddr;
    reg [BURST_WIDTH-1:0] s_axi_arburst;
    reg [TRANSFER_WIDTH-1:0] s_axi_arlen;
    reg [SIZE_WIDTH-1:0] s_axi_arsize;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire s_axi_arlast;
    wire [DATA_WIDTH-1:0] s_axi_rdata;

    // Master AXI signals
    wire m_axi_tvalid;
    wire [DATA_WIDTH-1:0] m_axi_tdata;
    reg m_axi_tready;

    // Instantiate the module
    axis_rotate #(
        .DATA_WIDTH(DATA_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BURST_WIDTH(BURST_WIDTH),
        .TRANSFER_WIDTH(TRANSFER_WIDTH),
        .SIZE_WIDTH(SIZE_WIDTH)
    ) uut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_tuser(s_axi_tuser),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_awlast(s_axi_awlast),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_arlast(s_axi_arlast),
        .s_axi_rdata(s_axi_rdata),
        .m_axi_tvalid(m_axi_tvalid),
        .m_axi_tdata(m_axi_tdata),
        .m_axi_tready(m_axi_tready)
    );

    // Clock generation
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // 100 MHz Clock
    end

    // Reset generation
    initial begin
        aresetn = 0;
        #100;
        aresetn = 1;
    end

    // Test scenarios
    initial begin
        // Initialize all signals
        s_axi_awaddr = 0;
        s_axi_wdata = 0;
        s_axi_tuser = 0;
        s_axi_awburst = 0;
        s_axi_awlen = 0;
        s_axi_awsize = 0;
        s_axi_awvalid = 0;
        s_axi_araddr = 0;
        s_axi_arburst = 0;
        s_axi_arlen = 0;
        s_axi_arsize = 0;
        s_axi_arvalid = 0;
        m_axi_tready = 1;

        // Wait for reset deassertion
        wait(aresetn);
        // Wait for a posedge of clock
        @(posedge aclk);

        // Start a write transaction
        s_axi_awaddr = 10'h2EF;
        s_axi_wdata = 32'h12345678;
        s_axi_tuser = 8'b10000001; // Rotate right
        s_axi_awvalid = 1;
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
        s_axi_awvalid = 0;
        
        
        s_axi_awaddr = 10'h2F0;
        s_axi_wdata = 32'h12345678;
        s_axi_tuser = 8'b00000001; // Rotate left
        s_axi_awvalid = 1;
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
        s_axi_awvalid = 0;

        // Start a read transaction
        s_axi_araddr = 10'h2EF;
        s_axi_arvalid = 1;
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
        s_axi_arvalid = 0;
        
        s_axi_araddr = 10'h2F0;
        s_axi_arvalid = 1;
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
        s_axi_arvalid = 0;


        // Additional test cases can be added here
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
        @(posedge aclk);
        $finish;
    end

    // Capture output response
    always @(posedge aclk) begin
        if (s_axi_arvalid || s_axi_awvalid || !s_axi_arvalid || !s_axi_awvalid) begin
            $display("Time: %t, Output Data: %h", $time, m_axi_tdata);
        end
    end

endmodule
