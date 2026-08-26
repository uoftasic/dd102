// tb_sweep8.sv — every input of the 8-bit adder. All 131,072 of them.
//
// 256 values of a, times 256 values of b, times 2 values of cin. Same idea as
// tb_sweep.sv, four bits wider, and 256 times as many vectors.
//
// It does NOT dump a waveform. A VCD of 131,072 vectors is tens of megabytes
// and no human is going to scroll it.

`timescale 1ns/1ps

module tb_sweep8;

    logic [7:0] a, b;
    logic       cin;
    logic [7:0] sum;
    logic       cout;
    logic [8:0] expected;

    int checked = 0;
    int errors  = 0;

    ripple8 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    initial begin
        $display("tb_sweep8: all 131072 inputs of ripple8");

        for (int i = 0; i < 131072; i = i + 1) begin
            {a, b, cin} = i[16:0];
            #10;
            expected = a + b + cin;
            checked  = checked + 1;
            if ({cout, sum} !== expected) errors = errors + 1;
            #10;
        end

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end
endmodule
