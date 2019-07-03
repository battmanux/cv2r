

shift_by_one <- function(x, env) {
  xd <- deparse(x)
  
  if (xd == "\":\"") {
    l_ret <- ":"
  } else if (grepl(pattern = "^[0-9]*:[0-9]*$", x = xd) ) {
    # Faster version
    l_ret <- paste(collapse  = ":", as.integer(strsplit(xd, ":")[[1]]) - 1)  
    
    
  } else if (grepl(pattern = ":", x = xd) ) {
    
    l_args <- unlist(strsplit(xd, ":"))
    l_ret <- paste0(lapply(
      seq_along(l_args),
      function(i) as.integer(eval(parse(text = l_args[[i]]), envir = env))-ifelse(i==1,1,0)
    ), collapse =  ":")
  }
  else
    l_ret <- as.character(as.integer(x)-1)
  
  return(l_ret)
}

#' Efficient way to crop image
#' Same thing but faster than mat[axe1_from:axe1_to,]
#' 
#' @param mat Image
#' @param axe1_from  coordinates
#' @param axe1_to coordinates
#' @param axe2_from coordinates
#' @param axe2_to coordinates
#' @param axe3_from coordinates
#' @param axe3_to coordinates
#'
#' @return
#' @export
#'
#' @examples
crop <- function(mat, axe1_from, axe1_to, axe2_from, axe2_to, axe3_from, axe3_to) {
  if (missing(axe1_from) ) axe1_from <- ''  else axe1_from <- as.integer(axe1_from)
  if (missing(axe1_to) )   axe1_to <- ''    else axe1_to   <- as.integer(axe1_to)
  if (missing(axe2_from) ) axe2_from <- ''  else axe2_from <- as.integer(axe2_from)
  if (missing(axe2_to) )   axe2_to <- ''    else axe2_to   <- as.integer(axe2_to)
  if (missing(axe3_from) ) axe3_from <- ''  else axe3_from <- as.integer(axe3_from)
  if (missing(axe3_to) )   axe3_to <- ''    else axe3_to   <- as.integer(axe3_to)
  
  main <- reticulate::import_main(convert = F)
  main[["_r_tmp_mat"]] <- mat
  
  if ( length(mat$shape) == 3 &&  mat$shape[2] > 1 )
    axe3 <- paste0(", ",axe3_from, ":", axe3_to)
  else
    axe3 <- ""
  
  l_out <- reticulate::py_eval(paste0(
    "_r_tmp_mat[",
        axe1_from,":",axe1_to,
    ",",axe2_from,":",axe2_to,
    axe3,
    "]"), 
    convert = F)
  
}


#' Subset numpy.ndarray from R
#'
#' Caution, this function uses R index counting style : first elemnt at index 1
#' use crop function if you need performances
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
    
    if ( missing(axe1) )
      l_a1 <- ':'
    else
      l_a1 <- substitute(axe1)
    
    if ( missing(axe2) )
      l_a2 <- ':'
    else
      l_a2 <- substitute(axe2)
    
    if ( missing(axe3) )
      l_a3 <- ':'
    else
      l_a3 <- substitute(axe3)
    
    l_a1 <- shift_by_one(l_a1, env)
    l_a2 <- shift_by_one(l_a2, env)
    l_a3 <- shift_by_one(l_a3, env)

    if ( ! ( length(mat$shape) == 3 &&  mat$shape[2] > 1 ) )
      l_a3 <- ""
    
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
    attr(x = l_ret, which = "colorspace") <- attr(x = x, which = "colorspace")
    l_ret
    }

#' @export
as.data.frame.numpy.ndarray <- function(x) { 
    l_ret <- data.table::melt(reticulate::py_to_r(x)) 
    names(l_ret) <- c(c("x", "y", "layer")[seq_len(length(l_ret)-1)], "value")
    attr(x = l_ret, which = "colorspace") <- attr(x = x, which = "colorspace")
    l_ret
}

#' @export
as.image <- function(df, x.name = "x", y.name = "y", layer.name ="layer", value.name = "value" ) {
    if ( layer.name %in% names(df) ) {
        setDT(df)
        l_filter <- unique(df[,get(layer.name)]) 
        l_mat <- array(0, dim = c(max(df[[x.name]]),max(df[[y.name]]),length(l_filter)))
        for ( l in l_filter) {
            l_f <-   dcast(df[get(layer.name)==l,.(x,y,value=get(value.name))], x ~ y, fill = 0)
            l_f[,x := NULL]
            l_mat[,,l] <- as.matrix(l_f)   
        }
        
    } else {
        l_mat <- as.matrix(dcast(df, x ~ y, value.var = value.name ))   
    }

    l_ret <- reticulate::np_array(data = l_mat, dtype = "uint8")
    attr(x = l_ret, which = "colorspace") <- attr(x = df, which = "colorspace")
    l_ret
}
