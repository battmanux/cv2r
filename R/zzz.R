.onLoad <- function(libname, pkgname) {
    cv2 <- reticulate::import("cv2", convert = F)
    assign("cv2", cv2, pos = parent.env(environment()) )
    
}
