if (cv2_available()) {
    my_image <- imread("https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png")
    cv2r$cvtColor(my_image, cv2r$COLOR_BGR2HSV)
}
