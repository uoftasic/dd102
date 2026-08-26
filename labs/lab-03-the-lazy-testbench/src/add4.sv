// src/add4.sv  --  a 4-bit adder, built the way you would draw it.
//
// Four full adders in a row. The carry out of each one is the carry in of the
// next. This is a complete, compilable, working file: every gate in it does
// exactly what it should, and nothing here is a typo.
//
// It is also wrong, and Lab 03 is about finding out how.

module add4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic       cin,
    output logic [3:0] sum
);

    logic c1, c2, c3, c4;      // the carries that run between the four adders

    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c1));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(c1),  .sum(sum[1]), .cout(c2));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(c2),  .sum(sum[2]), .cout(c3));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(c3),  .sum(sum[3]), .cout(c4));

endmodule
