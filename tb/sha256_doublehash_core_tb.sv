module sha256_doublehash_core_tb ();
  logic clk = 0;
  logic reset = 1;
  logic [639:0] blockHeader;
  logic [31:0] a, b, c, d, e, f, g, h;
  logic [255:0] digest;

  logic [255:0] expected_first_hash;
  logic [255:0] expected_digest;

  sha256_doublehash_core DUT (
      .clk(clk),
      .reset(reset),
      .blockHeader(blockHeader),
      .a(a),
      .b(b),
      .c(c),
      .d(d),
      .e(e),
      .f(f),
      .g(g),
      .h(h),
      .digest(digest)
  );

  /* clock generator */
  always #5 clk = ~clk;

  initial begin
    /* release reset after a couple of cycles */
    repeat (2) @(posedge clk);
    reset <= 0;

    /* use well documented test vector */
    blockHeader = 640'h0100000081cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000e320b6c2fffc8d750423db8b1eb942ae710e951ed797f7affc8892b0f1fc122bc7f5d74df2b9441a42a14695;
    expected_first_hash = 256'hb9d751533593ac10cdfb7b8e03cad8babc67d8eaeac0a3699b82857dacac9390;
    expected_digest = 256'h1dbd981fe6985776b644b173a4d0385ddc1aa2a829688d1e0000000000000000;

    repeat (110) @(posedge clk);

    if (DUT.first_hash !== expected_first_hash) begin
      $display("FAILED: First hash incorrect!");
      $fatal;
    end else begin
      $display("PASSED: First hash matches!");
    end

    repeat (110) @(posedge clk);

    if (DUT.digest !== expected_digest) begin
      $display("FAILED: Second hash (digest) incorrect!");
      $fatal;
    end else begin
      $display("PASSED: Second hash (digest) matches!");
    end
    $finish;
  end

endmodule
