#' @import htmlwidgets
#' 

#' @export
plot.base64img <- function(base64img,
                  width = NULL, height = NULL) {
    
    
    # pass the data and settings using 'x'
    x <- base64img
    
    sizingPolicy <- htmlwidgets::sizingPolicy(
        viewer.padding = 0,
        viewer.paneHeight = base64img$height,
        viewer.defaultWidth = base64img$width,
        browser.padding	= 0,
        browser.fill = TRUE
    )
    
    # create the widget
    htmlwidgets::createWidget("base64img", package = "cv2r",
                              x,  width = width, height = height, sizingPolicy = sizingPolicy)
}

#' @export
base64imgOutput <- function(outputId, width = "100%", height = "400px") {
    shinyWidgetOutput(outputId, "base64img", width, height, package = "cv2r")
}

#' @export
renderBase64img <- function(expr, env = parent.frame(), quoted = FALSE) {
    if (!quoted) { expr <- substitute(expr) } # force quoted
    shinyRenderWidget(expr, base64imgOutput, env, quoted = TRUE)
}