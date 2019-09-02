#' Python OpenCV wrapper
#' 
#' Access to all cv2 functions and variables without implicte conversion to R
#' 
#' @example inst/examples/cv2r.R
#' 
#' @export
cv2r <- NULL
base64 <- NULL
np <- NULL

cv2r_colors <- character(0)

.onLoad <- function(libname, pkgname) {
    
    # load cv2 without convertion and assign it to the package env and GlobalEnv
    cv2r <<- reticulate::import("cv2", convert = F, delay_load = T)
    base64 <<- reticulate::import("base64", convert = F)
    # np <<-     reticulate::import("numpy", convert = F)
    
    l_colors <- names(cv2r)
    cv2r_colors <<- l_colors[grepl("^COLOR_", l_colors)]
           
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

