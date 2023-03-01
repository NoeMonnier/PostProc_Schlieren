# PostProc_Schlieren
A post processing code written in MATLAB to calculate laminar burning velocity base on high framerate schlieren videos

User guide : 

Step 1 : VideoProcess.m

Input:
- RepBase : path to the folder where videos are stocked (string)
Output:
- tir_X : folders containing each video sliced into single images.

This first code split video into single frames. Once the input is correct run the code and select the
correct folder. Then remove images without flame except the last before flame, remove images
where the flame is too distorted or exit the frame.

Step 2 : Detection_Contours_Schlieren.m

Input:
- RepBase : path to the folder where videos are stocked (string)
- skip : skip length for the processing, 1 by default to process all images, 2 for processing every other image ... (integer)
- erosionsize : size of the erosion structure for the image processing , 2 by default (integer)
- smfilt : size of the mean matric for mean filtering, 7 by default (integer)
- F : acquisition frequency of the camera in fps (integer/double)
- sizex and sizey : resolution of the camera in pixels (integers)
- num_image_debut : 1st image to process (integer)
- imagesplit : true in case of a double Schlieren, false by default (logic)
- splitx : X coordinate where images are split, in pixel (integer)
- Tronqall : true for images not already truncated, false otherwise (logic)
- Echelle_Filtre : scale of the gaussian filter used to filter contours, 0.5 by default (double)
- Grandissement : ratio mm/pixel for the images (double)
Output:
- 1_Images_Tronq : a folder containing the truncated images
- 2_Images_Contour : a folder containing the contour data for each image, images with the contour drawn for validation and images with a custom colour map for video assembly

This code binarizes, filters and detects the flame on every image processed. Once the inputs are
correct run the code and select the correct folder containing the images from VideoProcess.m . On
the first popup window check if the filter’s threshold is ok : if the flame is smooth for the 10th and last
images click “Yes” otherwise click “No” and use the coefficient to adjust the threshold. On the second
popup window adjust the mask on the electrodes, be sure to take all the electrodes. Once the mask
is in place double click on it to validate then place the horizontal line on the bottom of the electrodes
and double click to validate. After the code finished check 2_Images_Contour if all the contours are
correctly detected.

Step 3 : radii_Schlieren.m

Input :
- RepBase : path to the folder where videos are stocked (string)
- Rayon_min_traite : minimal radius used for calculation (double)
- Rayon_max_traite : maximal radius used for calculation (double)
- F : acquisition frequency of the camera in fps same as Detection_Contours_Schlieren.m (integer/double)
- skip : skip length for the processing, same as Detection_Contours_Schlieren.m (integer)
- largeur : size of the gradient scheme used for calculation, 1 by default (integer)
- imagesplit : true in case of a double Schlieren, false by default, same as Detection_Contours_Schlieren.m (logic)
Output :
- Evolution_rayons.fig : MATLAB figure showing the temporal evolution of radii used to compare the different models.
- Evolution_Vt.fig : MATLAB figure showing propagation speed depending on the flame radius. Used to check the results and the filtering.
- Resultats_Rp_Ra_Vt.mat : MATLAB save file containing speed and radii data, used in the next step
- Resultats_Rp_Ra_Vt.dat : text file containing speed and radii data, used for external post processing
- Workspace_Rp_Ra_Vt.mat : MATLAB save file containing all workspace data

This third code computes radii and speed of the flame during its propagation. The radii and speeds
are filtered to eliminate camera noise. Once the inputs are correct run the code and select the
correct folder containing the images from VideoProcess.m

Step 4 : Resolution_Modeles.m

Input :
- RepBase : path to the folder where videos are stocked (string)
- imagesplit : true in case of a double Schlieren, false by default, same as Detection_Contours_Schlieren.m (logic)
Output :
- Sb0_models.fig : MATLAB figure showing the fitting of each models on the experimental data. Used to check the results.
- Rayons_Temps.fig : MATLAB figure showing the temporal evolution of radii (experimental and models). Use to check the cutting points.
- Out_Sb_calc.dat : text file containing the computing output for each models : time, radii, speed, Markstein length.
- Data_exp.dat : text file containing the experimental data used for the calculation
- Data_Lineaire_calc.dat : text file containing the data for the linear model calculation
- Data_NLineaire_calc.dat : text file containing the data for the non linear model calculation

This final code computes the unstretched laminar flame speed with the resolution of different
models. Once the inputs are correct run the code and select the correct folder containing the images
from VideoProcess.m . On the first popup window select radii values for the first cut (6.5-25 by
default), be careful to respect the limit for the upper cutting point. If the cut is good click “Oui”,
otherwise click “Non” and move the dots on the popup window, double click on a dot to validate its
position. The final results are displayed on screen and in the console