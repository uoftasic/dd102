// 05_wrong_port_name.sv — BROKEN ON PURPOSE.
// half_adder's carry port is called `carry`. This says `cout`.
module half_adder (input logic a, input logic b, output logic sum, output logic carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

module wrong_port_name (input logic a, input logic b, output logic s, output logic c);
    half_adder ha (.a(a), .b(b), .sum(s), .cout(c));
endmodule
