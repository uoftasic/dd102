// lut_simple.sv — a four-input AND. The simplest function of four inputs.
// Printed in the guide as an excerpt; this is the whole file.
//   yosys -p "read_verilog -sv src/lut_simple.sv; synth_ice40 -top lut_simple; stat"
module lut_simple (
    input  logic a, b, c, d,
    output logic y
);
    assign y = a & b & c & d;
endmodule
