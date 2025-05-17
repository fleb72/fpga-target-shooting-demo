module debounce #(parameter STABILITY = 130_000) // 130 000/(25,2x10^6) = 5ms environ
(
    input logic clk25,       // Horloge principale
    input logic button_in, // Signal brut du bouton (avec rebonds)
    output logic button_out // Signal stabilisé sans rebonds
);

    localparam WIDTH = $clog2(STABILITY);
    logic [WIDTH-1:0] counter;  // Compteur pour le filtrage des rebonds
    logic a, b, stable;    // Registres internes pour la synchronisation

    always_ff @(posedge clk25) begin
        a <= button_in; // Premier étage de synchronisation
        b <= a;         // Deuxième étage de synchronisation

        if (a ^ b) begin  // Détection de variations (rebonds ou véritables transitions)
            counter <= 0; // Réinitialisation du compteur
        end else if (counter < STABILITY) begin // Comptage jusqu'à seuil de stabilité 130 000/(25,2x10^6) = 5ms environ
            counter <= counter + 1;
        end

        if (counter == STABILITY) stable <= b; // Validation du signal stabilisé
    end

    assign button_out = stable; // Sortie filtrée et stabilisée

endmodule
