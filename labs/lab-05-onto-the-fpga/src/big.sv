// big.sv — a 4000-stage shift register. Three pins, an enormous amount of logic.
// It is here to be large, and to fit.
module big (
    input  logic clk,
    input  logic d,
    output logic q
);
    logic [3999:0] sr;
    always_ff @(posedge clk) sr <= {sr[3998:0], d};
    assign q = sr[3999];
endmodule
