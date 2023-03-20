function erreur=fct_Lineaire(param, temps, Ra)

    [~,r] = ode45(@(t,r) param(1)/(1+(2*param(2)/r)), temps, param(3)); % Résolution du modèle linéraire 
    erreur = sum(abs(r - Ra).^2); % erreur globale (somme des valeurs absolues des carrés des résidus) 

end