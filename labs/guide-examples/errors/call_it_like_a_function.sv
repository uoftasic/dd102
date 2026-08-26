// DOES NOT COMPILE, ON PURPOSE.
// A module is a box you wire up, not a function you call. This file calls it.
//   iverilog -g2012 -o /dev/null errors/call_it_like_a_function.sv src/full_adder.sv
module call_it_like_a_function (
    input  logic a, b, cin,
    output logic sum, cout
);
    assign sum  = full_adder(a, b, cin);
    assign cout = 1'b0;
endmodule
