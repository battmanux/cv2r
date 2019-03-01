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
imshow <- function(winname="default", mat, render_max_w = 1000, render_max_h = 1000, keep_shape = T, scale = 1.0) {

    # Clean input types
    
    # Convert from not displayable types
    if ( ! "numpy.ndarray" %in% class(mat) )
        l_mat <- reticulate::np_array(data = mat, dtype = "uint8")
    else {
        if (mat$dtype == "uint8")
            l_mat <- mat
        else if (mat$dtype == "bool") {
            l_mat <- mat$`__mul__`(255L)$astype("uint8")
        } else {
            cat("forcing dtype to uint8 when displaying (from ", mat$dtype, ")\n")
            l_mat <- mat$astype("uint8")
        }
            
    }
    
    # convert color spaces
    if ( ! is.null( attr(l_mat, "colorspace") ) ) {
        if ( ! attr(l_mat, "colorspace") %in% c("GREY", "BGR") ) {
            l_mat <- cv2r$cvtColor(l_mat, cv2r[[paste0("COLOR_",attr(l_mat, "colorspace"),"2BGR")]])
        }
    }
        
    if ( keep_shape ) {
        l_shape <- unlist(reticulate::py_to_r(l_mat$shape))[1:2]
        l_ratio <- max(l_shape[1:2] / c(render_max_h, render_max_w))
        render_max_h <- floor(l_shape / l_ratio)[1]
        render_max_w <- floor(l_shape / l_ratio)[2]
    }
    
    render_max_w <- as.integer(render_max_w)
    render_max_h <- as.integer(render_max_h)
    
    if ( render_max_h < l_shape[[1]] || render_max_w < l_shape[[2]] ) {
        l_mat <- cv2r$resize(src=l_mat, dsize=reticulate::tuple(render_max_w,render_max_h))
    }
    
    l_b64img <- base64enc::base64encode(
        reticulate::py_to_r(cv2r$imencode(img=l_mat, ext=".png"))[[2]])
    
    l_data <- list(
        list(id=winname, scale = scale, type="data:image/png;base64", data=l_b64img) 
    )
    
    l_out <- r2d3::r2d3(data=l_data, script = system.file("simple_png_view.js", package = "cv2r"))

    # knitr does not call print from a python chunk
    if ( "options" %in% names(sys.frames()[[1]]) &&
         sys.frames()[[1]]$options$engine == "python") {
        print(l_out)
    } else {
        l_out
    }
}


`cvtColor<-` <- function(mat, value) { 
    l_from <- cvtColor(mat)
    l_to <- value
    l_trans <- paste0("COLOR_",l_from,"2",l_to)
    
    if ( ! l_trans %in% names(cv2r) ) {
        warning("Unable to find convertion function: ", l_trans)
        l_ret <- mat
    } else {
        l_ret <- cv2r$cvtColor(mat, cv2r[[l_trans]])
        attr(l_ret, "colorspace") <- l_to
    }
    return(l_ret)
}
    
cvtColor <- function(mat) {
    l_cspace <- attr(mat, 'colorspace')
    
    if ( is.null(l_cspace) )
        if ( length(mat$shape) == 3) 
            l_ret <- "GRB"
        else
            l_ret <- "GREY"
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
    mat = x
    cat("Python ndarray: shape=")
    print(mat$shape)
    
    if ( length(mat$shape) == 3 && reticulate::py_to_r(mat$shape)[[3]] %in% c(1,3,4) ) {
        print(imshow(mat = mat))
        invisible(print(imshow(mat = mat)))
    } else if ( length(mat$shape) == 2 ) {
        print(imshow(mat = mat))
        NextMethod()
    }else
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
plot.numpy.ndarray <- function(mat) {
    if ( length(mat$shape) == 2 || ( length(mat$shape) == 3 &&reticulate::py_to_r(mat$shape)[[3]] %in% c(1,3,4) ) )
        invisible(print(imshow(mat = mat)))
    else
        NextMethod()
}