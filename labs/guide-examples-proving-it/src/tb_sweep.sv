// tb_sweep.sv — every input this adder can ever see. All 512 of them.
//
// 16 values of a, times 16 values of b, times 2 values of cin, is 512. That is
// not a sample. It is the entire behaviour of the circuit, the same way eight
// rows was the entire behaviour of one full adder.
//
// It prints only the FIRST FIVE mismatches and then a count, because 256
// MISMATCH lines would scroll the interesting part off the screen.
//
// Run it with `+clue` for the per-input breakdown.

`timescale 1ns/1ps

module tb_sweep;

    logic [3:0] a, b;
    logic       cin;
    logic [3:0] sum;
    logic       cout;
    logic [4:0] expected;

    logic       mismatch;       // dumped, so you can watch it go high
    int         checked   = 0;
    int         errors    = 0;
    int         shown     = 0;
    time        first_bad = 0;

    // one counter per input bit, for the breakdown at the end
    int wrong_when_1 [0:8];
    int wrong_when_0 [0:8];

    logic [8:0] v;              // {a, b, cin} packed into one 9-bit number

    ripple4 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    initial begin
        $timeformat(-9, 0, " ns", 6);
        $dumpfile("sweep.vcd");
        $dumpvars(0, tb_sweep);

        for (int k = 0; k < 9; k = k + 1) begin
            wrong_when_1[k] = 0;
            wrong_when_0[k] = 0;
        end

        $display("tb_sweep: all 512 inputs of ripple4");

        for (int i = 0; i < 512; i = i + 1) begin
            v = i[8:0];
            {a, b, cin} = v;
            mismatch = 1'b0;
            #10;
            expected = a + b + cin;
            mismatch = ({cout, sum} !== expected);
            checked  = checked + 1;

            if (mismatch) begin
                if (errors == 0) first_bad = $time;
                errors = errors + 1;
                if (shown < 5) begin
                    shown = shown + 1;
                    $display("  MISMATCH  %0d + %0d + %0d : ripple4 said %0d, the answer is %0d",
                             a, b, cin, {cout, sum}, expected);
                end
                for (int k = 0; k < 9; k = k + 1)
                    if (v[k]) wrong_when_1[k] = wrong_when_1[k] + 1;
                    else      wrong_when_0[k] = wrong_when_0[k] + 1;
            end
            #10;
        end

        if (errors > shown)
            $display("  ... and %0d more. Only the first %0d are printed.", errors - shown, shown);

        $display("TESTED %0d", checked);
        $display("ERRORS %0d", errors);
        if (errors != 0) $display("FIRST MISMATCH at %0t", first_bad);
        if (errors == 0) $display("VERDICT PASS");
        else             $display("VERDICT FAIL");

        if ($test$plusargs("clue")) begin
            $display("");
            $display("  input   wrong when it is 0   wrong when it is 1");
            $display("  cin              %5d                %5d", wrong_when_0[0], wrong_when_1[0]);
            for (int k = 0; k < 4; k = k + 1)
                $display("  b[%0d]             %5d                %5d", k, wrong_when_0[k+1], wrong_when_1[k+1]);
            for (int k = 0; k < 4; k = k + 1)
                $display("  a[%0d]             %5d                %5d", k, wrong_when_0[k+5], wrong_when_1[k+5]);
        end

        $finish;
    end
endmodule
