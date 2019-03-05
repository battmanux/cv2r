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

extend.shape <- function(a, b) {
    if ( a$shape == b$shape ) {
        l_out <- b
    } else {
        if ( a$shape[0] == b$shape[0] && a$shape[1] == b$shape[1] ) {
            l_out <- a$copy()
            
            if ( length(a$shape) == 3 && length(b$shape) == 2)  {
                
                for ( i in seq_len(py_to_r(a$shape[2]) )) {
                    l_out[,,i] <- b
                }
                
            } else if ( length(a$shape) == 2 && length(b$shape) == 3 ) {
                
                warning("Only first layer is used in mathematical operation")
                l_out <- b[,,1]
                
            } else if ( length(a$shape) == 3 && length(b$shape) == 3 && a$shape[2] > b$shape[2]) {
                
                for ( i in seq_len(py_to_r(a$shape[2]))) {
                    warning("Only first layer is used in mathematical operation")
                    l_out[,,i] <- b[,,1]
                }
                
            } else {
                stop("unable to fit mat shapes:",
                     as.character(a$shape),
                     " -> ", 
                     as.character(b$shape))
            }
            
        } else {
            stop("unable to fit mat shapes:",
                 as.character(a$shape),
                 " -> ", 
                 as.character(b$shape))
        }
    }
    return(l_out)
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
`*.numpy.ndarray` <- function(a, b) {
      # This is an optimisation for masks
      if ( a$dtype == "bool" && !(inherits(b, "numpy.ndarray") && b$dtype == "bool") ) a <- a$astype('uint8')
      
      if ( is.numeric(b) ) {
        if ( as.integer(b) == as.numeric(b) ) {
          np <- reticulate::import("numpy", convert = F)
          b <- np$uint0(b)
        }
            
        l_out <- a$`__mul__`(b)
        
    } else if (inherits(b, "numpy.ndarray")) {
        b <- extend.shape(a, b)
        np <- reticulate::import("numpy", convert = F)
        l_out <- np$multiply(a,b)
    }
    
    attr(l_out, "colorspace") <- cvtColor(a)
    l_out
} 

#' @export
`&.numpy.ndarray` <- function(a, b) reticulate::import("numpy", convert = F)$multiply(a,b)

#' @export
`|.numpy.ndarray` <- function(a, b) reticulate::import("numpy", convert = F)$bitwise_or(a,b)


#' @export
`/.numpy.ndarray` <- function(a, b) {
    if ( is.numeric(b) ) {
      if ( as.integer(b) == as.numeric(b) ) {
        np <- reticulate::import("numpy", convert = F)
        b <- np$uint0(b)
      }
      l_out <- a$`__div__`(b)
        
    } else if (inherits(b, "numpy.ndarray")) {
        b <- extend.shape(a, b)
        l_out <- a$`__div__`(b$astype(a$dtype))
    }
    
    attr(l_out, "colorspace") <- cvtColor(a)
    l_out
} 

#' @export
`+.numpy.ndarray` <- function(a, b) {
  # This is an optimisation for masks
  if ( a$dtype == "bool" && !(inherits(b, "numpy.ndarray") && b$dtype == "bool") ) a <- a$astype('uint8')
  
  if ( is.numeric(b) ) {
    if ( as.integer(b) == as.numeric(b) ) {
      np <- reticulate::import("numpy", convert = F)
      b <- np$uint0(b)
    }
    l_out <- a$`__add__`(b)
      
  } else if (inherits(b, "numpy.ndarray")) {
      b <- extend.shape(a, b)
      np <- reticulate::import("numpy", convert = F)
      l_out <- np$add(a,b)
  } else {
      l_out <- a
  }

    attr(l_out, "colorspace") <- cvtColor(a)
    l_out
} 

#' @export
`-.numpy.ndarray` <- function(a, b) {
    if ( is.numeric(b) ) {
      if ( as.integer(b) == as.numeric(b) ) {
        np <- reticulate::import("numpy", convert = F)
        b <- np$uint0(b)
      }
      l_out <- a$`__sub__`(b)
        
    } else if (inherits(b, "numpy.ndarray")) {
        b <- extend.shape(a, b)
        l_out <- a$`__sub__`(b$astype(a$dtype))
    }
    
    attr(l_out, "colorspace") <- cvtColor(a)
    l_out
} 


#' @export
`!.numpy.ndarray` <- function(a) {
    l_out <- a$`__neg__`()
    attr(l_out, "colorspace") <- cvtColor(a)
    l_out
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
