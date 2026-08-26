// 02_logic_and_vectors.sv — `logic`, and `logic [3:0]` when one bit is not enough.
//
// `logic` is the only type DD102 asks you for. It is a wire when you drive it
// with `assign`, and it is whatever else it needs to be when you don't.
// Internal wires — the ones with names on your drawing but no port — are
// declared inside the module, before you use them.
//   iverilog -g2012 -o 02.vvp src/02_logic_and_vectors.sv && vvp 02.vvp
module widths (
    input  logic [3:0] a,
    output logic [3:0] y,
    output logic       msb
);
    logic [3:0] flipped;      // an internal wire. No direction: it is not a port.
    assign flipped = ~a;
    assign y   = flipped;
    assign msb = a[3];        // one bit out of the bus
endmodule

module card02;
    logic [3:0] a, y;
    logic msb;
    widths dut (.a(a), .y(y), .msb(msb));
    initial begin
        a = 4'b1001; #1;
        $display("02_logic_and_vectors: a=%b y=%b a[3]=%b a[2:1]=%b", a, y, msb, a[2:1]);
    end
endmodule
