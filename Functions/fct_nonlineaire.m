function erreur=fct_nonlineaire(Param,Rbrut,Vitpoly)
CP1=Param(1);
CP2=Param(2);
erreur=sum(abs((Rbrut.*Vitpoly.*(log(Vitpoly/CP1))+2.*CP2.*CP1).^2));