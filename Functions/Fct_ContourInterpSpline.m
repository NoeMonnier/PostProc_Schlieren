function C = Fct_ContourInterpSpline(Cont,Grand,pas)
% interpolation du contour avec un intervalle defini 
% par le pas et le grandissement en mm/pixels :
% C=Contour_Interp(Cont,Grand,pas);
% contour en pixels et pas en mm
% Fabrice Foucher, 16/08/2000
% ex : C=Fct_ContourInterpSpline(Cont,1,1);

if nargin==0, help Fct_ContourInterpSpline, return, end
if nargin<3, error('Nombre d''arguments manquant'), return, end

abscurv = cumsum(abs(diff(Cont)));
longueur = max(abscurv);
l = [0:(pas/Grand)*10:longueur*10]/10;
C = interp1([0 abscurv],Cont,[0:pas*10:longueur*10]/10,'spline');