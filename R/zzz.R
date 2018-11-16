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
cv2r <- new.env()

.onLoad <- function(libname, pkgname) {
    
    reticulate:::ensure_python_initialized()
    
    # load cv2 without convertion and assign it to the package env and GlobalEnv
    l_cv2 <- reticulate::import("cv2", convert = F)
    
    #assign("cv2", l_cv2, pos = .GlobalEnv) 
    
    lapply(
        names(l_cv2), 
        function(x) assign(
            x, 
            reticulate:::`$.python.builtin.module`(l_cv2, x),
            pos = cv2r )
    )
           
    # Overload reticulate python env to ba able to use R functions from python 
    py_inject_r(.GlobalEnv)
    
    
    if ( length(find.package("shiny", quiet = T)) == 1 ) {
        shiny::registerInputHandler("base64img", base64img2ndarray, force = TRUE)
    } else {
        warning("shiny is not installed. Make sure you reload R after shiny installation.")
    }
}

