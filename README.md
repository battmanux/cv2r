# cv2r
Use OpenCV in RStudio 

cv2r let me use OpenCV directly in RStudio.
All it does is to import cv2 from python through reticulate and overload imshow so that the output can be visualised in the Viewer pane.
It also provide a minimal intagration with shiny through cv2Output, renderCv2 and inputCv2Cam

Plan: 
- imshow shall display the image in Viewer
- expose componants for shiny : cv2Output, renderCv2
- overload VideoCapture(0) to request the webcam through the webbrowser in Rstudio Server
- add a inputCv2Cam componant for shiny that stream the webcam to the server