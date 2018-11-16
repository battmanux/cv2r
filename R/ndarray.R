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

#' Subset numpy.ndarray from R
#'
#' Caution, this function uses R index counting style : first elemnt at id 0!
#'
#' @param mat matrice to subset
#' @param axe1 axe 1
#' @param axe2 axe 2
#' @param axe3 axe 3
#' @param env  where to find variables parameters evaluation
#'
#' @return numpy.ndarray subset
#' @export
#'
#' @examples
#' 
#' my_image <- imread("https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png")
#' plot(my_image[1:100,1:100,])
#' imshow("Red",my_image[,,3])
#' 
#' 
`[.numpy.ndarray` <- function(mat, axe1, axe2, axe3, env = parent.frame()) {
    
    shift_by_one <- function(x) {
        xd <- deparse(x) 
        
        if (grepl(pattern = ":", x = xd) ) {
            
            l_args <- unlist(strsplit(xd, ":"))
            paste0(lapply(
                seq_along(l_args),
                function(i) as.integer(eval(parse(text = l_args[[i]]), envir = env))-ifelse(i==1,1,0)
                ), collapse =  ":")
        }
        else
            as.character(as.integer(x)-1)
    }

    if ( missing(axe1) )
        l_a1 <- ':'
    else
        l_a1 <- shift_by_one(substitute(axe1))
    
    if ( missing(axe2) )
        l_a2 <- ':'
    else
        l_a2 <- shift_by_one(substitute(axe2))
    
    if ( missing(axe3) )
        l_a3 <- ':'
    else
        l_a3 <- shift_by_one(substitute(axe3))
    
    main <- reticulate::import_main(convert = F)
    main[["_r_tmp_mat"]] <- mat
    reticulate::py_eval(paste0("_r_tmp_mat[",l_a1,",",l_a2,",",l_a3,"]"), convert = F)
}