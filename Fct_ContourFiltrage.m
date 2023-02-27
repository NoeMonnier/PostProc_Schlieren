function C=Fct_ContourFiltrage(Cont, Echelle_Filtre, Grandissement);
%   Filtrage en utilisant filtfilt et les coeffcients donnés par butterworth
%   Remarque : Pour ne pas perdre d'infos aux extrémités du contour, on rajoute deux morceaux de courbe au deux extrémités sur NPts = taille du filtre	

%   Cont : contour de flamme complexe en pixels
%   Echelle_Filtre : taille du filtre [mm]
%   C=Fct_ContourFiltrage(Cont,NPts);

%   Bénédicte Galmiche, 20/03/2013

if nargin==0, help Fct_ContourFiltrage, return, end
if nargin<2, error('Nombre d''arguments manquant'), return, end

F_Niquist = 2*1;   % résolution = 1 pixel
F_Coupure_norm = (Grandissement/Echelle_Filtre)/F_Niquist; % fréquence de coupure normalisée
NPts = Echelle_Filtre/Grandissement;   % nbre de points pour calculer la pente moyenne aux extrémités du contour
[b1 b2] = butter(3,F_Coupure_norm);

Cont=Cont(:);
xc=real(Cont);
yc=imag(Cont);
lg=length(Cont);

% test sur la longueur du contour (condition pour la fonction filtfilt)
if lg>3*length(b1)

    C = [Cont(end-NPts:1:end); Cont; Cont(1:NPts)];

    C=filtfilt(b1,b2,C);

    C=C(NPts+2:end-NPts-1);
else
    disp('Contour pas assez long : length(Cont)>3*taille du filtre')
end