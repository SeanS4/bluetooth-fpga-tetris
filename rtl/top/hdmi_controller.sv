`timescale 1 ns / 1 ps

module hdmi_text_controller_v1_0 (

    input logic Clk,
    input logic key_up, key_left, key_right, 
    input logic key_down, key_drop, key_start, key_reset,

    output logic hdmi_clk_n,
    output logic hdmi_clk_p,
    output logic [2:0] hdmi_tx_n,
    output logic [2:0] hdmi_tx_p,
    output logic [10:0] led  
);


//drawing and clock logic
     
 logic clk_25MHz, clk_100MHz, clk_125MHz;
 logic [9:0] drawX, drawY;
 logic locked;
 logic hsync, vsync, vde;
 logic [3:0] red, green, blue;


 
 //control signals
 logic [7:0] keycode;
 logic gravity_tick;
 logic board_init, board_done, game_init, game_start_done;
 logic spawn_piece, check_spawn, spawn_checked, spawn_collision;
 logic check_right, check_left, check_down, check_rotate;
 logic left_valid, right_valid, down_valid, rotate_valid, checked_collision;
 logic move_left, move_right, move_down, rotate_piece, lock_piece;
 logic done_locking, check_clear, clear_done;
 logic reset;
 logic game_over_reset;
 logic clk;

logic reset_clean;

sync_reset reset_synchronizer(
    .clk(clk),
    .rst_n_async(~key_reset),  // (if your button is active high, invert it here)
    .rst_sync(reset_clean)
);
 assign reset = reset_clean;

logic vga_frame_tick;
logic draw_top_left, draw_top_left_q;

assign draw_top_left = (drawX == 0) && (drawY == 0) && vde;

always_ff @(posedge clk_25MHz or posedge reset) begin
    if (reset)
        draw_top_left_q <= 0;
    else
        draw_top_left_q <= draw_top_left;
end

assign vga_frame_tick = draw_top_left & ~draw_top_left_q;

logic left_tick, right_tick, down_tick, rotate_tick;






das_arr_input left_input (
    .clk(clk_25MHz),
    .reset(reset),
    .vga_frame_tick(vga_frame_tick),
    .key(key_left),
    .action_tick(left_tick)
);

das_arr_input right_input (
    .clk(clk_25MHz),
    .reset(reset),
    .vga_frame_tick(vga_frame_tick),
    .key(key_right),
    .action_tick(right_tick)
);

das_arr_input down_input (
    .clk(clk_25MHz),
    .reset(reset),
    .vga_frame_tick(vga_frame_tick),
    .key(key_down),
    .action_tick(down_tick)
);

das_arr_input rotate_input (
    .clk(clk_25MHz),
    .reset(reset),
    .vga_frame_tick(vga_frame_tick),
    .key(key_up),
    .action_tick(rotate_tick)
);
 
 logic drop_debounced, start_debounced, reset_debounced;
sync_debouncer drop_in(
    .clk(clk),        // Clock signal
    .rst(reset),        // Reset signal
    .in_signal(key_drop), // Input signal to debounce
    .pulse_out(drop_debounced) // Debounced output pulse
);

sync_debouncer start_in(
    .clk(clk),        // Clock signal
    .rst(reset),        // Reset signal
    .in_signal(key_start), // Input signal to debounce
    .pulse_out(start_debounced) // Debounced output pulse
);


 

 //piece position logic
 logic [4:0] piece_x, piece_y;
logic [1:0] piece_rotation;
 logic [3:0][3:0] shape_matrix;
 logic [2:0] shape_type;


    logic        rotation_done;
    logic        rotation_success;
    logic [4:0]  new_piece_x;
    logic [4:0]  new_piece_y;
    logic [1:0]  new_rotation;

// Default spawn position
localparam int SPAWN_X = 18;
localparam int SPAWN_Y = 5;

logic [2:0] rand_type;
randomizer rando (
    .clk(clk),
    .reset(reset),
    .enable(spawn_piece),
    .random_out(rand_type)
);



always_ff @(posedge clk) begin
    if (reset || spawn_piece) begin
        piece_x <= SPAWN_X;
        piece_y <= SPAWN_Y;
        piece_rotation <= 0;
        shape_type <= (rand_type == 3'd7) ? 3'd0 : rand_type;
    end
    else if (rotate_piece) begin
            // Accept rotated position
        piece_x <= new_piece_x;
        piece_y <= new_piece_y;
        piece_rotation <= new_rotation;
    end
    else if (!rotation_done) begin
            // Movement only when no rotation is resolving
        if (move_left)
            piece_x <= piece_x - 1;
        if (move_right)
            piece_x <= piece_x + 1;
        if (move_down)   
            piece_y <= piece_y + 1;
        end
    end
 


    //dame read/write logic
    logic [10:0] bram_addr, init_addr, game_addr, collision_addr, rotate_addr, lock_addr, clear_addr;
    logic [7:0] bram_dout;
    logic [7:0] bram_wr_data, init_data, game_data, lock_data, clear_data;
    logic init_wren, game_wren, lock_wren, clear_wren, bram_wren;
    
    assign bram_wren = (game_init)  ? game_wren  :
                       (board_init) ? init_wren  : 
                       (lock_piece) ? lock_wren  :
                       (check_clear) ? clear_wren : 1'b0;

    always_comb begin
        if (game_init) begin
            bram_addr = game_addr;
            bram_wr_data = game_data;
        end
        else if (board_init) begin
            bram_addr = init_addr;
            bram_wr_data = init_data;
        end
        else if (check_rotate)
            bram_addr = rotate_addr;
        else if (check_left || check_right || check_down || check_spawn)
            bram_addr = collision_addr;
        else if (lock_piece) begin
            bram_addr = lock_addr;
            bram_wr_data = lock_data;
        end
        else if (check_clear) begin
        bram_addr = clear_addr;
        bram_wr_data = clear_data;
        end
        else begin
            bram_addr = 0;
            bram_wr_data = 0;
        end 
    end
    
   
     
    //render address logic
    logic [5:0] blockColumn, blockRow;
    logic [11:0] block_index;  
    logic [7:0] block_data;
    assign blockColumn = drawX[9:4];
    assign blockRow = drawY[8:4];
    assign block_index = blockRow * 40 + blockColumn;
    
    
    blk_mem_gen_0 bram (
    .addra    (bram_addr),                 // [10:0] for write
    .clka     (clk),
    .dina     (bram_wr_data),
    .douta    (bram_dout),
    .ena      (1'b1),
    .wea      (bram_wren),
    .rsta(reset),
    
    
    .addrb    (block_index), 
    .clkb     (clk_25MHz),
    .doutb    (block_data),
    .enb      (1'b1),
    .web      (4'b0000),
    .rstb(reset)
);

    logic [9:0] drawX_q, drawY_q;

//allign drawX and drawY with data after 1-cycle read latency
    always_ff @(posedge clk or posedge reset) begin
  if (reset) begin
    drawX_q <= 0;
    drawY_q <= 0;
  end else begin
    drawX_q <= drawX;
    drawY_q <= drawY;
  end
end
    
    
    //control unit
    tetris_fsm control(
    .input_clk(clk_100MHz),
    .board_done(board_done),
    .game_start_done(game_start_done),
    .reset(reset),  //reset_clean
    .gravity_tick(gravity_tick),        // pulse from gravity timer
    .key_up(rotate_tick),
    .key_down(down_tick), //change
    .key_left(left_tick),
    .key_right(right_tick),
    .key_drop(drop_debounced),
    .key_start(start_debounced),
    .left_valid(left_valid),  // change
    .right_valid(right_valid),  //change
    .down_valid(down_valid),  //change
    .collision_checked(checked_collision),   
    .check_spawn(check_spawn),
    .spawn_collision(spawn_collision),
    .spawn_checked(spawn_checked),
    .rotation_done(rotation_done),   //change
    .rotation_success(rotation_success),  //change
    .check_left(check_left),
    .check_right(check_right),
    .check_down(check_down),
    .check_rotate(check_rotate),
    .spawn_piece(spawn_piece),
    .move_left(move_left), 
    .move_right(move_right), 
    .move_down(move_down), 
    .rotate_piece(rotate_piece),
    .lock_piece(lock_piece),
    .done_locking(done_locking),
    .check_clear(check_clear),
    .clear_done(clear_done),
    .game_over(game_over_reset),
    .board_init(board_init),
    .game_init(game_init),
    .clk(clk),
    .state_debug(led)
);
    
    gravity_timer grav(
    .clk(clk),
    .reset(reset),
    .level(6),
    
    .gravity_tick(gravity_tick)
);
    
    
    draw_border initialize_board(
    .clk(clk),
    .rst(reset),
    .start_init(board_init),
    
    
    .done(board_done),
    .init_addr(init_addr),  // 0-1199
    .init_data(init_data),
    .init_wren(init_wren)
);
    
    draw_start_screen draw_start_screen_inst(
    .clk(clk),
    .rst(reset),
    .start_init(game_init),
    
    
    .done(game_start_done),
    .init_addr(game_addr),  // 0-1199
    .init_data(game_data),
    .init_wren(game_wren)
);
    
    
    
    collision_checker collision(
    .clk(clk),
    .reset(reset),

    .piece_x(piece_x),
    .piece_y(piece_y),
    .shape_matrix(shape_matrix), 
    .check_left(check_left),
    .check_right(check_right),
    .check_down(check_down),
    .check_spawn(check_spawn),
    .bram_dout(bram_dout),

    .collision_addr(collision_addr),
    .valid_left(left_valid),
    .valid_right(right_valid),
    .valid_down(down_valid),
    .collision_spawn(spawn_collision),
    .done_spawn(spawn_checked),
    .done(checked_collision) 
);
    
    rotation_checker rotate(
    .clk(clk),
    .reset(reset),

    .rotate_request(check_rotate),
    .piece_x(piece_x),
    .piece_y(piece_y),
    .current_rotation(piece_rotation),
    .shape_type(shape_type),
    .bram_dout(bram_dout),

    // BRAM interface
    .rotate_addr(rotate_addr),
    .rotation_done(rotation_done),
    .rotation_success(rotation_success),
    .new_piece_x(new_piece_x),
    .new_piece_y(new_piece_y),
    .new_rotation(new_rotation)
);

piece_locker lock(
    .clk(clk),
    .reset(reset),
    .lock_piece(lock_piece),           // One-cycle pulse to start lock
    .piece_x(piece_x),
    .piece_y(piece_y),
    .shape_type(shape_type),
    .shape_matrix(shape_matrix),

    // BRAM interface
    .lock_addr(lock_addr),
    .lock_data(lock_data),
    .lock_wren(lock_wren),
    .done_locking(done_locking)        // High for one cycle when done
);

clear_rows clearer(
    .clk(clk),
    .rst(reset),
    .clear_check(check_clear),             // High until FSM completes all operations
    .locked_piece_y(piece_y),    // Top Y of 4x4 piece

    .clear_addr(clear_addr),
    .bram_dout(bram_dout),        // 1-cycle latency
    .clear_wren(clear_wren),
    .clear_data(clear_data),
    .clear_done(clear_done)        // High for one cycle when clearing is done
);

    
 
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .clk_out3(clk_100MHz),
        .reset(1'b0),
        .locked(locked),
        .clk_in1(Clk)
    );

    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_clk_p),          
        .TMDS_CLK_N(hdmi_clk_n),          
        .TMDS_DATA_P(hdmi_tx_p),         
        .TMDS_DATA_N(hdmi_tx_n)          
    );
    
    shape_rom shapes(
        .clk(clk),
        .shape_type(shape_type),        // [2:0] 0-6 (I, O, T, S, Z, J, L)
        .rotation(piece_rotation),          //[1:0]  0-3 (0°, 90°, 180°, 270°)
        .shape_matrix(shape_matrix)   // Unpacked 4x4 matrix
);
    
    
 
logic [7:0] render_data; 
logic in_piece_bounds;
logic [1:0] shape_r, shape_c;
logic is_falling_tile;

assign in_piece_bounds = (blockColumn >= piece_x) && (blockColumn < piece_x + 4) &&
                         (blockRow >= piece_y) && (blockRow < piece_y + 4);

always_comb begin
    if (in_piece_bounds == 1) begin
        shape_r = blockRow - piece_y;
        shape_c = blockColumn - piece_x;
        is_falling_tile = in_piece_bounds && shape_matrix[shape_r][shape_c];
    end 
    else begin
        is_falling_tile = 0;
    end
end

logic is_falling_tile_d1;

always_ff @(posedge clk) begin
    is_falling_tile_d1 <= is_falling_tile;
end

assign render_data = (game_init || board_init) ? block_data :
                     (is_falling_tile_d1 ? {1'b1, {1'b0, shape_type + 1}, 2'b00, 1'b0} :  block_data);

     //Color Mapper Module     
    color_mapper color_instance(
        .render_data(render_data),      
        .DrawX(drawX_q),
        .DrawY(drawY_q),
        .Red(red),
        .Green(green),
        .Blue(blue)
    );



endmodule