#' Overload of OpenCV imread.
#' 
#' It allows to open a file or an url
#'
#' @param filename local filepath or url
#' @param flags 
#' >0 Return a 3-channel color image. (CV_LOAD_IMAGE_[ANYDEPTH|COLOR|GRAYSCALE])
#' =0 Return a grayscale image.
#' <0 Return the loaded image as is (with alpha channel).
#' 
#' @return numpy.ndarray that can be displayed with plot()
#' 
#' @export
#'
#' @example inst/examples/plot.R
#' 
imread <- function(filename, flags=-1L) {
    
    if ( grepl("^https?://.*", x = filename) ) {
        l_tmpfile <- tempfile(fileext = ".bin")
        curl::curl_download(filename, l_tmpfile)
    } else {
        # This allows ~/doc and ../doc
        l_tmpfile <- normalizePath(filename)
    }
        
    l_out <- cv2r$imread(l_tmpfile, flags)
    
    if (length(l_out$shape) == 3)
        attr(l_out, "colorspace") <- "BGR"
    else
        attr(l_out, "colorspace") <- "GRAY"
    
    l_out
}


#' Overload of OpenCV imshow to make it compatible with RStudio server and Shiny
#'
#' @param winname Image identifyer
#' @param mat image data structure to show
#' @param scale Scale factor on client size (does not affect bandwidth)
#' @param render_max_w make sure we do not send too much pixels over http  
#' @param render_max_h make sure we do not send too much pixels over http 
#' @param keep_shape keep aspect ratio when resizing according to render_max_w|h (default TRUE)
#'
#' @return r2d3 object
#' @export
#'
#' @example inst/examples/plot.R
#' 
imshow <- function(winname="default", mat, 
                   render_max_w = 1000, render_max_h = 1000, 
                   keep_shape = T, scale = 1.0,
                   backgroundcolor, use_svg=FALSE) {
    
    
    if ( inherits(mat, "base64img") ) {
        l_b64img <- mat
    } else {
        l_b64img <- as.base64img(mat = mat,
                                 render_max_w = render_max_w, 
                                 render_max_h = render_max_h, 
                                 keep_shape = keep_shape,
                                 scale = scale )   
    }
    
    
    if (use_svg == TRUE) {
        l_data <- list(
            list(id=runif(1), winname=winname, scale = scale, type=l_b64img$type, data=l_b64img$data) 
        )
        
        l_out <- r2d3::r2d3(data=l_data, script = system.file("simple_png_view.js", package = "cv2r"))
        
        # transparent background
        if (missing(backgroundcolor)) {
            l_out$x$theme$runtime$background <- NULL
            l_out$x$theme$default$background <- NULL
        } else {
            l_out$x$theme$runtime$background <- backgroundcolor
            l_out$x$theme$default$background <- backgroundcolor
        }
    } else {
        l_out <- plot( l_b64img )
    }
    
    # knitr does not call print from a python chunk
    if ( "options" %in% names(sys.frames()[[1]]) &&
         sys.frames()[[1]]$options$engine == "python") {
        print(l_out)
    } else {
        l_out
    }
}


# convert base64 string into an OpenCV Mat (numpy.ndarray)
#
# @param data base64 string
# @param ... 
#
# @return
#'@export
as.numpy.ndarray.base64img <- function(base64img, ...) {

    if (is.null(names(base64img)) ||  !"data" %in% names(base64img))
        return(NULL)
  
    np <- reticulate::import("numpy", convert = F)
    l_array <- base64enc::base64decode(base64img$data)
    l_array <- np$frombuffer(l_array, dtype = np$uint8)  
    l_mat <- cv2r$imdecode(l_array, -1L)
    attr(l_mat, "colorspace") <- "BGR"
    return(l_mat)
}

#' @export 
as.base64img <- function(mat, 
                      render_max_w = 1000, render_max_h = 1000, 
                      keep_shape = T, scale = 1.0) {
    
    # Clean input types
    
    # prototype is compatible with python, but fix most frequent mistake
    if (missing( mat )) {
        mat <- winname
        winname <- "default"
    }
    
    # convert data.table to image
    if ( inherits(mat, "data.frame" ) ) {
        mat <- as.image(mat)
    }
    
    # Convert from not displayable types
    if ( inherits(mat, "array" ) || inherits(mat, "matrix") ) {
        l_mat <- reticulate::np_array(data = mat, dtype = "uint8")
    } else if ( inherits(mat, "numpy.ndarray") ) {
        if (mat$dtype == "uint8")
            l_mat <- mat
        else if (mat$dtype == "bool") {
            l_mat <- mat$`__mul__`(255L)$astype("uint8")
            attr(l_mat, "colorspace") <- attr(mat, "colorspace") 
        } else {
            cat("forcing dtype to uint8 when displaying from ", as.character(mat$dtype), "\n")
            l_mat <- mat$astype("uint8")
            attr(l_mat, "colorspace") <- attr(mat, "colorspace") 
        }
        
    } else {
        return(NULL)
    }
    
    # convert color spaces
    if ( ! is.null( attr(l_mat, "colorspace") ) ) {
        if ( ! attr(l_mat, "colorspace") %in% c("GREY", "BGR", "BGRA") ) {
            if (length(l_mat$shape) == 3 && l_mat$shape[2] == 4) {
                l_convert <- paste0("COLOR_",attr(l_mat, "colorspace"),"2BGRA")
                if (l_convert %in% names(cv2r)) {
                    l_mat <- cv2r$cvtColor(l_mat, cv2r[[paste0("COLOR_",attr(l_mat, "colorspace"),"2BGRA")]])
                } else {
                    # report alpha layer
                    l_mat_bgra <- l_mat$copy()
                    l_mat_bgra[,,1:3] <- cv2r$cvtColor(l_mat[,,1:3], cv2r[[paste0("COLOR_",attr(l_mat, "colorspace"),"2BGR")]])
                    l_mat_bgra[,,4] <- l_mat[,,4] 
                    attr(l_mat_bgra, "colorspace") <- "BGRA"
                    l_mat <- l_mat_bgra
                }
            }
            if (length(l_mat$shape) == 3 && l_mat$shape[2] == 3)
                l_mat <- cv2r$cvtColor(l_mat, cv2r[[paste0("COLOR_",attr(l_mat, "colorspace"),"2BGR")]])
            if (length(l_mat$shape) == 3 && l_mat$shape[2] == 2)
                warning("Unsuported number of color channel")
        } else {
            
        }
    }
    
    l_shape <- unlist(reticulate::py_to_r(l_mat$shape))[1:2]
    
    # protect against empty images
    if ( min(l_shape) == 0 )
        l_mat <- reticulate::np_array(data = matrix(c(100,155,100,155,100,155,100,155,100), nrow = 3), dtype = "uint8")
    
    if ( keep_shape ) {
        l_ratio <- max(l_shape[1:2] / c(render_max_h, render_max_w))
        render_max_h <- floor(l_shape / l_ratio)[1]
        render_max_w <- floor(l_shape / l_ratio)[2]
    }
    
    render_max_w <- as.integer(render_max_w)
    render_max_h <- as.integer(render_max_h)
    
    if ( render_max_h < l_shape[[1]] || render_max_w < l_shape[[2]] ) {
        l_mat <- cv2r$resize(src=l_mat, dsize=reticulate::tuple(render_max_w,render_max_h))
    }
    
    # zoom pixel art for very small images
    if ( l_shape[[1]] < 50 || l_shape[[2]] < 50 ) {
        l_mat <- cv2r$resize(src=l_mat, dsize=.(l_shape[[2]]*100, l_shape[[1]]*100), interpolation = cv2r$INTER_NEAREST)
    }
    
    l_b64img <- base64enc::base64encode(
        reticulate::py_to_r(cv2r$imencode(img=l_mat, ext=".png"))[[2]])
    l_ret <- list(
        data=l_b64img, 
        type="png", 
        height=reticulate::py_to_r(l_mat$shape[[0]]), 
        width=reticulate::py_to_r(l_mat$shape[[1]])
    )
    class(l_ret) <- "base64img"
    l_ret
}
 
base64imgOutput <- function(outputId, height = "100%", width="100%" ) {
  htmlwidgets::createWidget(
    'cv2rplotimg',
    list(),
    elementId = outputId,
    sizingPolicy = htmlwidgets::sizingPolicy(
      viewer.padding = 0,
      viewer.paneHeight = height,
      viewer.defaultWidth = width,
      browser.padding	= 0,
      browser.fill = TRUE
    ),
    dependencies = htmltools::htmlDependency(
      'cv2rplotimg', '0.1', src = c(href = '')))
}


#' @export
`cvtColor<-` <- function(mat, value) { 
    l_from <- cvtColor(mat)
    l_to <- value
    l_trans <- paste0("COLOR_",l_from,"2",l_to)
    
    if ( ! l_trans %in% cv2r_colors ) {
        warning("Unable to find convertion function: ", l_trans)
        l_ret <- mat
    } else {
        l_ret <- cv2r$cvtColor(mat, cv2r[[l_trans]])
        attr(l_ret, "colorspace") <- l_to
    }
    return(l_ret)
}

#' @export    
cvtColor <- function(mat) {
    l_cspace <- attr(mat, 'colorspace')
    
    if ( is.null(l_cspace) )
        if ( length(mat$shape) == 3) 
            l_ret <- "BGR"
        else
            l_ret <- "GREY"
    else
        if ( l_cspace != "GREY" &&
             length(mat$shape) == 3 && 
             nchar(l_cspace) > reticulate::py_to_r(mat$shape[2]) )
            l_ret <- substr(l_cspace, 0, reticulate::py_to_r(mat$shape[2]))
        else
            l_ret <- l_cspace
    
    return(l_ret)
}

#' print an image from OpenCV 
#'
#' @param x image to plot
#' @param ... ignored
#'
#' @return Show image in Viwer pane
#' @export
#'
#' @example inst/examples/plot.R
#' 
print.numpy.ndarray <- function(x, ...) {

    cat("Python ndarray: colorspace=",attr(x, "colorspace")," shape= ")
    print(x$shape)
    
    if ( length(dim(x)) == 2 || 
         ( length(dim(x)) == 3 && dim(x)$layers %in% c(1,3,4) ) )
      invisible(print(imshow(mat = x)))
    else
      NextMethod()
}


#' plot an image from OpenCV 
#'
#' @param mat image to plot
#'
#' @return Show image in Viwer pane
#'
#' @example inst/examples/plot.R
#' 
#' @export
plot.numpy.ndarray <- function(x, ...) {
    if ( length(dim(x)) == 2 || 
         ( length(dim(x)) == 3 && dim(x)$layers %in% c(1,3,4) ) )
        invisible(print(imshow(mat = x)))
    else
        NextMethod()
}
