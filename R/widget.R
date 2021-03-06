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
scene3d <- function(gltf, obj, show_ground=TRUE, use_vr = FALSE, code = "", data = list() ) {
    
    l_ret <- list(
        width=100,
        height=100,
        texture = "",
        show_ground=show_ground,
        use_vr = use_vr,
        code = code,
        data = data
    )
    
    if (! missing(gltf) ) {
        if (length(gltf) == 1 && nchar(gltf) < 300 && file.exists(gltf) ) {
            l_file <- paste(readLines(gltf), sep = "", collapse = "\n")        
        } else {
            l_file <- gltf
        }
        
        l_ret$gltf <- l_file
    }
    
    if (! missing(obj) ) {
        if (length(obj) == 1 && nchar(obj) < 300 && file.exists(obj) ) {
            l_file <- paste(readLines(obj), sep = "", collapse = "\n")        
        } else {
            l_file <- obj
        }
        
        l_ret$obj <- l_file
    }
    
    class(l_ret) <- 'scene3ddef'
    l_ret
}

#' @export
plot.scene3ddef <- function(scene3d,
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
print.scene3ddef <- function(scene3d) {
    cat("scene3d\n")
    invisible(print(plot(scene3d)))
}


#' @export
updateScene3d <- function(session, outputId, code, data=list()) {
    code <- htmlwidgets::JS(code)
    session$sendCustomMessage( paste0(outputId, "_", "execute"), list(code=code, data=data))
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


as.matrix.mp3base64 <- function(data, ...) {
    
    if (is.null(data) || nchar(data) < 10) {
        l_ret <- numeric(0)
    } else {
        l_x <- base64enc::base64decode(what = data)
        l_wave <- .Call(tuneR:::C_do_read_mp3, l_x)@left
        
        i <- 735
        # while(i < length(l_wave)-660 && l_wave[[i]] == 0 ) i <- i+1
        # 
        if ( (i+660) > (length(l_wave) - 441) )
            l_ret <- numeric(0)
        else
            l_ret <- l_wave[(i+660):length(l_wave)]
    } 
    return(l_ret)
}


plot.Wave <- function(l_audio) {
    tuneR::writeWave(l_audio, "file.wav")
    l_data <- readBin("file.wav", what = "raw", n = 10000000)
    l_ui <- shiny::bootstrapPage(
        actionButton(inputId = "done", label = "done"),
        shiny::tags$audio(controls = "true",
        shiny::tags$source(
            src=paste0("data:audio/wav;base64,",
                       base64enc::base64encode(l_data)), 
            type="audio/wav") ))
    shiny::runGadget(l_ui, server = function(input,output){ 
        observeEvent(input$done, {
        stopApp(NULL)
            })
        } )
}
