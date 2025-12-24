module sha256_compress_tb ();

  logic clk = 0;
  logic reset = 1;
  logic start = 0;
  logic [511:0] chunk;
  logic [255:0] state_in = {
    32'h6a09e667,
    32'hbb67ae85,
    32'h3c6ef372,
    32'ha54ff53a,
    32'h510e527f,
    32'h9b05688c,
    32'h1f83d9ab,
    32'h5be0cd19
  };
  logic [255:0] state_out;
  logic finish;

  logic [255:0] expected_digest;

  sha256_compress DUT (
      .clk(clk),
      .reset(reset),
      .start(start),
      .chunk(chunk),
      .state_in(state_in),
      .state_out(state_out),
      .finish(finish)
  );

  /* clock generator */
  always #5 clk = ~clk;

  task automatic run_test(string name, logic [511:0] chunk_in, logic [255:0] expected);
    begin
      chunk = chunk_in;
      expected_digest = expected;

      @(posedge clk);
      start <= 1;

      @(posedge clk);
      start <= 0;

      @(posedge finish);

      if (state_out !== expected_digest) begin
        $display("FAILED!: %s\nactual  : %h\nexpected: %h", name, state_out, expected_digest);
        $fatal;
      end else begin
        $display("PASSED!: %s", name);
      end
    end
  endtask

  initial begin
    repeat (2) @(posedge clk);
    reset <= 0;

    /* empty string test */
    run_test("EMPTY STRING TEST", {1'd1, 511'd0},
             256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855);

    /* 'abc' test */
    run_test("'abc' TEST", {24'h616263, 1'd1, 423'd0, 64'd24},
             256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad);

    $finish;

  end

endmodule
