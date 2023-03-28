%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Resolution des modèles pour Vitesse de propagation et longueur de Markstein %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear all
close all
warning off

%% CHOIX DU REPERTOIRE/BASE DE TRAVAIL ET CHARGEMENT DES DONNEES

addpath('./Functions') % Répertoire où sont stockées les fonctions MATLAB
RepBase = uigetdir('C:\Users\noe.monnier\Documents\Post_Proc'); % Répertoire où sont stockées les fichiers du tir
OriginalRepBase = RepBase; % Copie du chemin du répertoire de travail

imagesplit = false; % true si le Schlieren est split
test = true; % true par défaut (contrôle la boucle de coupure)

for LeftRight=2:2 % Images à traiter : 1:1 (gauche) OU 1:2 (gauche et droite) OU 2:2 (droite ou non slipt)

    if LeftRight==1 && imagesplit % Selection de la base de travail pour le Schlieren splité
        RepBase = [OriginalRepBase '\0_Images_Left'];
    elseif LeftRight==2 && imagesplit
        RepBase = [OriginalRepBase '\0_Images_Right'];
    end

%% PREMIERE COUPURE

    load([RepBase '\Resultats_Rp_Ra_Vt']) % Charge des données de rayon et de vitesse issues de radii_Schlieren

    Ra_brut = Ra*10^(-3); % Conversion mm/m
    Ra_filt = Ra_filt*10^(-3); % Conversion mm/m
    temps = temps*10^(-3); % Conversion ms/s
    Etirement = 2*Vt_filt./(Ra_filt); % Calcul de l'étirement 
    
    figure(1)
    plot(Etirement,Vt_filt,'--*g') % Plot de la vitesse en fonction de l'étirement 
    % Si l'étirement est trop grand, réduit les axes pour éviter d'écraser le graphe
    if max(Etirement) > 10^5
        axis([0 Etirement(find(Etirement < max(Etirement), 1, 'first')) min(Vt_filt)*0.95 max(Vt_filt)*1.05]);
    else
        axis([min(Etirement)*0.9 max(Etirement)*1.1 min(Vt_filt)*0.9 max(Vt_filt)*1.1]);
    end
    xlabel('Etirement [1/s]')
    ylabel('Vitesse de propagation [m/s]')
    legend('Données exp')

    % Valeurs pour la première coupure
    prompt = {'Entrer la coupure basse (mm):',['Entrer la coupure haute (< ' num2str(Ra(end)) ' mm)'  ]};
    dlg_title = 'Coupures';
    num_lines = 1;
    def = {'6.5','20'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    rbas = str2double(answer{1}); % Coupure basse
    rhaut = str2double(answer{2}); % Coupure haute
    rmid = rhaut - rbas; % Rayon médian de coupure

    close all
    
    dRmmR(:,1) = sqrt(2).*1e-3./Ra_filt; % Erreur
    Ra_origin(:,1) = Ra_filt - Ra_filt.*dRmmR; % Erreur basse
    Ra_origin(:,2) = Ra_filt; % Rayons filtrés
    Ra_origin(:,3) = Ra_filt + Ra_filt.*dRmmR; % Erreur haute
    temps_origin = temps; % sauvegarde des datas temps
    Vt_origin(:,1) = gradient(Ra_origin(:,1), temps_origin); % Vitesse erreur basse
    Vt_origin(:,2) = Vt_filt; % Vitesse filtrée
    Vt_origin(:,3) = gradient(Ra_origin(:,3), temps_origin); % Vitesse erreur haute
    Etirement_origin(:,1) = 2*Vt_origin(:,1)./Ra_origin(:,1); % Etirement erreur basse
    Etirement_origin(:,2) = Etirement; % Etirement calculé à partir de Vt-filt
    Etirement_origin(:,3) = 2*Vt_origin(:,3)./Ra_origin(:,3); % Etirement erreur haute

    CoupureBasse = find(Ra_origin(:,2) > rbas/1000, 1); % Indice à partir duquel le modèle est calculé
    nbCoupureHaute = length(Ra_origin(:,2)) - find(Ra_origin(:,2) > rhaut/1000, 1); %  Nombre de valeurs a enlever de Ra en haut
    l_coupure = length(Ra_origin(CoupureBasse:end-nbCoupureHaute,2)); % Longueur des vecteurs coupés

    l = 2; % 1 : erreur basse, 2 : Rayons filtrés, 3: erreur haute

    %% PREALOCATION
    Sb0_Lineaire = zeros(1,3);
    Lb_Lineaire = zeros(1,3);
    Sb0_Curvature = zeros(1,3);
    Lb_Curvature = zeros(1,3);
    Sb0_NLineaire = zeros(2,3);
    Lb_NLineaire = zeros(2,3);
    

    %% BOUCLE DE CALCUL     

    while test 
        

        Ra_calc = Ra_origin(CoupureBasse:end-nbCoupureHaute,l); % Rayons pour le calcul 
        temps_calc = temps_origin(CoupureBasse:end-nbCoupureHaute); % Temps pour le calcul
        Vt_calc = Vt_origin(CoupureBasse:end-nbCoupureHaute,l); % Vitesse pour le calcul
        Etirement_calc = Etirement_origin(CoupureBasse:end-nbCoupureHaute,l); % Etirement pour le calcul

        %% CALCUL MODELE LINEAIRE ETIREMENT 
        % Modèle valable pour Lb > 0
        param = [0.75 -0.001 0]; % Initialisation des paramètres (valeurs arbitraires)
        [CP,~,~,~] = fminsearch(@fct_Lineaire,param,optimset('TolFun',1e-20,'MaxIter',10000,'MaxFunEvals',1e9),temps_calc,Ra_calc); % Optimisaltion des paramètres (Sb, Lb, Condition Initiale)
        Sb0 = CP(1); % Vitesse non étirée des gaz brulés
        Lb = CP(2); % Longueur de Markstein
        [TempsDiff,SolutionDiff] = ode45(@(t,r) Sb0/(1+(2*Lb/r)), temps_calc, CP(3)); % Résolution du modèle linéraire à l'aide des paramètres optimisés 
        DiffRayonDiff_L(:,l) = abs(Ra_calc - SolutionDiff); % Erreur entre le modèle linéaire et les rayons exp
        VitesseDiff_L(:,l) = gradient(SolutionDiff, temps_calc); % Calcul de la vitesse à partir de la résolution du modèle linéaire
        EtirementDiff_L(:,l) = 2*VitesseDiff_L(:,l)./SolutionDiff; % Calcul de l'étirement à partir de la résolution du modèle linéaire
        Sb0_Lineaire(l) = Sb0; 
        Lb_Lineaire(l) = Lb; 
        %% CALCUL MODELE LINEAIRE COURBURE
        param = [0.75 -0.001 0]; % Initialisation des paramètres (valeurs arbitraires)
        [CP,~,~,~] = fminsearch(@fct_Curvature,param,optimset('TolFun',1e-20,'MaxIter',10000,'MaxFunEvals',1e9),temps_calc,Ra_calc); % Optimisaltion des paramètres (Sb, Lb, Condition Initiale)
        Sb0 = CP(1); 
        Lb = CP(2);
        [TempsCurv,SolutionCurv] = ode45(@(t,r) Sb0*(1-(2*Lb/r)), temps_calc, CP(3)); % Résolution du modèle linéaire basé sur la courbure
        DiffRayonCurv(:,l) = abs(Ra_calc - SolutionCurv); % Erreur entre le modèle curv et les rayons exp
        VitesseCurv(:,l) = gradient(SolutionCurv, temps_calc); % Calcul de la vitesse à partir du modèle linéaire courbure
        EtirementCurv(:,l) = 2*VitesseCurv(:,l)./SolutionCurv; % Calcul de l'étirement à partir du modèle linéaire courbure
        Sb0_Curvature(l) = Sb0;
        Lb_Curvature(l) = Lb;
        %% CALCUL MODELE NON LINEAIRE ETIREMENT   
        % Modèle NL 
        param = [Sb0 Lb]; % Initialisation des paramètres (valeurs du modèle Linéiare)
        [CP,~,~,~] = fminsearch(@fct_nonlineaire,param,optimset('TolFun',1e-14,'MaxIter',10000,'MaxFunEvals',1e7),Ra_calc,Vt_calc); % Optimisation des paramètres (Sb, Lb)
        Sb0_1 = CP(1); % Vitesse non étirée des gaz brulés  
        Lb_1 = CP(2); % Longueur de Markstein
        decalage = 0; % Initialisation du decalage
        [decal,~,~,~] = fminsearch(@fct_decalage,decalage,optimset('TolFun',1e-14,'MaxIter',10000,'MaxFunEvals',1e7),temps_calc, Ra_calc,Lb,Sb0); % Optimisation du vecteur temps à partir des paramètres (Sb, Lb)
        param = [Sb0_1 Lb_1 decal]; % Paramètres pour l'optimisation du modèle
        [CP,~,~,~] = fminsearch(@fct_optirayon,param,optimset('TolFun',1e-14,'MaxIter',10000,'MaxFunEvals',1e6),temps_calc,Ra_calc); % Optimisation des Rayons à partir des paramètres Rayons, Sb et Lb
        Sb0_2 = CP(1); % Vitesse non étirée des gaz brulés
        Lb_2 = CP(2); % Longueur de Markstein
        C = CP(3); % Décalage temporel
        % x = Sb/Sb_0, utilisé pour le calcul du modèle
        if Lb_2>0
            x = 1/exp(1):0.0001:1;
        else
            x = 1:0.0001:4;
        end
        % Calcul des vecteurs temps et rayon à partir du modèle Non Linéaire et des paramètres optimisés
        rf_recalc(:,l) = -2*Lb_2./(x.*log(x));
        t_recalc(:,l) = real(2*(Lb_2/Sb0_2)*expint((log(x.^2)))-2*(Lb_2/Sb0_2)*(1./(x.^2.*log(x)))+C);
        Vitesse_NL(:,l) = gradient(rf_recalc(:,l), t_recalc(:,l)); % Vitesse étirée à partir des vecteurs recalculés
        Etirement_NL(:,l) = 2.*Vitesse_NL(:,l)./rf_recalc(:,l); % Etirement à partir des vecteurs recalculés
        Sb0_NLineaire(1,l) = Sb0_1;
        Sb0_NLineaire(2,l) = Sb0_2;
        Lb_NLineaire(1,l) = Lb_1;
        Lb_NLineaire(2,l) = Lb_2;
       
        %% CALCUL DES ERREURS ET DISPLAY DES RESULTATS
        if l == 3

            disp('### RESULTATS ###')
            disp(['Coupure Basse = ' num2str(CoupureBasse)])
            disp(['Coupure haute = ' num2str(length(temps_origin) - nbCoupureHaute)])
            disp(['Nombre d images = ' num2str(length(temps_calc))])

            disp('# Modèle Linéaire #')
            disp(['Sb0 = ' num2str(Sb0_Lineaire(2)) ' m/s'])
            disp(['Lb = ' num2str(Lb_Lineaire(2)*1000) ' mm'])

            erreurBL = abs(Sb0_Lineaire(2) - Sb0_Lineaire(1));
            erreurHL = abs(Sb0_Lineaire(3) - Sb0_Lineaire(2));
            erreurL = max(erreurBL, erreurHL)/Sb0_Lineaire(2)*100; % erreur la plus défavorable du modèle linéraire
            disp(['Erreur max = ' num2str(erreurL) ' %'])

            disp('# Modèle Courbure #')
            disp(['Sb0 = ' num2str(Sb0_Curvature(2)) ' m/s'])
            disp(['Lb = ' num2str(Lb_Curvature(2)*1000) ' mm'])

            erreurBC = abs(Sb0_Curvature(2) - Sb0_Curvature(1));
            erreurHC = abs(Sb0_Curvature(3) - Sb0_Curvature(2));
            erreurC = max(erreurBC, erreurHC)/Sb0_Curvature(2)*100;
            disp(['Erreur max = ' num2str(erreurC) ' %'])

            disp('# Modèle Non Linéaire #')
            disp(['Sb0 = ' num2str(Sb0_NLineaire(2,2)) ' m/s'])
            disp(['Lb = ' num2str(Lb_NLineaire(2,2)*1000) ' mm'])

            erreurBNL2 = abs(Sb0_NLineaire(2,2) - Sb0_NLineaire(2,1));
            erreurHNL2 = abs(Sb0_NLineaire(2,3) - Sb0_NLineaire(2,2));
            erreurNL2 = max(erreurBNL2,erreurHNL2)/Sb0_NLineaire(2,2)*100; % erreur la plus défavorable du modèle non linéraire 
            disp(['Erreur max = ' num2str(erreurNL2) ' %'])
            
            test = false; % Fin de la boucle de calcul
        end
        %% PLOT DE LA COURBE VITESSE ET RAFFINEMENT DE LA COUPURE

        if l==1
            l = 3; % Après le calcul de l'erreur basse, calcul de l'erreur haute
        end

        if l==2
            scrsz = get(0,'ScreenSize'); % Taille de la fenêtre
            Im1 = figure('Position',scrsz/1.3);
            hold on
            plot(Etirement,Vt_filt,'g*--');
            plot(Etirement_NL(:,2),Vitesse_NL(:,2),'r*','Markersize',2)
            hold off
            xlabel('Etirement [1/s]');
            ylabel('Vitesse de propagation [m/s]');
            legend('Data Exp', 'Modèle NL');
            axis([Etirement_origin(end,2)*0.9 Etirement_origin(1,2)*1.1 min(Vt_origin(:,2))*0.9 max(Vt_origin(:,2))*1.1]);

            % Raffinement de la coupure 
            h1 = drawpoint(gca, 'Position', [Etirement_calc(1) Vt_calc(1)]);
            text(Etirement_calc(1)+0.2,Vt_calc(1)+0.05,[num2str(rbas,'%2.2f'), ' mm'],'FontSize',10)
            h2 = drawpoint(gca, 'Position', [Etirement_calc(end) Vt_calc(end)]);
            text(Etirement_calc(end)+0.2,Vt_calc(end)+0.05,[num2str(rhaut,'%2.2f'), ' mm'],'FontSize',10)
            
            % Limites de positionnement des points (à revoir)
%             limx = get(gca,'XLim');
%             fcn = makeConstrainToRectFcn('impoint',[EtirementdataOrigin(end) limx(2)],get(gca,'YLim'));
%             setPositionConstraintFcn(h1,fcn);
%             setPositionConstraintFcn(h2,fcn);

            % Message si la coupure basse est trop basse
            if Etirement_calc(1) > max(Etirement_NL(:,2))*2.5
                button = questdlg('La coupure basse est trop basse','Erreur','OK','OK');
            end

            % Validation de la coupure
            button = MFquestdlg([1,0.5], 'La coupure est elle bonne ?','Precision','Oui','Non','Oui');
            switch button
            
            case 'Non'
                
                wait(h1)
                disp('#  Coupure basse OK  #')
                wait(h2)
                disp('#  Coupure haute OK  #')

                xbas = h1.Position; % Coordonées du point bas
                xhaut = h2.Position; % Coordonnées du point haut
                supxbas = find(Etirement_origin(:,2) > xbas(1),1,'last'); % Point le plus proche ayant un étirement supérieur à xbas
                supxhaut = find(Etirement_origin(:,2) > xhaut(1),1,'last'); % Point le plus proche ayant un étirement supérieur à xhaut
                rbas = Ra_origin(supxbas,2); % Correspondance Rayon/Etirement 
                rhaut = Ra_origin(supxhaut,2);
                rmid = rhaut - rbas; % Rayon médian de coupure
                CoupureBasse = find(Ra_origin(:,2) > rbas,1); % Nouvelle coupure basse
                nbCoupureHaute = length(Ra_origin(:,2))-find(Ra_origin(:,2) > rhaut,1); % Nouvelle coupure haute
                rbas = rbas*1e3; % Convertion m/mm pour l'affichage
                rhaut = rhaut*1e3; % Convertion m/mm pour l'affichage

                % Nettoyage des valeurs stockant les résultats des modèles (pour éviter les résidus liés à la taile de la coupure)
                close all
                clear DiffRayonDiff_L VitesseDiff_L EtirementDiff_L 
                clear DiffRayonCurv VitesseCurv EtirementCurv
                clear rf_recalc t_recalc Vitesse_NL Etirement_NL 
            case 'Oui'
                l = 1; % Calcul de l'erreur basse au prochain tour de boucle
                Ra_cut = Ra_brut(CoupureBasse:end-nbCoupureHaute); % Rayons brut pour les fichiers de sortie

                close(Im1)

                %% SAUVEGARDE DES RESULTATS ET DES DONNEES
                disp('### SAUVEGARDE DES RESULTATS ###')
                file = [RepBase '\Out_Sb_calc.dat'];
                fid = fopen(file,'w');
                fprintf(fid,'Temps [s]\tRayon Brut [m]\tRayon Filt [m]\tdt [s]\tSb0 L [m/s]\tLb L [m]\t2LbL/Rmid\tSb0 C [m/s]\tLb C [m]\t2LbC/Rmid\tSb0 NL 1 [m/s]\tLb NL 1 [m]\t2LbNL1/Rmid\tSb0 NL 2 [m/s]\tLb NL 2 [m]\t2LbNL2/Rmid\tCt NL 2');
                fprintf(fid,'\n');
                for j=1:length(Ra_calc)
                    if j==1
                        fprintf(fid,'%9.5f\t%10.10f\t%10.10f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f\t%9.9f',temps_calc(j),Ra_cut(j),Ra_calc(j),temps_origin(2)-temps_origin(1),Sb0_Lineaire(2),Lb_Lineaire(2),2*Lb_Lineaire(2)/rmid,Sb0_Curvature(2),Lb_Curvature(2),2*Lb_Curvature(2)/rmid,Sb0_NLineaire(1,2),Lb_NLineaire(1,2),2*Lb_NLineaire(1,2)/rmid,Sb0_NLineaire(2,2),Lb_NLineaire(2,2),2*Lb_NLineaire(2,2)/rmid,C);
                        fprintf(fid,'\n');
                    else
                        fprintf(fid,'%9.5f\t%10.10f\t%10.10f',temps_calc(j),Ra_cut(j),Ra_calc(j));
                        fprintf(fid,'\n');
                    end
                end
                fclose(fid);
                disp('#   Résultats sauvegardés  #')

                file = [RepBase '\Data_exp.dat'];
                fid = fopen(file, 'w');
                fprintf(fid, 'Temps [s]\tRayon Brut [m]\tRayon Filt [m]\tVitesse Filt [m]\tEtirement [1/s]\tErreur relative R [%%]');
                fprintf(fid, '\n');
                for j=1:length(temps_origin)
                    fprintf(fid, '%9.5f\t%10.10f\t%10.10f\t%10.10f\t%10.10f\t%9.9f',temps_origin(j),Ra_brut(j),Ra_filt(j),Vt_filt(j),Etirement(j),dRmmR(j));
                    fprintf(fid, '\n');  
                end
                fclose(fid);
                disp('# Récap données exp sauvegardé #')

                file = [RepBase '\Data_Lineaire_calc.dat'];
                fid = fopen(file, 'w');
                fprintf(fid, 'Temps L [s]\tRayon L [m]\tVitesse L [m/s]\tEtirement L [1/s]');
                fprintf(fid, '\n');
                for j=1:length(temps_calc)
                    fprintf(fid, '%9.5f\t%10.10f\t%10.10f\t%10.10f',temps_calc(j),SolutionDiff(j),VitesseDiff_L(j,2),EtirementDiff_L(j,2));
                    fprintf(fid, '\n');
                end
                fclose(fid);
                disp('# Données calcul L sauvegardées #')

                file = [RepBase '\Data_Curvature_calc.dat'];
                fid = fopen(file, 'w');
                fprintf(fid, 'Temps C [s]\tRayon C [m]\tVitesse C [m/s]\tEtirement C [1/s]');
                fprintf(fid, '\n');
                for j=1:length(temps_calc)
                    fprintf(fid, '%9.5f\t%10.10f\t%10.10f\t%10.10f',temps_calc(j),SolutionCurv(j),VitesseCurv(j,2),EtirementCurv(j,2));
                    fprintf(fid, '\n');
                end
                fclose(fid);
                disp('# Données calcul Curv sauvegardées #')

                file = [RepBase '\Data_NLineaire_calc.dat'];
                fid = fopen(file, 'w');
                fprintf(fid, 'Temps NL [s]\tRayon NL [m]\tVitesse NL [m/s]\tEtirement NL [1/s]');
                fprintf(fid, '\n');
                for j=1:length(t_recalc)
                    fprintf(fid, '%9.5f\t%10.10f\t%10.10f\t%10.10f',t_recalc(j),rf_recalc(j),Vitesse_NL(j,2),Etirement_NL(j,2));
                    fprintf(fid, '\n');
                end
                fclose(fid);
                disp('# Données calcul NL sauvegardées #')

            end  
        end    
    end

    %% PLOT DES RESULTATS ET SAUVEGARDE DES FIGURES

    Im1 = figure(1);
    set(Im1,'Position',[1 scrsz(4)/4 scrsz(3)/2 scrsz(4)/2])
    hold on
    plot(Etirement_origin(:,2),Vt_origin(:,2),'g*--');
    plot(Etirement_NL(:,2), Vitesse_NL(:,2),'r*','MarkerSize',2)
    plot(EtirementDiff_L(:,2),VitesseDiff_L(:,2),'b','LineWidth',2)
    plot(EtirementCurv(:,2), VitesseCurv(:,2),'m--','LineWidth',2)
    plot(Etirement_origin(CoupureBasse,2),Vt_origin(CoupureBasse,2),'gs','MarkerSize',10,'MarkerFaceColor','m') % 
    plot(Etirement_origin(end-nbCoupureHaute,2),Vt_origin(end-nbCoupureHaute,2),'gs','MarkerSize',10,'MarkerFaceColor','m')
    hold off
    xlabel('Etirement [1/s]')
    ylabel('Vitesse de propagation [m/s]')
    legend('Data exp','Non Lineaire','Lineaire','Courbure','Rmin','Rmax')
    text(Etirement_origin(end,2),Vt_origin(end,2)*1.05,['\fontname{times} S_b^0 = ' num2str(Sb0_NLineaire(2,2)) ' m/s'],'FontSize',14)
    axis([min(Etirement_origin(:,2))*0.9 max(Etirement_origin(:,2))*1.1 min(Vt_origin(:,2))*0.9 max(Vt_origin(:,2))*1.1])
    

    Im2 = figure(2);
    set(Im2,'Position',[scrsz(3)/2 scrsz(4)/4 scrsz(3)/2 scrsz(4)/2])
    hold on
    plot(temps_origin,Ra_origin(:,1),'+g')
    plot(temps_origin,Ra_origin(:,2),'+g')
    plot(temps_origin,Ra_origin(:,3),'+g')
    plot(t_recalc(:,1),rf_recalc(:,1),'b')
    plot(t_recalc(:,2),rf_recalc(:,2),'b')
    plot(t_recalc(:,3),rf_recalc(:,3),'b')
    plot(temps_origin(CoupureBasse),Ra_origin(CoupureBasse,2),'gs','MarkerSize',10,'MarkerFaceColor','m')
    text(temps_origin(CoupureBasse),Ra_origin(CoupureBasse,2)*1.02,[num2str(rbas,'%2.2f'), 'mm'],'FontSize',10)
    plot(temps_origin(end-nbCoupureHaute),Ra_origin(end-nbCoupureHaute,2),'gs','MarkerSize',10,'MarkerFaceColor','m')
    text(temps_origin(end-nbCoupureHaute),Ra_origin(end-nbCoupureHaute,2)*1.02,[num2str(rhaut,'%2.2f'), 'mm'],'FontSize',10)
    hold off
    axis([temps_origin(1) temps_origin(end) Ra_origin(1,2) Ra_origin(end,2)]);
    xlabel('Temps [s]');
    ylabel('Rayon [m]');
    legend('','Data exp','','','Modèle Non Linéaire','','Rmin','Rmax','Location','northwest')

    % Sauvegarde des graphs sous format image
    saveas(Im1,[RepBase '\Sb0_models.fig'])
    saveas(Im2,[RepBase '\Rayons_Temps.fig'])
    save([RepBase '\Workspace_calc_models.mat']) % Sauvegarde des données du calcul



end

disp('### FIN ###')