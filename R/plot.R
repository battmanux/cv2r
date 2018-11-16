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
#' @examples
#' my_image <- imread("https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png")
#' imshow(mat= my_image)
#' 
#' # you can also do plot(my_image)
#' 
#' 
imread <- function(filename, flags=-1L) {
    if ( grepl("^https?://.*", x = filename) ) {
        l_tmpfile <- tempfile(fileext = ".bin")
        curl::curl_download(filename, l_tmpfile)
    } else {
        l_tmpfile <- filename
    }
        
    cv2r$imread(l_tmpfile, flags)
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
#' @examples
#' my_image <- imread("https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png")
#' imshow(mat=my_image)
#' 
#' # you can also do plot(my_image)
#' 
imshow <- function(winname="default", mat, render_max_w = 1000, render_max_h = 1000, keep_shape = T, scale = 1.0) {

    # Clean input types
    
    if ( ! "numpy.ndarray" %in% class(mat) )
        l_mat <- reticulate::np_array(data = mat, dtype = "uint8")
    else
        l_mat <- mat
    
    if ( keep_shape ) {
        l_shape <- unlist(reticulate::py_to_r(l_mat$shape))[1:2]
        l_ratio <- max(l_shape[1:2] / c(render_max_h, render_max_w))
        render_max_h <- floor(l_shape / l_ratio)[1]
        render_max_w <- floor(l_shape / l_ratio)[2]
    }
    
    render_max_w <- as.integer(render_max_w)
    render_max_h <- as.integer(render_max_h)
    
    if ( render_max_h < l_shape[[1]] || render_max_w < l_shape[[2]] ) {
        mat <- cv2r$resize(src=mat, dsize=reticulate::tuple(render_max_w,render_max_h))
    }
    
    l_b64img <- base64enc::base64encode(
        reticulate::py_to_r(cv2r$imencode(img=mat, ext=".png"))[[2]])
    
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


#' print an image from OpenCV 
#'
#' @param x image to plot
#' @param ... ignored
#'
#' @return Show image in Viwer pane
#' @export
#'
#' @examples
#' 
#' my_image <- imread("https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png")
#' print(my_image) # or just my_image
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
#' @examples
#' 
#' my_image <- imread("https://upload.wikimedia.org/wikipedia/fr/4/4e/RStudio_Logo.png")
#' plot(my_image)
#' 
#' @export
plot.numpy.ndarray <- function(mat) {
    if ( length(mat$shape) == 2 || ( length(mat$shape) == 3 &&reticulate::py_to_r(mat$shape)[[3]] %in% c(1,3,4) ) )
        invisible(print(imshow(mat = mat)))
    else
        NextMethod()
}