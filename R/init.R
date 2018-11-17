#' Tests if OpenCV is available on the system.
#'
#' Returns TRUE if the python `cv2` library is installed. If the function
#' returns FALSE, but you believe `cv2` is installed, then see
#' [use_python] to configure the python environment
#' 
#' @param silent   logical. Should warning message be displayed
#'                 if the result is false.
#'
#' @export
#' @return Logical
#' 
cv2_available <- function(silent = FALSE){
    msg <- ""
    collapse <- function(...) paste(..., sep = "\n")
    if(!reticulate::py_available(initialize = TRUE))
        msg <- collapse(msg, "python not available")
    else if(!reticulate::py_numpy_available())
        msg <- collapse(msg, "numpy  not available")
    
    
    # need to load numpy for this to work
    if (msg == "") {
        temp <- reticulate::import("numpy", convert = FALSE)
    }
    
    if(!reticulate::py_module_available("cv2"))
        msg <- collapse(msg, "cv2 not available")
    
    if(msg != ""){
        if (!silent) {
            message(msg, "\n",
                    "See reticulate::use_python('opencv') or reticulate::use_python('opencv-python') to set python path, ", "\n",)
        }
        FALSE
    } else TRUE
}

#' Install opencv 
#' 
#' Thisi is usefull if you do not have opencv installed yet
#'
#' @param method auto
#' @param conda auto
#'
#' @export
#'
install_opencv <- function(method = "auto", conda = "auto") {
    reticulate::py_install("opencv", method = method, conda = conda)
}
