// toobig.sv — a 16 x 16 multiplier. It has 64 pins. The chip has 39.
module toobig (
    input  logic [15:0] a,
    input  logic [15:0] b,
    output logic [31:0] p
);
    assign p = a * b;
endmodule
