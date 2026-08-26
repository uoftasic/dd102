// broken/narrow_only.sv — card 11's mistake on its own, with nothing to
// compare it against. This is what the bug looks like in real code: a 4-bit
// answer to a question that needs five bits, and not one tool complains.
//
// Run by `make lint`. Both tools exit 0 and print nothing.
module narrow_only (
    input  logic [3:0] a,
    input  logic [3:0] b,
    output logic [3:0] sum
);
    assign sum = a + b;
endmodule
