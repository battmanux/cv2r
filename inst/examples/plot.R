if ( cv2_available()) {
    my_image <- imread("https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png")
    
    print(my_image)
    
    plot(my_image[1:100,1:100,])
    
    imshow("Red",my_image[,,3])
    
}
