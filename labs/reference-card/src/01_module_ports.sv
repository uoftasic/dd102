// 01_module_ports.sv — module, endmodule, and an ANSI port list.
//
// A module is a box with labelled edges. The port list IS the labels on the
// edge of your DD101 drawing, typed out. Direction first, then type, then name.
//   iverilog -g2012 -o 01.vvp src/01_module_ports.sv && vvp 01.vvp
module gate_box (
    input  logic a,
    input  logic b,        // one port per line reads best while you are learning
    output logic y
);
    assign y = a & b;
endmodule

module card01;
    logic a, b, y;
    gate_box dut (.a(a), .b(b), .y(y));
    initial begin
        a = 1'b1; b = 1'b1; #1;
        $display("01_module_ports: a=%b b=%b y=%b", a, b, y);
    end
endmodule
