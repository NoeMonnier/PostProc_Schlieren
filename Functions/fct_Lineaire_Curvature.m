function erreur=fct_Lineaire_Curvature(param, temps, rayons)

    [~,r] = ode45(@(t,r) param(1)-(2*param(2)/r), temps, param(3)); % Résolution du modèle linéaire basé sur la courbure
    erreur = sum(abs(r - rayons).^2); % erreur globale (somme des valeurs absolues des carrés des résidus)

end