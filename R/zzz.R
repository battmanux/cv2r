#' Python OpenCV wrapper
#' 
#' Access to all cv2 functions and variables without implicte conversion to R
#' 
#' @examples
#' 
#' my_image <- imread("https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png")
#' cv2r$cvtColor(my_image, cv2r$COLOR_BGR2HSV)
#' 
#' @export
cv2r <- NULL

.onLoad <- function(libname, pkgname) {
    
    # load cv2 without convertion and assign it to the package env and GlobalEnv
    cv2r <<- reticulate::import("cv2", convert = F, delay_load = T)
           
    # Overload reticulate python env to ba able to use R functions from python 
    try({
        py_inject_r(.GlobalEnv)
    })
    
    if ( length(find.package("shiny", quiet = T)) == 1 ) {
        shiny::registerInputHandler("base64img", base64img2ndarray, force = TRUE)
    } else {
        warning("shiny is not installed. Make sure you reload R after shiny installation.")
    }
}

