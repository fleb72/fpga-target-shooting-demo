module edge_down(
    input logic clk25,       // Horloge principale
    input logic button_in, // Signal brut du bouton (avec rebonds)
    output logic pulse 
);

    logic button_prev; // Registre pour l'état précédent du bouton

    always_ff @(posedge clk25) begin
        button_prev <= button_in; // Stocke l'état précédent
    end

    // Détection du front descendant (passage de 1 à 0)
    assign pulse = button_prev && !button_in;

endmodule