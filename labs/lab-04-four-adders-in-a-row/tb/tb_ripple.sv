// tb_ripple.sv — the same exhaustive test, at whatever width you ask for.
//   iverilog -g2012 -Ptb_ripple.N=8 -o wide8.vvp tb/tb_ripple.sv src/ripple.sv src/full_adder.sv
`timescale 1ns / 1ps

module tb_ripple;

    parameter int N = 4;

    logic [N-1:0] a, b;
    logic         cin;
    logic [N-1:0] sum;
    logic         cout;

    ripple #(.N(N)) dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    logic [N:0] want;
    longint cases = 0;
    longint bad   = 0;

    initial begin
        for (longint i = 0; i < (1 << N); i++)
        for (longint j = 0; j < (1 << N); j++)
        for (int    k = 0; k < 2;          k++) begin
            a = i[N-1:0]; b = j[N-1:0]; cin = k[0];
            #1;
            want = a + b + cin;
            cases++;
            if ({cout, sum} !== want) bad++;
        end

        $display("");
        $display("N = %0d   %0d cases", N, cases);
        if (bad == 0) $display("PASS  0 mismatches out of %0d", cases);
        else          $display("FAIL  %0d mismatches out of %0d", bad, cases);
        $finish;
    end
endmodule
