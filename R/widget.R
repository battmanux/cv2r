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

#' @export
scene3d <- function(texture="") {
    l_ret <- list(
        width=100,
        height=100,
        texture = texture
    )
    
    class(l_ret) <- 'scene3d'
    l_ret
}

#' @export
plot.scene3d <- function(scene3d,
                           width = NULL, height = NULL) {
    
    
    # pass the data and settings using 'x'
    x <- scene3d
    
    sizingPolicy <- htmlwidgets::sizingPolicy(
        viewer.padding = 0,
        viewer.paneHeight = 300,
        viewer.defaultWidth = 300,
        browser.padding	= 0,
        browser.fill = TRUE
    )
    
    # create the widget
    htmlwidgets::createWidget("scene3d", package = "cv2r",
                              x,  width = width, height = height, sizingPolicy = sizingPolicy)
}

#' @export
scene3dOutput <- function(outputId, width = "100%", height = "400px") {
    shinyWidgetOutput(outputId, "scene3d", width, height, package = "cv2r")
}

#' @export
renderScene3d <- function(expr, env = parent.frame(), quoted = FALSE) {
    if (!quoted) { expr <- substitute(expr) } # force quoted
    shinyRenderWidget(expr, scene3dOutput, env, quoted = TRUE)
}