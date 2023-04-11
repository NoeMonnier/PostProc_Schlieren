%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             DETECTION CONTOURS SCHLIEREN                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
warning off
clc

%% CHOIX DU REPERTOIRE/BASE DE TRAVAIL

addpath('./Functions') % Répertoire où sont stockées les fonctions MATLAB
RepBase = uigetdir('C:\Users\noe.monnier\Documents\Post_Proc'); % Répertoire où sont stockées les vidéos fragmentées
OriginalRepbase = RepBase; % Garde en mémoire le répertoire de travail
softbase = cd();
erosionsize=2;
smfilt=7; % Taille de la mean matrice pour le filtrage médian 

%% PARAMETRES ET PREPARATION 

F = 5000; % Fréquence d'acquisition de la caméra
sizex = 1280; % Hauteur de l'image [pxl] 
sizey = 800; % Largeur de l'image [pxl] 
num_image_deb = 1; % Num de la 1ere image à traiter (sur le nombre total d'images)

imagesplit = false; % Si le Schlieren est slpit : true
splitx = 640; % Coordonnés X où l'image est split

Tronqall = true; % Contrôle de la tronquature (image - background) false si les images sont déjà tronquées

Echelle_Filtre = 0.5;  % Echelle de filtrage pour supprimer le bruit de pixelisation du contour [mm]

map=zeros(100,3); % Color map custom
for intens=1:100
    intfact=0.5;
    map(intens,:)=[((intens-1)/200)^(intfact)^2,((intens-1)/100)^(intfact)^2,((intens-1)/100)^(intfact)^0.6];
end

if imagesplit
    Grandissement(1) = 0.0995; % [mm/pxl] pour l'image de gauche
    Grandissement(2) = 0.0995; % [mm/pxl] pour l'image de droite
else 
    Grandissement = 0.0995;
end

tic 
if imagesplit
    splitimages % Commentaire
end
toc

%% BOUCLE DE CALCUL

for LeftRight = 2:2 % Images à traiter : 1:1 (gauche) OU 1:2 (gauche et droite) OU 2:2 (droite ou non slipt)

    if imagesplit && LeftRight == 1   % Selectionne le dossier des images à traiter en cas de Schlieren splité
        RepBase = [OriginalRepbase '\0_Images_Left'];
    elseif imagesplit && LeftRight == 2
        RepBase = [OriginalRepbase '\0_Images_Right'];
    end

    % Transformer la première image en image de fond
    disp('### La première image devient image de fond ###')
    
    ListeImagesBrut = dir([RepBase '\*.tif']); % Récupère les images brutes dans le répertoire
    premiere = ListeImagesBrut(1,1).name; % Nom de la première image
    FOND = exist([RepBase '\fond.tif'], 'file'); % Existence de l'image de fond

    if FOND==0
        copyfile([RepBase '\' premiere],[RepBase '\fond.tif']); % Créer l'image fond.tif à partir de la première image
        delete([RepBase '\' premiere]); % Efface le doublon première image
    end
    Ifond = im2double(imread([RepBase '\fond.tif'])) ; % Data de l'image de fond

%% PARAMETRES DE TIR ET CREATIONS DES DOSSIERS

    SaveTronq = [RepBase '\1_Images_Tronq'];
    mkdir(SaveTronq);                            % Creation du repertoire images tronquées
    SaveContours = [RepBase '\2_Images_Contour'];  %
    mkdir(SaveContours);                % Création du répertoire images avec contours
    
    ListeImagesBrut = dir([RepBase '\*.tif']); % Liste des images brutes (incluant fond.tif)
    ListeImagesBrut = ListeImagesBrut(2:end); % On retire fond.tif de la liste
    TotalImage = size(ListeImagesBrut,1); % Nombre total des images
    NomBrut = sortrows(char(ListeImagesBrut.name));    % Noms de toutes les images
    Background = imread([RepBase '\fond.tif']);       % Image de fond

%% TRONQUATURE DES IMAGES

    tic 
    if Tronqall
        for i = 1:TotalImage
    
            disp(['Troncature ' NomBrut(i,:) '...']);
            ImageBrute = imread([RepBase '\' NomBrut(i,:)]);
            ImageTronq = (imsubtract(ImageBrute,Background)); % Soustraction du fond 
            imwrite(ImageTronq,[SaveTronq '\Tronq_' num2str(i,'%03.0f') '.tif']); % Sauvegarde de l'image tronquée
        end
    end
    ListeImagesTronq = dir([SaveTronq '\*.tif']);    % Liste des images tronquées
    NomTronq = sortrows(char(ListeImagesTronq.name));  % Nom des images tronquées
    disp('### Troncature effectuée ###')
    toc

%% CALCUL DU SEUIL 

    disp('### Calcul du seuil à partir de la dernière image tronquée ###')
    NameLast = NomTronq(length(NomTronq),:);
    I = im2double(imread([SaveTronq '\' NameLast])); % Dernière image tronquée en double précision
    IF = medfilt2(I, [smfilt smfilt]); % Filtrage médian de la dernière image tronquée taille de la mean matrice : smfilt
    Soriginal = mean(mean(IF))*2^8; % Calcul de la valeur moyenne de IF utilisée comme seuil par défaut (2^16 pour être en niveau de gris sur 16 bits)
    

%% FENETRE DE CONFIRMATION DU SEUIL

    test_seuil = true;
    Coeff = 1.0; % Coefficient correcteur pour le seuil
    Stemp = Soriginal; % Seuil temporaire pour la binarisation
    Stemp = Stemp/(2^8-1); % Seuil absolu pour la binarisation (entre 0 et 1) 2^16 pour 16 bits
    fprintf('Seuil image = %0.03f', Stemp); % Affiche la valeur de seuil trouvée
    ImageBrute10 = imread([RepBase '\' NomBrut(10,:)]); % 10è image brute (choix arbitraire)
    ImageTronq10 = imread([SaveTronq '\' NomTronq(10,:)]); % 10è image tronquée
    ImageBruteLast = imread([RepBase '\' NomBrut(length(NomBrut),:)]); % Dernière image brute
    ImageTronqLast = imread([SaveTronq '\' NameLast]); % Dernière image tronquée

    while test_seuil 
        Stemp = Stemp*Coeff; % Correction du seuil
        IBin10 = imbinarize(ImageTronq10, Stemp); % Binarisation de l'image 10
        IBinLast = imbinarize(ImageTronqLast, Stemp); % Binarisation de la dernière image

        figure(31); % Affichage des images brutes et binarisée 
        subplot(221); imagesc(ImageBrute10); colormap gray; title('Image 10 : Brute'); axis off;
        subplot(222); imagesc(IBin10); title('Image 10 : Seuillée'); axis off; 
        subplot(223); imagesc(ImageBruteLast); title('Dernière Image : Brute'); axis off; 
        subplot(224); imagesc(IBinLast); title('Dernière image : Seuillée'); axis off; 
        pause(3)
        
        button = questdlg('Seuil OK ?','Seuil');
        switch button
            case 'Yes'
                Seuil = Stemp;
                test_seuil = false;
            case 'No'
                Para = inputdlg({'Nouveau coefficient correcteur : '}, 'Coeff', 1.0, {'1.0'});
                Coeff = str2double(Para{1});
            case 'Cancel'
                break
        end     
    end
    close(31)

%% MASQUE POUR LES ELECTRODES

    
    figure, imshow(ImageBruteLast) % Affiche la dernière image brute

    if LeftRight == 2
        load rmask.mat % Charge le masque par défaut pour l'image de droite
        h = drawpolygon(gca,'Position', accepted_pos); % Dessine le masque 
    else
        load lmask.mat % Charge le masque par défaut pour l'image de gauche
        h = drawpolygon(gca, 'Position', accepted_pos); % Dessine le masque
    end
    
    l = drawpolyline(gca, 'Position',[0 365; 640 365]); % Dessine une ligne horizontale pour la position des électrodes
    addlistener(h,'MovingROI',@(src, evt) title(mat2str(evt.CurrentPosition))); % Affiche les coordonnées du masque en titre
    id = addlistener(l,'MovingROI',@(src, evt) title(mat2str(evt.CurrentPosition))); % Affiche les coordonnées de la ligne en titre
    % h.DrawingArea(get(gca,'Xlim'), get(gca,'Ylim')) a revoir
    % l.DrawingArea(get(gca,'Xlim'), get(gca,'Ylim'))
    wait(h); % Confirmation du masque
    disp('### Masque OK ###')
    wait(l); % Confirmation de la ligne
    disp('### Ligne OK ###')
    rawmask = createMask(h); % Création du masque à partir du polygone
    accepted_pos = h.Position;
    accepted_line = l.Position;

    if LeftRight ==1 % Sauvegarde du masque pour les images droites et gauches
        save('lmask.mat','accepted_pos');
    else
        save('rmask.mat','accepted_pos');
    end

    electrodeheight=(accepted_line(1,2)+accepted_line(end,2))/2; % Hauteur de l'électrode dans l'image
    close all

    %% TRAITEMENT DES IMAGES

    tic
    disp('### Début détection des contours ###')
    FI = fspecial('gaussian', 8, 1); % Créer un filtre gaussien passe bas (lisse les contours en supprimant une partie du bruit de binarisation)
    FF = fspecial('gaussian', 5, 1); % 
    se = strel('disk', erosionsize, 4); % Créer un masque disk pour l'érosion et la dilatation
    if LeftRight==1
        sem = strel('disk', 4); % Taille de l'érosion et de la dilatation pour les électrodes
    else
        sem = strel('disk', 8); % Défaut : 6
    end

    parfor i = num_image_deb:TotalImage
        warning off
        disp(['image Brute:..' NomBrut(i,:) '...']);
        ImageBrute = imread([RepBase '\' NomBrut(i,:)]); % Chargement de l'image brute
        ImageTronq = imread([SaveTronq '\' NomTronq(i,:)]); % Chargement de l'image tronquée
        ImageTronq = uint8(conv2(ImageTronq, FI, 'same')); % Convolue l'image traitée avec le filtre gaussien (uint16 pour 16 bits)
        ImageBin = imbinarize(ImageTronq, Seuil); % Binarisation de l'image

        % On rabotte les impuretés externes de l'image seuillée
        dilateIBin = imdilate(ImageBin, se); % Dilatation de l'image avec le masque disk
        erodeIBin = imerode(dilateIBin, se); % Erosion de l'image avec le masque disk, enlève les dernières impuretés de l'image seuillée
        erodeIBin= medfilt2(erodeIBin, [smfilt smfilt]); % Filtrage médian de l'image (lisse le contour) 

        % Plus de dilatation pour remplir l'électrode
        verydilate = imdilate(erodeIBin, sem);
        verydilate = imdilate(verydilate, sem);
        verydilate = imdilate(verydilate, sem); 
        verydilate = imdilate(verydilate, sem);
        verydilate = imdilate(verydilate, sem);
        % On érode la dilatation pour retrouver l'image de base (sans la trace de l'électrode)
        verydilate=imerode(verydilate, sem);
        verydilate=imerode(verydilate, sem);
        verydilate=imerode(verydilate, sem);
        verydilate=imerode(verydilate, sem);
        verydilate=imerode(verydilate, sem);
        
        % Multiplie l'image et le masque pour ne laisser que la zone d'intersection
        dilateIBin2 = verydilate.*rawmask; 

        % Filtrage du masque pour lisser les contours
        electrodemask = conv2(single(cell2mat({dilateIBin2})),FF,'same'); % Filtrage du masque
        electrodemask = imbinarize(electrodemask); % Binarisation du masque 
        electrodemask = imdilate(electrodemask, se); % Petite dilatation pour compenser la perte de surface liée au filtrage

        % Ajout du masque à l'image
        dilateIBin = electrodemask + dilateIBin; 

        ImageRemplie = imfill(dilateIBin,'holes'); % Rempli les trous à l'interieur de l'image
        ImageRemplie = Fct_Structure_Max(ImageRemplie); % Garde la plus grande structure 

        % Detection du contour 
        fig_cont = figure;
        cont = imcontour(ImageRemplie,1); % Detecte le contour
        close(fig_cont);
        X_cont = cont(1,2:end); % Coordonnées X des points du contour
        Y_cont = cont(2,2:end); % Coordonnées Y des points du contour 
        Contour = X_cont -1i * Y_cont; % Paramétrique du contour
        
        % Filtrage du contour
        Contour_filt = Fct_ContourFiltrage(Contour, Echelle_Filtre, Grandissement);
        XcontourFilt = [real(Contour_filt); real(Contour_filt(1))];
        YcontourFilt = [abs(imag(Contour_filt)); abs(imag(Contour_filt(1)))];

        % Réinterpolation du contour filtré
        % Calcul de la distance entre 2 points successifs. 
        % Si l'interpolation est correcte, cette distance doit être égale à 0.5. 
        % Sinon on recommence.
        Contour_filt_int = Contour_filt;
        while ((max(sqrt(diff(real(Contour_filt_int)).^2+diff(imag(Contour_filt_int)).^2))>0.55) && (min(sqrt(diff(real(Contour_filt_int)).^2+diff(imag(Contour_filt_int)).^2))<0.45))
            temp_contour = Contour_filt_int(:)';
            Contour_filt_int = Fct_ContourInterpSpline(temp_contour,1,0.5);
        end
        
        X_filt_int = real(Contour_filt_int); % Coordonnées X du contour filtré interpolé
        Y_filt_int = abs(imag(Contour_filt_int)); % Coordonnées Y du contour filtré interpolé

        % On plot le contour sur l'image brute pour valider manuellement la détection du contour 
        Validation = figure('Visible','off');
        imagesc(ImageBrute); axis equal; title(['Image n°' num2str(i)]); colormap gray; hold on; plot(X_filt_int,Y_filt_int,'r-');
        
        % Largeur des tranches verticales
        width=sum(ImageRemplie,2);
        top=find(width,1,'first'); bot=find(width,1,'last');

        % Sauvegardes 
        % Image brute + contour
        saveas(Validation,[SaveContours '\Image' NomBrut(i,end-6:end-4) '.tif']);
        % Données brutes (contour, filtres ...)
        parsave([SaveContours '\Contour_' NomBrut(i,end-6:end-4)], Contour, Contour_filt, Contour_filt_int, Echelle_Filtre,Grandissement, num_image_deb, F, width, top, bot, electrodeheight);
        % Image pour animation
        ImageAnim = figure('Visible','off');
        imagesc(ImageBrute-Seuil); axis equal; title(['Image n°' num2str(i)]); colormap(map); hold on; plot(X_filt_int,Y_filt_int,'r-','LineWidth',1.5)        
        saveas(ImageAnim,[SaveContours '\Movie' NomBrut(i,end-6:end-4) '.tif']);
       
    end
    toc
end

disp('### Détection des contours finie ###')
