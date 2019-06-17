# cv2r
Use OpenCV in RStudio 

cv2r let me use OpenCV directly in RStudio.
All it does is to import cv2 from python through reticulate and overload imshow so that the output can be visualised in the Viewer pane.
It also provide a minimal intagration with shiny through cv2Output, renderCv2 and inputCv2Cam
You can also quickly capture an image with capture()

See inst/doc folder for more details
