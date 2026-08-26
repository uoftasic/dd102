// 03_assign_and_operators.sv — `assign`, and the five operators DD102 uses.
//
// `assign` is a soldered connection, not a step in a program. The left side
// is whatever the right side is, always, at the same time as everything else.
//   iverilog -g2012 -o 03.vvp src/03_assign_and_operators.sv && vvp 03.vvp
module ops (
    input  logic a,
    input  logic b,
    output logic o_and, o_or, o_xor, o_not
);
    assign o_and = a & b;      // And
    assign o_or  = a | b;      // Or
    assign o_xor = a ^ b;      // Xor
    assign o_not = ~a;         // Not
endmodule

module card03;
    logic a, b, o_and, o_or, o_xor, o_not;
    ops dut (.a(a), .b(b), .o_and(o_and), .o_or(o_or), .o_xor(o_xor), .o_not(o_not));
    initial begin
        a = 1'b1; b = 1'b0; #1;
        $display("03_assign_and_operators: a=%b b=%b and=%b or=%b xor=%b not_a=%b",
                 a, b, o_and, o_or, o_xor, o_not);
    end
endmodule
