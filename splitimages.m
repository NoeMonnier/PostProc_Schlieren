%%%%%
% This code splits images along a vertical line
%%

disp('splitting images');
Listrawimages = dir([RepBase '/*.tif']);    % Recherche des images dans le répertoire


% Name of left and right image directories
SaveLeft = [RepBase '/0_Images_Left']; 
SaveRight = [RepBase '/0_Images_Right'];

% Delete old versions
OldLeft = exist([SaveLeft] , 'file') ;
    if OldLeft == 7
        rmdir([SaveLeft],'s');
        rmdir([SaveRight],'s');
    end

% Create empty directories
% mkdir(SaveLeft);                           
mkdir(SaveRight);                            

parfor i=1:skip:length(Listrawimages)
    rawimage = im2double(imread([RepBase '/' Listrawimages(i,1).name])) ;   %Reading origninal image
    %Crop images
    leftimage=rawimage(:,1:splitx);                                        
    rightimage=rawimage(:,splitx:sizex);
    %Flip images
    leftimage=flipud(leftimage);
    rightimage=flipud(rightimage);
    %Save new images
%     eval(['
%         imwrite(leftimage,[SaveLeft '/split_' num2str(i,'%03.0f') '.tif']);   % changer le nombre de chiffre ici (i,'%03.0f'), pour plus d images   
%     eval(['
        imwrite(rightimage,[SaveRight '/split_' num2str(i,'%03.0f') '.tif']);  
    
end