// 12_testbench_only.sv — the five things that only exist in a testbench.
//
// `timescale, initial, $display, $dumpfile/$dumpvars, $finish. None of these
// become hardware. They are how the second circuit — the one whose whole job
// is doubt — drives inputs, writes a waveform, and reports.
//   iverilog -g2012 -o 12.vvp src/12_testbench_only.sv && vvp 12.vvp
`timescale 1ns/1ps

module inverter (input logic a, output logic y);
    assign y = ~a;
endmodule

module card12;
    logic a, y;
    inverter dut (.a(a), .y(y));

    initial begin
        $timeformat(-9, 0, " ns", 6);   // print times in ns, not in ps
        $dumpfile("card12.vcd");     // the file the waveform goes into
        $dumpvars(0, card12);        // 0 = this module and everything under it
        a = 1'b0;
        #10 a = 1'b1;
        #10;
        $display("12_testbench_only: at %0t, a=%b y=%b", $time, a, y);
        $finish;                     // without this, vvp can sit there forever
    end
endmodule
