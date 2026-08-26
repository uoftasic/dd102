// 07_instantiation.sv — putting a module inside another module.
//
// Three pieces: the module's name, YOUR name for this copy of it, and the
// wiring. `.a(x)` means "the port called a, wired to my signal called x".
// A module is a box you wire up. It is not a function you call.
//   iverilog -g2012 -o 07.vvp src/07_instantiation.sv && vvp 07.vvp
module half_adder (
    input  logic a,
    input  logic b,
    output logic sum,
    output logic carry
);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

module two_halves (
    input  logic a, b, cin,
    output logic sum, cout
);
    logic s1, c1, c2;
    half_adder ha1 (.a(a),  .b(b),   .sum(s1),  .carry(c1));   // ha1 is my name for it
    half_adder ha2 (.a(s1), .b(cin), .sum(sum), .carry(c2));   // ha2 is a second copy
    assign cout = c1 | c2;
endmodule

module card07;
    logic a, b, cin, sum, cout;
    two_halves dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
    initial begin
        a = 1'b1; b = 1'b1; cin = 1'b1; #1;
        $display("07_instantiation: 1+1+1 -> cout=%b sum=%b (= %0d)", cout, sum, {cout, sum});
    end
endmodule
