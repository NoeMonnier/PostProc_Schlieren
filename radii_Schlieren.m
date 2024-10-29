%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               Rayons et vitesse de propagation Schlieren                %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all
warning off

%% CHOIX DU REPERTOIRE/BASE DE TRAVAIL

addpath('./Functions') % Répertoire où sont stockées les fonctions MATLAB
RepBase = uigetdir('C:\Users\noe.monnier\Documents\NO\'); % Répertoire où sont stockées les fichiers du tir
OriginalRepBase = RepBase; % Copie du chemin du répertoire de travail

%% PARAMETRES

sizex = 1280; % Size of the picture [pxl]
sizey = 800; 
Rayon_min_traite = 6; % Rayon minimum [mm] utilisé pour le calcul de vitesse
Rayon_max_traite = 25; % Rayon maximum [mm] utilisé pour le calcul de vitesse
F = 7000; % Fréquence d'aquisition de la caméra
skip = 2; % Saut d'images effectué lors de la detection des contours
largeur = 5; % Largeur du gradient utilisé pour calculé la vitesse (Défaut : 1)

imagesplit = false; % Si le Schlieren est splité : true 

%% TRAITEMENT DES CONTOURS

disp('### Determination des rayons et des vitesses ###')

for LeftRight=2:2 % Images à traiter : 1:1 (gauche) OU 1:2 (gauche et droite) OU 2:2 (droite ou non slipt)

    if LeftRight==1 && imagesplit % Selection de la base de travail pour le Schlieren splité
        RepBase = [OriginalRepBase '\0_Images_Left'];
    elseif LeftRight==2 && imagesplit
        RepBase = [OriginalRepBase '\0_Images_Right'];
    end

    CheminImageContour = [RepBase '\2_Images_Contour']; % Chemin d'accès aux données des contours
    ListeContours = dir([CheminImageContour '\*.mat']); % Liste des différents fichiers contour
    NbContours = length(ListeContours); % Nombre de contours à traiter 

    ListeImage = dir([RepBase '\*.tif']); % Chemin d'accès aux images brutes
    ImageName = ListeImage(2).name(1:end-7); % Nom des images brutes (sans le numéro et l'extension)

    clear Ra Ra_fit Rp Rp_fit Vt % Clear les variables Rayons par sécurité
    Ra = zeros(NbContours, 1); % Rayon calculé à partir de l'aire du contour
    Rp = zeros(NbContours, 1); % Rayon calculé à partir du périmètre du contour 
    A = zeros(NbContours, 1); % Aire du contour
    P = zeros(NbContours, 1); % Périmètre du contour
    NumContours = zeros(NbContours, 1); % Numéro des images correspondants aux contours
    centre_x = zeros(NbContours, 1); % Abscises des centres des contours
    centre_y = zeros(NbContours, 1); % Ordonnées des centres des contours
    Shape_ratio = zeros(NbContours, 1); % Ratio d'aspect des contours
    Roundness = zeros(NbContours, 1); % Roundness des contours

    %% DETERMINATION DES RAYONS EQUIVALENTS

    for i = 1:NbContours

        load([CheminImageContour '\' ListeContours(i).name]); % Charge le contour de l'image i
        NumeroContours = ListeContours(i).name(end-6:end-4); % Isole le numéro de la frame dont le contour est issu
        NumContours(i) = str2double(NumeroContours); % Converti NumContours du format string au format double

        XContour = real(Contour_filt_int); % Abscises des point du contour
        YContour = abs(imag(Contour_filt_int)); % Ordonnées des points du contour

        [geom, ~, ~] = polygeom(XContour, YContour); % Calcul les différentes propriétés du contour 
        A(i) = geom(1)*(Grandissement(LeftRight)^2); % Aire du contour en mm² 
        P(i) = geom(4)*Grandissement(LeftRight); % Périmètre du contour en mm
        % geom(2) et geom(3) sont les positions x,y du centre de gravité du contour
        centre_x(i) = geom(2);%*Grandissement(LeftRight);
        centre_y(i) = geom(3);%*Grandissement(LeftRight);
        Ra(i) = sqrt(A(i)/pi()); % Rayon moyen basé sur l'aire du contour en mm
        Rp(i) = P(i)/(2*pi()); % Rayon moyen basé sur le perimètre du contour en mm
        Shape_ratio(i) = (max(YContour)-min(YContour))/(max(XContour)-min(XContour)); % Ratio d'aspect du contour 
        Roundness(i) = (4*pi()*A(i))/(P(i)^2); % Roundness du contour

        disp(['Contour n°' num2str(NumContours(i)) ' : Ra = ' num2str(Ra(i)) ' mm'])

    end
    dt = 1/F*1000; % pas de temps entre 2 images [ms]
    temps(:,1) = NumContours*dt; % Vecteur temps (démarre à l'instant du premier contour) [ms]
    
    % Filtrage des Rayons
    Ra_filt = filtfilt([1 1 1 1 1], 5, Ra); % Ra filtré
    Rp_filt = filtfilt([1 1 1 1 1], 5, Rp); % Rp filtré

    %% CALCUL DES VITESSES DE PROPAGATION A PARTIR DE RA
    
    Vt = zeros(NbContours, 1);
    Vt_filt = zeros(NbContours, 1); 
    Posrayonmin = min(find(Ra_filt>=Rayon_min_traite)); % Pos du rayon min dans Ra_filt
    Posrayonmax = max(find(Ra_filt<=Rayon_max_traite)); % Pos du rayon max dans Ra_filt
    Vt_temp = grad(Ra_filt(Posrayonmin:Posrayonmax),dt*skip,largeur); % Calcul de la vitesse sur la plage de Rayon choisi
    d1 = designfilt('lowpassiir','FilterOrder',12,'HalfPowerFrequency',0.1,'DesignMethod','butter'); % Filtre passe-bas IIR pour filtrer la courbe de vitesse obtenue 
    Vt_filt_temp = filtfilt(d1, Vt_temp); % Filtrage de la vitesse
    Vt(Posrayonmin:Posrayonmax) = Vt_temp;
    Vt_filt(Posrayonmin:Posrayonmax) = Vt_filt_temp;
    Froude = Vt_filt(Posrayonmin:Posrayonmax)./sqrt(9.81.*(Ra_filt(Posrayonmin:Posrayonmax)./1000)); % Froude number : buoyancy effect
    
    %% CALCUL DES ERREURS RELATIVES

    Erreur_Ra = abs(Ra_filt-Ra)./abs(Ra)*100; % Erreur relative de filtrage
    Erreur_Rp = abs(Rp_filt-Rp)./abs(Ra)*100; % Erreur relative de filtrage
    Erreur_Vt = abs(Vt_filt-Vt)./abs(Vt)*100; % Erreur relative de filtrage
    Erreur_Rayons = abs(Ra_filt-Rp_filt); % Erreur absolue sur les rayons 

    %% PLOT DES RESULTATS

    % Plot des rayons et des rayons filtrés 
    figure(1*LeftRight)
    hold on
    plot(temps, Ra, 'b+')
    plot(temps, Rp, 'g+')
    plot(temps, Ra_filt, 'r-')
    plot(temps, Rp_filt, 'k-')
    hold off
    xlabel('Temps [ms]','Interpreter','latex')
    ylabel('Rayon equivalent [mm]','Interpreter','latex')
    legend('Ra', 'Rp', 'Ra$_{filt}$', 'Rp$_{filt}$','Interpreter','latex')
    axis([0 temps(end) 0 Ra(end)+5])
    box on;
    saveas(gcf, [RepBase '\Evolution_rayons.fig']) % Sauvegarde de la figure

    % Plot des vitesses brutes et filtrées
    figure(10*LeftRight)
    hold on
    plot(Ra_filt, Vt, 'r+')
    plot(Ra_filt, Vt_filt, 'bo')
    hold off
    xlabel('Rayon Ra$_{filt}$ [mm]','Interpreter','latex')
    ylabel('Vitesse de propagation [m/s]','Interpreter','latex')
    legend('Vt', 'Vt$_{filt}$','Interpreter','latex')
    box on;
    saveas(gcf, [RepBase '\Evolution_Vt.fig']) % Sauvegarde de la figure

    % Plot des erreurs
    figure(100*LeftRight)

    subplot(2,2,1)
    plot(Ra_filt, Erreur_Rayons, 'r','LineWidth',2)
    xlabel('Rayon [mm]','Interpreter','latex')
    ylabel('Erreur [mm]','Interpreter','latex')
    title('Erreur sur les rayons','Interpreter','latex')
    xlim([0 round(Ra_filt(end))+5])
    box on;

    subplot(2,2,2)
    plot(Ra_filt,Erreur_Ra,'r','LineWidth',2)
    xlabel('Rayon [mm]','Interpreter','latex')
    ylabel('Erreur [%]','Interpreter','latex')
    title('Erreur de filtrage Ra','Interpreter','latex')
    xlim([0 round(Ra_filt(end))+5])
    box on;

    subplot(2,2,3)
    plot(Rp_filt,Erreur_Rp,'r','LineWidth',2)
    xlabel('Rayon [mm]','Interpreter','latex')
    ylabel('Erreur [%]','Interpreter','latex')
    title('Erreur de filtrage Rp','Interpreter','latex')
    xlim([0 round(Rp_filt(end))+5])
    box on;

    subplot(2,2,4)
    plot(Ra_filt,Erreur_Vt,'r','LineWidth',2)
    xlabel('Rayon [mm]','Interpreter','latex')
    ylabel('Erreur [%]','Interpreter','latex')
    title('Erreur de filtrage Vt','Interpreter','latex')
    xlim([0 round(Ra_filt(end)+5)])
    box on;

    saveas(gcf, [RepBase '\Erreurs_Rayons.fig']) % Sauvegarde de la figure

    % Plot du facteur de forme
    figure(1000*LeftRight)
    subplot(1,2,1)
    plot(Ra_filt, Shape_ratio, 'r','LineWidth',2) 
    xlabel('Rayon Ra$_{filt}$ [mm]','Interpreter','latex')
    ylabel('Shape ratio [-]','Interpreter','latex')
    xlim([0 round(Ra_filt(end)+5)])
    box on;

    subplot(1,2,2)
    hold on
    plot(Ra_filt, Roundness,'r','LineWidth',2)
    plot([0 40], [0.99 0.99], 'k--','LineWidth',2)
    hold off
    xlabel('Rayon Ra$_{filt}$ [mm]','Interpreter','latex')
    ylabel('Roundness [-]','Interpreter','latex')
    xlim([0 round(Ra_filt(end)+5)])
    box on;

    saveas(gcf, [RepBase '\Shape_ratio.fig']) % Sauvegarde de la figure

    %Plot du déplacement du centroïd
    figure(10000*LeftRight)
    imagesc(imread([RepBase '\fond.tif']))
    colormap gray
    hold on
    plot(centre_x,centre_y,'r','LineWidth',2)
    plot(centre_x(1),centre_y(1),'gs','MarkerSize',10,'MarkerFaceColor','m')
    text(centre_x(1)*1.02,centre_y(1),'Start','FontSize',10,'Color','r')
    plot(centre_x(end),centre_y(end),'gs','MarkerSize',10,'MarkerFaceColor','m')
    text(centre_x(end)*1.02,centre_y(end),['Stop ' num2str((centre_x(end)-centre_x(1))*Grandissement(LeftRight),'%2.2f') ' mm ' num2str((centre_y(end)-centre_y(1))*Grandissement(LeftRight),'%2.2f') ' mm'],'FontSize',10,'Color','r')
    hold off
    title('Centroïd displacement','Interpreter','latex')
    axis([0 sizex 0 sizey])
    box on;
    saveas(gcf, [RepBase '\Centroid_displacement.fig'])

    % Plot du Froude
    figure(100000*LeftRight)
    plot(Ra_filt(Posrayonmin:Posrayonmax),Froude,'b',LineWidth=2)
    xlabel('Ra [mm]','Interpreter','latex')
    ylabel('Froude Number [-]','Interpreter','latex')
    box on;
    saveas(gcf,[RepBase '\Froude.fig'])

   

    %% SAUVEGARDE DES RESULTATS

    % On conserve uniquement les valeurs comprises dans les rayons limites
    temps = temps(Posrayonmin:Posrayonmax);
    Rp = Rp(Posrayonmin:Posrayonmax);
    Rp_filt = Rp_filt(Posrayonmin:Posrayonmax);
    Ra = Ra(Posrayonmin:Posrayonmax);
    Ra_filt = Ra_filt(Posrayonmin:Posrayonmax);
    Vt = Vt(Posrayonmin:Posrayonmax);
    Vt_filt = Vt_filt(Posrayonmin:Posrayonmax);
    centre_x = centre_x(Posrayonmin:Posrayonmax);
    centre_y = centre_y(Posrayonmin:Posrayonmax);

    disp('### Sauvegarde Rayons et Vitesse ###')
    file = [RepBase '\Resultats_Rp_Ra_Vt.dat'];
    fid = fopen(file, 'w');
    fprintf(fid, 'Temps [ms]\tRp Brut [mm]\tRp Filtré [mm]\tRa Brut [mm]\tRa Filtré [mm]\tVt Brute [m/s]\tVt Filtrée [m/s]'); % Noms des variables sauvegardés pour l'entête
    fprintf(fid,'\n'); % Saut de ligne 
    for k = 1:length(temps)
        fprintf(fid,'%7.5f\t%7.5f\t%7.5f\t%7.5f\t%7.5f\t%7.5f\t%7.5f',temps(k),Rp(k), Ra(k),Rp_filt(k),Ra_filt(k),Vt(k),Vt_filt(k)); % Ecriture des données
        fprintf(fid, '\n'); % Saut de ligne 
    end
    save([RepBase '\Workspace_Rp_Ra_Vt.mat']);
    fclose(fid);
    save([RepBase '\Resultats_Rp_Ra_Vt'], 'temps', 'Rp', 'Ra', 'Rp_filt', 'Ra_filt', 'Vt', 'Vt_filt', 'centre_x', 'centre_y')

    
end

disp('### FIN ###')
