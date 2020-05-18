#' Python OpenCV wrapper
#' 
#' Access to all cv2 functions and variables without implicte conversion to R
#' 
#' @example inst/examples/cv2r.R
#' 
#' @export
cv2r <- NULL
base64 <- NULL

#' @export
np <- NULL

#' @export
py_to_r <- reticulate::py_to_r

#' @export
r_to_py <- reticulate::r_to_py

#' @export 
`.` <- function(...)  {
    data <- list(...)
    l_ret <- do.call(
        reticulate::tuple, 
        lapply(data, as.integer )
    )
    l_ret
}

cv2r_colors <- character(0)

.onLoad <- function(libname, pkgname) {
    if ( ! file.exists("/usr/bin/python3"))
        stop("cv2r is tested with python3 only!")
    
    Sys.setenv(RETICULATE_PYTHON = "/usr/bin/python3")
    l_cfg <- reticulate::py_discover_config()
    if ( ! grepl(pattern = "python3", l_cfg[1]) ) {
        stop("you must use pyhton3! restart R and reload cv2r")
    }
    
    # load cv2 without convertion and assign it to the package env and GlobalEnv
    cv2r <<- reticulate::import("cv2", convert = F, delay_load = T)
    base64 <<- reticulate::import("base64", convert = F)
<<<<<<< HEAD

=======
    # np <<-     reticulate::import("numpy", convert = F)
    
>>>>>>> 9bae4c56e4425b665daa0e47e52dd45650d5f395
    l_colors <- names(cv2r)
    cv2r_colors <<- l_colors[grepl("^COLOR_", l_colors)]
           
    # Overload reticulate python env to ba able to use R functions from python 
    try({
        py_inject_r(.GlobalEnv)
    })
    
    if ( length(find.package("shiny", quiet = T)) == 1 ) {
        shiny::registerInputHandler("base64img", as.numpy.ndarray.base64img, force = TRUE)
        shiny::registerInputHandler("mp3base64", as.matrix.mp3base64, force = TRUE)
    } else {
        warning("shiny is not installed. Make sure you reload R after shiny installation.")
    }
}

