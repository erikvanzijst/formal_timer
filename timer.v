`default_nettype none
module timer(
    input clk,
    input reset,
    input load,
    input [15:0] cycles,
    output busy
    );

    reg [15:0] counter;

    always @(posedge clk) begin
        if(reset)
            counter <= 0;
        else if (load)
            counter <= cycles;
        else if (counter > 0)
            counter <= counter - 1'b1;
    end

    assign busy = counter > 0;

    `ifdef FORMAL
    // register for knowing if we have just started
    reg f_past_valid = 0;
    // start in reset
    initial assume(reset);
    always @(posedge clk) begin
        
        // assume timer won't get loaded with a 0
        assume(cycles > 0);

        // update past_valid reg so we know it's safe to use $past()
        f_past_valid <= 1;

        // cover the counter getting loaded and starting to count
        _loaded_: cover(reset == 0 && (busy == 1 || load == 1));

        // cover timer finishing
        if (f_past_valid) begin
            _finishing_: cover(counter == 0 && $past(counter == 1) && $past(reset == 0) && load == 0);
        end

        // busy
        if (counter > 0) begin
            _busy_: assert(busy == 1);
        end

        // load works
        if (f_past_valid) begin
            if ($past(load) == 1 && $past(reset) == 0) begin
                _loadworks_: assert($past(cycles) == counter);
            end
        end

        // counts down
        if (f_past_valid) begin
            if (busy == 1 && $past(busy) == 1 && load == 0 && $past(load) == 0 && reset == 0) begin
                _countdown_: assert($past(counter) == counter + 1);
            end
        end

    end
    `endif
    
endmodule
