function erreur=fct_Lineaire(param, temps, Ra)
    
    S = param(1); 
    L = param(2);
    C = param(3);
    Z = exp((S.*temps+C)./(2*L))./(2.*L);
    r = 2*L.*lambertw(Z); % Résolution du modèle linéraire 
    erreur = sum(abs(r - Ra).^2); % erreur globale (somme des valeurs absolues des carrés des résidus) 

end