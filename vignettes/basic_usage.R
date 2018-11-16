## ------------------------------------------------------------------------
library(cv2r)

img_url <- "https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png"

my_image <- imread(img_url)

# Very simple to plot images
imshow(mat=my_image)

## ------------------------------------------------------------------------

# Lets show the alpha mask
imshow(mat=my_image[,,4])

## ------------------------------------------------------------------------
# To use advances matrix subseting you shall convert the matrix to R 
my_r_image <- reticulate::py_to_r(my_image)
imshow(mat=my_r_image[50:300,200:900,c(4,2,2)])

