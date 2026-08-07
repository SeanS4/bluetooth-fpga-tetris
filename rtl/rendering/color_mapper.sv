module color_mapper(
    input logic [7:0] render_data, // should also be changed in top level
    input  logic [9:0] DrawX, DrawY,
    output logic [3:0] Red, Green, Blue
);
 
    logic [11:0] palette [0:9];  // Base RGB colors (12-bit RGB444)
    logic [3:0] pixelRow;
    logic [3:0] pixelColumn;
    logic [3:0] base_red, base_green, base_blue;
    logic [3:0] shaded_red, shaded_green, shaded_blue;

    assign pixelRow    = DrawY[3:0];
    assign pixelColumn = DrawX[3:0];

    // Extract color index from render_data (bits [6:3])
    logic [3:0] color_index;
    assign color_index = render_data[6:3]; 

    // Get base color
    assign {base_red, base_green, base_blue} = palette[color_index];

    // Edge shading with diagonal intersections
    always_comb begin
        shaded_red   = base_red;
        shaded_green = base_green;
        shaded_blue  = base_blue;
        // Brighten top region with diagonal fade (top edge)
        if (pixelRow < 2) begin
            if(!(((pixelColumn < 2) && (pixelRow > pixelColumn)) ||((pixelColumn > 13) && (pixelColumn + pixelRow > 15)))) begin
            shaded_red   = (base_red   > 12) ? 4'hF : base_red   + 2;
            shaded_green = (base_green > 12) ? 4'hF : base_green + 2;
            shaded_blue  = (base_blue  > 12) ? 4'hF : base_blue  + 2;
            end
        end
        // Darken bottom region with diagonal fade (bottom edge)
        else if (pixelRow > 13) begin 
            if (!(((pixelColumn > 13) && (pixelRow <= pixelColumn)) ||((pixelColumn < 2) && (pixelColumn + pixelRow < 15)))) begin
            shaded_red   = (base_red > 1) ? base_red >> 1 : 1;
            shaded_green = (base_green > 1) ? base_green >> 1 : 1;
            shaded_blue  = (base_blue > 1) ? base_blue >> 1 : 1;
            end
        end
        // Slightly darken left edge (fade into center diagonally)
         else if (pixelColumn < 2) begin 
            if (!(((pixelRow > 2) && (pixelRow <= pixelColumn)) ||((pixelRow > 13) && (pixelColumn + pixelRow >= 15)))) begin
            shaded_red   = (base_red > 0) ? base_red - 1 : 0;
            shaded_green = (base_green > 0) ? base_green - 1 : 0;
            shaded_blue  = (base_blue > 0) ? base_blue - 1 : 0;
            end
        end
        // Slightly darken right edge (fade into center diagonally)
        else if (pixelColumn > 13) begin 
            if (!(((pixelRow > 13) && (pixelRow > pixelColumn)) ||((pixelRow < 2) && (pixelColumn + pixelRow <= 15)))) begin
            shaded_red   = (base_red > 0) ? base_red - 1 : 0;
            shaded_green = (base_green > 0) ? base_green - 1 : 0;
            shaded_blue  = (base_blue > 0) ? base_blue - 1 : 0;
            end
        end
    end

    assign Red   = shaded_red;
    assign Green = shaded_green;
    assign Blue  = shaded_blue;
    
   
    
    assign palette[0] = 12'h000; // black  //change to 000
    assign palette[1] = 12'h0FF; // cyan
    assign palette[2] = 12'hF00; // red
    assign palette[3] = 12'h0F0; // green
    assign palette[4] = 12'h00F; // blue
    assign palette[5] = 12'hFF0; // yellow
    assign palette[6] = 12'hF0F; // magenta
    assign palette[7] = 12'hF50; // orange
    assign palette[8] = 12'hAAA; // gray
    assign palette[9] = 12'hFFF; // white
   

endmodule