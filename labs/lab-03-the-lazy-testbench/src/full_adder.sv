// reference/full_adder.sv  --  one complete, working answer.
//
// This is not "the" answer. It is one of infinitely many circuits that fill in
// the same eight rows -- which is exactly what you proved to yourself in DD101
// Lab 04 with Combinational Analysis. If your src/full_adder.sv passes and does
// not look like this, you are not wrong. You are different.
//
// `make` runs this file through the same printer and the same grader as yours,
// so a PASS here proves your toolchain works even when your own file does not.

module full_adder (
    input  logic a,
    input  logic b,
    input  logic cin,
    output logic sum,
    output logic cout
);

    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule
