// mutants/mut1_cin_ignored.sv  --  a full adder with one thing wrong.
//
// cout is right. sum forgot that cin exists.
//
// This is a complete, compilable file and it is a broken one on purpose. It
// declares `module full_adder`, exactly like the real one, so your testbench
// binds to it without changing a character.

module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);

    assign sum  = a ^ b;                              // <-- cin dropped
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule
