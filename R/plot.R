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
#' my_image <- imread("https://www.google.fr/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png")
#' imshow(my_image)
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
        
    cv2$imread(l_tmpfile, flags)
}

#' Overload of OpenCV imshow to make it compatible with RStudio server and Shiny
#'
#' @param winname Image identifyer
#' @param mat image data structure to show
#' @param max_w resize with maximum number of pixel width
#' @param max_h resize with maximum number of pixel height
#' @param keep_shape keep aspect ratio when resizing (default TRUE)
#'
#' @return r2d3 object
#' @export
#'
#' @examples
#' my_image <- imread("https://www.google.fr/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png")
#' imshow(my_image)
#' 
#' # you can also do plot(my_image)
#' 
imshow <- function(winname="default", mat, max_w = 500, max_h = 500, keep_shape = T) {

    # Clean input types
    
    if ( ! "numpy.ndarray" %in% class(mat) )
        l_mat <- reticulate::np_array(data = mat, dtype = "uint8")
    else
        l_mat <- mat
    
    if ( keep_shape ) {
        l_shape <- unlist(reticulate::py_to_r(l_mat$shape))[1:2]
        l_ratio <- max(l_shape[1:2] / c(max_w, max_h))
        max_w <- floor(l_shape / l_ratio)[1]
        max_h <- floor(l_shape / l_ratio)[2]
    }
    
    max_w <- as.integer(max_w)
    max_h <- as.integer(max_h)
    
    l_out <- cv2$resize(src=mat, dsize=reticulate::tuple(max_h,max_w))
    l_b64img <- base64enc::base64encode(reticulate::py_to_r(cv2$imencode(img=l_out, ext=".png"))[[2]])
    
    l_data <- list(
        list(id=winname, type="data:image/png;base64", data=l_b64img) 
    )
    
    r2d3::r2d3(data=l_data, script = system.file("simple_png_view.js", package = "cv2r"))
}


#' print an image from OpenCV 
#'
#' @param mat image to plot
#'
#' @return Show image in Viwer pane
#' @export
#'
#' @examples
#' 
#' my_image <- imread("https://www.google.fr/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png")
#' print(my_image) # or just my_image
#' 
print.numpy.ndarray <- function(mat) {
    cat("Pytohon ndarray: shape=")
    print(mat$shape)
    if ( length(mat$shape) == 3 && mat$shape[2] <= 4) {
        print(imshow(mat = mat))
        invisible(print(imshow(mat = mat)))
    }
        
    else
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
#' my_image <- imread("https://www.google.fr/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png")
#' plot(my_image)
#' 
#' @export
plot.numpy.ndarray <- function(mat) {
    if ( length(mat$shape) == 3 && mat$shape[2] <= 4)
        invisible(print(imshow(mat = mat)))
    else
        NextMethod()
}