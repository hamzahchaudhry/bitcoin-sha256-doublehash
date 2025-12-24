module sha256_doublehash_core_tb ();

  logic clk = 0;
  logic reset = 1;
  logic start = 0;
  logic [639:0] blockHeader;
  logic [255:0] digest;
  logic finish;

  logic [255:0] expected_digest;

  sha256_doublehash_core DUT (
      .clk(clk),
      .reset(reset),
      .start(start),
      .blockHeader(blockHeader),
      .digest(digest),
      .finish(finish)
  );

  /* clock generator */
  always #5 clk = ~clk;

  task automatic run_test(string name, logic [639:0] blockHeader_in, logic [255:0] expected);
    begin
      blockHeader = blockHeader_in;
      expected_digest = expected;

      @(posedge clk);
      start <= 1;

      @(posedge clk);
      start <= 0;

      @(posedge finish);

      if (digest !== expected_digest) begin
        $display("FAILED!: %s\nactual  : %h\nexpected: %h", name, digest, expected_digest);
        $fatal;
      end else begin
        $display("PASSED!: %s", name);
      end
    end
  endtask

  initial begin
    repeat (2) @(posedge clk);
    reset <= 0;

    run_test("bitcoin test vector",
             640'h0100000081cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000e320b6c2fffc8d750423db8b1eb942ae710e951ed797f7affc8892b0f1fc122bc7f5d74df2b9441a42a14695,
             256'h1dbd981fe6985776b644b173a4d0385ddc1aa2a829688d1e0000000000000000);

    $finish;

  end

endmodule
