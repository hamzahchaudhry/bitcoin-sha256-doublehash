module miner_top_tb;

  logic clk = 0;
  logic reset = 1;
  logic start = 0;

  logic [607:0] blockHeader_noNonce;
  logic [255:0] target;
  logic [255:0] digest;
  logic [31:0] golden_nonce;
  logic finish;

  /* bitcoin block header (76 bytes) without nonce */
  localparam logic [607:0] BLOCKHEADER_NO_NONCE = 608'h0100000081cd02ab7e569e8bcd9317e2fe99f2de44d49ab2b8851ba4a308000000000000e320b6c2fffc8d750423db8b1eb942ae710e951ed797f7affc8892b0f1fc122bc7f5d74df2b9441a;
  localparam logic [255:0] TARGET_MAX = 256'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  /* expected double-SHA256 digest when nonce=0 */
  localparam logic [255:0] EXPECTED_DIGEST = 256'hd883d7a3b814e3eace8a16e2f733c55780f87df3accdb85ee64a8241890f83da;

  miner_top DUT (
      .clk(clk),
      .reset(reset),
      .start(start),
      .blockHeader_noNonce(blockHeader_noNonce),
      .target(target),
      .digest(digest),
      .golden_nonce(golden_nonce),
      .finish(finish)
  );

  /* clock generator */
  always #5 clk = ~clk;

  initial begin
    blockHeader_noNonce = BLOCKHEADER_NO_NONCE;
    target = TARGET_MAX;

    repeat (2) @(posedge clk);
    reset <= 0;

    /* kick off hashing */
    @(posedge clk);
    start <= 1'b1;

    @(posedge clk);
    start <= 1'b0;

    @(posedge finish);

    if (digest !== EXPECTED_DIGEST) begin
      $display("FAILED!: digest mismatch\nactual  : %h\nexpected: %h", digest, EXPECTED_DIGEST);
      $fatal;
    end

    if (golden_nonce !== 32'd0) begin
      $display("FAILED!: nonce mismatch\nactual  : %0d\nexpected: 0", golden_nonce);
      $fatal;
    end

    $display("PASSED!: miner_top basic hashing flow");
    $finish;
  end

endmodule
