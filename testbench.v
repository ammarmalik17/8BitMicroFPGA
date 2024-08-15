module testbench;
// Inputs
reg clk;
reg rst;

// Instantiate the Unit Under Test (UUT)
Project uut (
    .clk(clk), 
    .rst(rst)
);

initial begin
    // Initialize Inputs
    rst = 1;
    // Wait 100 ns for global reset to finish
    #100;
    rst = 0;
end

initial begin 
    clk = 0;
    forever #10 clk = ~clk;
end

endmodule
