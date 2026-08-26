// DOES NOT COMPILE, ON PURPOSE.
// Two `assign` statements aimed at the same output. In software the second
// line would win. In hardware both are wires, and they are both soldered on.
//   iverilog -g2012 -o /dev/null errors/two_drivers.sv
module two_drivers (
    input  logic a, b, cin,
    output logic sum, cout
);
    assign sum  = a ^ b;
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
