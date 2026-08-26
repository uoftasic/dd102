// DOES NOT COMPILE, ON PURPOSE.
// `assign` takes an expression, not a statement. An `if` is a statement.
// One mistake on line 8; five error messages. Read the first one.
//   iverilog -g2012 -o /dev/null errors/if_inside_assign.sv
module if_inside_assign (
    input  logic a, b, cin,
    output logic sum, cout
);
    assign sum = if (cin) a ^ b; else a & b;
    assign cout = 1'b0;
endmodule
