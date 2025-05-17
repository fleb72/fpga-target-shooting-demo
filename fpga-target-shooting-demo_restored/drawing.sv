module drawing (
    input logic clk25, rst,
    input logic [9:0] x, y,
    input logic [11:0] CH0,
    input logic [11:0] CH1,
    input logic click,
    input logic inDisplayArea,
    input logic hsync, vsync,
    output logic [3:0] vga_r, vga_g, vga_b,
    output logic vga_hsync, vga_vsync,
    input logic frame,
    output logic [12:0] adr_reticle,
    input logic [11:0] color_pixel_reticle,
    output logic [12:0] adr_impact,
    input logic [11:0] color_pixel_impact,
    output logic [3:0] counter
);



    localparam SCREEN_WIDTH  = 640;
    localparam SCREEN_HEIGHT = 480;
    localparam SPRITE_WIDTH  = 60;  // largeur du sprite en pixels
    localparam SPRITE_HEIGHT = 60;  // hauteur du sprite en pixels

    localparam INIT_X = (SCREEN_WIDTH - SPRITE_WIDTH) / 2;  // Position centrale en X
    localparam INIT_Y = (SCREEN_HEIGHT - SPRITE_HEIGHT) / 2; // Position centrale en Y

    localparam MAX_HOLES = 10;

    integer reticle_x, reticle_y;
    integer reticle_dx, reticle_dy;

    logic first_frame = 1;

    // gestion des impacts de tir
    logic [9:0] hole_x [MAX_HOLES-1:0];  // pour stocker 16 positions x
    logic [9:0] hole_y [MAX_HOLES-1:0];  // pour stocker 16 positions y
    logic [3:0] hole_count = 0;          // Nombre d'impacts placés


    assign counter = hole_count;  // counter de tirs
    always_ff @(posedge clk25) begin
        if (rst==1) begin
            hole_count <= 4'd0;
        end else

        if (click) begin // tir détecté
            if (hole_count < MAX_HOLES) begin  // 10 tirs maxi
                hole_x[hole_count] <= reticle_x;  // Enregistre position actuelle du tir
                hole_y[hole_count] <= reticle_y;
                hole_count <= hole_count + 4'd1;
            end
        end
    end
    // -------------------------------------------------------

    // Gestion des mouvements du joystick
    always_ff @(posedge clk25) begin
        if (rst==1) begin
            first_frame <= 1;  // active l'initialisation après le premier cycle
        end else
        begin
            if (frame) begin
                if (first_frame) begin
                    reticle_x <= INIT_X;
                    reticle_y <= INIT_Y;
                    first_frame <= 0;  // Désactive l'initialisation après le premier cycle
                end else
                begin
                    if (CH0 > 3000) reticle_dy <= 6;
                    else if (CH0 > 2100) reticle_dy <= 2;
                    else if (CH0 > 1900) reticle_dy <= 0;
                    else if (CH0 > 1000) reticle_dy <= -2;
                    else reticle_dy <= -6;

                    if (CH1 > 3000) reticle_dx <= -6;
                    else if (CH1 > 2100) reticle_dx <= -2;
                    else if (CH1 > 1900) reticle_dx <= 0;
                    else if (CH1 > 1000) reticle_dx <= 2;
                    else reticle_dx <= 6;

                    reticle_x <= reticle_x + reticle_dx;
                    reticle_y <= reticle_y + reticle_dy;

                    if (reticle_x > SCREEN_WIDTH - SPRITE_WIDTH) begin    // contact sur bord droit
                        reticle_x <= SCREEN_WIDTH - SPRITE_WIDTH;
                    end
                    else if (reticle_x < 0) begin                         // contact sur bord gauche
                        reticle_x <= 0;
                    end

                    if (reticle_y > SCREEN_HEIGHT - SPRITE_HEIGHT) begin  // contact sur bord bas
                        reticle_y <= SCREEN_HEIGHT - SPRITE_HEIGHT;
                    end
                    else if (reticle_y < 0) begin                         // contact sur bord haut
                        reticle_y <= 0;
                    end

                end
            end
        end
    end
    // -------------------------------------------------------


    // ----- Gestion de l'affichage -----

    // inReticle=1 si le pixel (x, y) en cours de balayage est à l'intérieur du sprite du réticule, inReticle=0 sinon
    logic inReticle;
    assign inReticle = (x >= reticle_x) && (x < reticle_x + SPRITE_WIDTH)
        &&
        (y >= reticle_y) && (y < reticle_y + SPRITE_HEIGHT);


    assign adr_reticle = (y - reticle_y) * SPRITE_WIDTH + (x - reticle_x);


    logic [3:0] r, g, b;


    always_comb begin
        r = 4'h0;  // hors zone d'affichage active de l'écran
        g = 4'h0;
        b = 4'h0;

        adr_impact = 0;

        if (inDisplayArea) begin // pixel dans l'aire visible 640x480

            // dessin des impacts
            for (int i = 0; i < hole_count; i++) begin
                if (i < MAX_HOLES) begin // nécessaire à la compilation, car i est un int et peut potentiellement dépasser MAX_HOLES

                    if ((x >= hole_x[i]) && (x < hole_x[i] + SPRITE_WIDTH)
                        &&
                        (y >= hole_y[i]) && (y < hole_y[i] + SPRITE_HEIGHT)) begin

                        adr_impact = (y - hole_y[i]) * SPRITE_WIDTH + (x - hole_x[i]) + SPRITE_WIDTH * SPRITE_HEIGHT;

                        r = color_pixel_impact[11:8];
                        g = color_pixel_impact[7:4];
                        b = color_pixel_impact[3:0];
                    end
                end
            end

            // dessin du sprite du réticule
            if (inReticle && color_pixel_reticle != 12'h000) begin  // gestion de la transparence avec les pixels noirs
                r = color_pixel_reticle[11:8];
                g = color_pixel_reticle[7:4];
                b = color_pixel_reticle[3:0];
            end

            if ((x == reticle_x + SPRITE_WIDTH / 2)
                || (y == reticle_y + SPRITE_HEIGHT / 2)) begin // les 2 lignes horizontale et verticale de la croix du viseur
                r = 4'h3a;
                g = 4'hd4;
                b = 4'hd4;
            end

        end
    end


    always_ff @(posedge clk25) begin  // transfert des signaux sur le port VGA
        {vga_hsync, vga_vsync}  <= {hsync, vsync} ;
        {vga_r, vga_g, vga_b} <= {r, g, b};
    end




endmodule
