clc
clear all;
close all;
warning off;

%% REPERTOIRE ET BASE DE TRAVAIL

RepBase = uigetdir('C:\Users\noe.monnier\Documents\Post_Proc'); % Répertoire où sont stockés les vidéos
structvideofile = dir([RepBase '\*.avi']); % s contient les informations sur les fichiers de RepBase
video_list = {structvideofile.name}'; % Nom des différentes vidéos

%% PROCESS

disp('### Découpage des vidéos ###')
for k = 1:length(video_list)
    cd(RepBase)
    video_char = char(video_list(k));
    disp(['#  Découpage ' video_char '  #'])
    VideoDecomp = VideoReader(video_char);
    folder_name=['tir_',num2str(k)];
    NFrames = round(VideoDecomp.FrameRate*VideoDecomp.Duration);
    
    % Sauvegarde
    outputFolder = fullfile(cd, folder_name);
    mkdir(outputFolder);

    for i = 1:NFrames
        % Lecture de chaque image
        Img = readFrame(VideoDecomp);

        % Sauvegarde au format tif 
        Img_name=['tir',num2str(i,'%03.0f'),'.tif'];
        cd(outputFolder);
        imwrite(Img,Img_name);
    end
end

disp('###          FIN         ###')

