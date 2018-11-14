.onLoad <- function(libname, pkgname) {
    
    reticulate:::ensure_python_initialized()
    
    # load cv2 without convertion and assign it to the package env and GlobalEnv
    cv2 <- reticulate::import("cv2", convert = F)
    assign("cv2", cv2, pos = parent.env(environment()) )
    .GlobalEnv$cv2 <- cv2
    
    # Overload reticulate python env to ba able to use R functions from python 
    py_inject_r(.GlobalEnv)
}
