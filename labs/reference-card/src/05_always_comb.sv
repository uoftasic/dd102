// 05_always_comb.sv — `always_comb` for logic that is easier to say in words.
//
// Same hardware as `assign`. Different spelling. Inside always_comb you use
// `=`, you may use `if`/`else`, and you must assign every output on every path.
//   iverilog -g2012 -o 05.vvp src/05_always_comb.sv && vvp 05.vvp
module chooser (
    input  logic       sel,
    input  logic [3:0] x,
    input  logic [3:0] y,
    output logic [3:0] out
);
    always_comb begin
        if (sel) out = x;
        else     out = y;      // the `else` is not optional. See card 05 on the page.
    end
endmodule

module card05;
    logic sel;
    logic [3:0] x, y, out;
    chooser dut (.sel(sel), .x(x), .y(y), .out(out));
    initial begin
        x = 4'd9; y = 4'd4;
        sel = 1'b1; #1; $write("05_always_comb: sel=1 -> %0d", out);
        sel = 1'b0; #1; $display("   sel=0 -> %0d", out);
    end
endmodule
