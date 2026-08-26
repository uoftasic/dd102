// tb_eight_rows.sv — the second circuit. Its whole job is doubt.
//
// It drives every input a full adder can ever see — all eight — compares each
// answer against the truth table you filled in by hand in DD101, and writes a
// waveform on the way past.
//
// Change the eight `expected` lines to YOUR eight rows. Nothing else.

`timescale 1ns/1ps

module tb_eight_rows;

    // ---- the wires between this testbench and the thing being doubted ----
    logic a, b, cin;        // we drive these
    logic sum, cout;        // the adder drives these

    full_adder dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    // ---- your DD101 truth table, one row per line, as {cout, sum} --------
    logic [1:0] expected [0:7];

    logic mismatch;         // high on any row that disagrees. It is dumped.
    int   checked   = 0;
    int   errors    = 0;
    time  first_bad = 0;

    initial begin
        expected[0] = 2'b00;    // a=0 b=0 cin=0  ->  0
        expected[1] = 2'b01;    // a=0 b=0 cin=1  ->  1
        expected[2] = 2'b01;    // a=0 b=1 cin=0  ->  1
        expected[3] = 2'b10;    // a=0 b=1 cin=1  ->  2
        expected[4] = 2'b01;    // a=1 b=0 cin=0  ->  1
        expected[5] = 2'b10;    // a=1 b=0 cin=1  ->  2
        expected[6] = 2'b10;    // a=1 b=1 cin=0  ->  2
        expected[7] = 2'b11;    // a=1 b=1 cin=1  ->  3

        $timeformat(-9, 0, " ns", 6);
        $dumpfile("eight.vcd");
        $dumpvars(0, tb_eight_rows);

        $display("tb_eight_rows: all 8 inputs of full_adder");
        $display("  a b cin | cout sum | want");
        $display("  --------+----------+-----");

        for (int row = 0; row < 8; row = row + 1) begin
            {a, b, cin} = row[2:0];
            mismatch = 1'b0;
            #10;
            mismatch = ({cout, sum} !== expected[row]);
            checked  = checked + 1;
            $display("  %b %b  %b  |   %b   %b  |  %b %b   %0s",
                     a, b, cin, cout, sum, expected[row][1], expected[row][0],
                     mismatch ? "MISMATCH" : "ok");
            if (mismatch) begin
                if (errors == 0) first_bad = $time;
                errors = errors + 1;
            end
            #10;
        end

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors != 0) $display("FIRST MISMATCH at %0t", first_bad);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");
        $finish;
    end
endmodule
