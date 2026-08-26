// tb_eight_rows_compact.sv — the SAME testbench as tb_eight_rows.sv, with the
// eight expected values written in the compact SystemVerilog form:
//
//     logic [1:0] expected [0:7] = '{ ... };
//
// It works on the workbench (Icarus Verilog 14.0) and it does NOT work on
// EDA Playground (Icarus Verilog 12.0). This file exists so the guide page can
// show you the exact error instead of describing it. See:
//   docs/guide/two-lines-make-the-waveform-appear.md

`timescale 1ns/1ps

module tb_eight_rows_compact;

    logic a, b, cin;
    logic sum, cout;

    full_adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    logic [1:0] expected [0:7] = '{
        2'b00, 2'b01, 2'b01, 2'b10,
        2'b01, 2'b10, 2'b10, 2'b11
    };

    int checked = 0;
    int errors  = 0;

    initial begin
        $display("tb_eight_rows_compact: all 8 inputs of full_adder");
        for (int row = 0; row < 8; row = row + 1) begin
            {a, b, cin} = row[2:0];
            #10;
            checked = checked + 1;
            if ({cout, sum} !== expected[row]) errors = errors + 1;
            #10;
        end
        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end
endmodule
