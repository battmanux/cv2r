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
#' @example inst/examples/plot.R
#'  
#' 
`[.numpy.ndarray` <- function(mat, axe1, axe2, axe3, env = parent.frame()) {
    
    l_cspace <- attr(mat, "colorspace")
    
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
    l_out <- reticulate::py_eval(paste0("_r_tmp_mat[",l_a1,",",l_a2,",",l_a3,"]"), convert = F)
    
    # If shape was reduced due to selection, tranform to grey
    if ( length(l_out$shape) == 2) 
        l_cspace <- "GREY"
    
    attr(l_out, "colorspace") <- l_cspace
    
    l_out
}

#' @export
str.numpy.ndarray <- function(x) {
    str(reticulate::py_to_r(x))
}

#' @export
summary.numpy.ndarray <- function(x) {
    summary(reticulate::py_to_r(x))
}

#' @export
`[<-.numpy.ndarray` <- function(mat, axe1, axe2, axe3, value) {
    param = list(mat=mat)
    if (!missing(axe1) ) param$axe1 <- axe1
    if (!missing(axe2) ) param$axe2 <- axe2
    if (!missing(axe3) ) param$axe3 <- axe3
    x <- do.call(cv2r:::`[.numpy.ndarray`, param)
    if (is.numeric(value)) {
        x$fill(value)
    } else {
        np <- reticulate::import("numpy")
        np$copyto(x, value)
    }
        
    return(mat)
} 

#' @export
`==.numpy.ndarray` <- function(a, b) a$`__eq__`(b)

#' @export
`<=.numpy.ndarray` <- function(a, b) a$`__le__`(b)

#' @export
`>=.numpy.ndarray` <- function(a, b) a$`__ge__`(b)

#' @export
`<.numpy.ndarray` <- function(a, b) a$`__lt__`(b)

#' @export
`>.numpy.ndarray` <- function(a, b) a$`__gt__`(b)

#' @export
`!=.numpy.ndarray` <- function(a, b) a$`__ne__`(b)

#' @export
mean.numpy.ndarray <- function(x) x$mean()

#' @export
max.numpy.ndarray <- function(x) x$max()

#' @export
min.numpy.ndarray <- function(x) x$min()

#' @export
median.numpy.ndarray <- function(x) median(reticulate::py_to_r(x))

#' @export
sd.numpy.ndarray <- function(x) x$std()

#' @export
hist.numpy.ndarray <- function(x, ...) { hist(reticulate::py_to_r(x, ...)) }

#' @export
as.data.table.numpy.ndarray <- function(x) { 
    l_ret <- data.table::melt(reticulate::py_to_r(x)) 
    names(l_ret) <- c(c("x", "y", "layer")[seq_len(length(l_ret)-1)], "value")
    setDT(l_ret)
    l_ret
    }

#' @export
as.data.frame.numpy.ndarray <- function(x) { 
    l_ret <- data.table::melt(reticulate::py_to_r(x)) 
    names(l_ret) <- c(c("x", "y", "layer")[seq_len(length(l_ret)-1)], "value")
    l_ret
}
