#' Shiny bindings for OpenCV
#' 
#' Output and render functions for using OpenCV within Shiny applications and interactive Rmd documents
#'
#' @param outputId output variable to write in
#' @param width    Must be a valid CSS unit (like '400px', 'auto', ...) or a number, which will be coerced to a string and have 'px' appended.
#' @param height   Must be a valid CSS unit (like '400px', 'auto', ...) or a number, which will be coerced to a string and have 'px' appended.
#'
#' @return output widget
#' @export
#'
#' @examples
#' 
#' \donttest{
#'library(shiny)
#'library(cv2r)
#'
#'ui <- fluidPage(
#'  inputCv2Cam("video"),
#'  cv2Output(outputId = "zoom")
#')
#'
#'server <- function(input, output, session) {
#'  
#'  output$zoom <- renderCv2({
#'    img <- input$video
#'    
#'    if (is.null(img))
#'      return(NULL)
#'    
#'    imshow("id", input$video[100:200,150:250]) })
#'}
#'
#'shinyApp(ui, server)
#' }
cv2Output <- function (outputId, width = "100%", height = "400px") 
{
  htmlwidgets::shinyWidgetOutput(outputId, "r2d3", width, 
                                 height)
}
  

#' Shiny bindings for OpenCV
#'
#' @param expr An expression that plots a OpenCV image (see [imshow()])
#' @param env  The environment in which to evaluate expr
#' @param quoted Is expr a quoted expression (with quote())? This is useful if you want to save an expression in a variable
#'
#' @export
#' 
#' @examples
#' 
#' \donttest{
#'library(shiny)
#'library(cv2r)
#'
#'ui <- fluidPage(
#'  inputCv2Cam("video"),
#'  cv2Output(outputId = "zoom")
#')
#'
#'server <- function(input, output, session) {
#'  
#'  output$zoom <- renderCv2({
#'    img <- input$video
#'    
#'    if (is.null(img))
#'      return(NULL)
#'    
#'    imshow("id", input$video[100:200,150:250]) })
#'}
#'
#'shinyApp(ui, server)
#' }
renderCv2 <- function (expr, env = parent.frame(), quoted = FALSE) 
{
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, r2d3::d3Output, env, quoted = TRUE)
}


#' Capture WebCam as OpenCV Mat
#' 
#' Add this component to a shiny ui and you will be able to access captured image through input$<inputId> 
#'
#' @param inputId  The input slot that will be used to access the value
#' @param width    Width of the captured image
#' @param height   Height of the captured image
#' @param fps      Frames per secondes
#' @param show_live  Shall we show webcam stream
#' @param show_captured  Shall we show the captured image
#' @param encoding Picture encoding over HTTP
#' @param quality  Encoding quality (if encoding = image/jpeg)
#'
#' @return A WebCam capture control that can be added to a UI definition
#' @export
#'
#' @examples
#' \donttest{
#'library(shiny)
#'library(cv2r)
#'
#'ui <- fluidPage(
#'  inputCv2Cam("video"),
#'  cv2Output(outputId = "zoom")
#')
#'
#'server <- function(input, output, session) {
#'  
#'  output$zoom <- renderCv2({
#'    img <- input$video
#'    
#'    if (is.null(img))
#'      return(NULL)
#'    
#'    imshow("id", input$video[100:200,150:250]) })
#'}
#'
#'shinyApp(ui, server)
#'}
inputCv2Cam <- function(inputId, width=320, height=240, fps=6, show_live=F, show_captured = T, encoding = "image/jpeg", quality = 0.9) {
    shiny::div(
        shiny::tags$video(id=inputId, width=width, height=height, style=if (!show_live) "display:none;" else ""),
        shiny::tags$canvas(id="canvas", width=width, height=height, style=if (!show_captured) "display:none;" else ""),
        shiny::tags$script(shiny::HTML(paste0('
$(document).ready(function(){
  let video = document.getElementById("',inputId,'"); // video is the id of video tag
  navigator.mediaDevices.getUserMedia({ video: { width: ',width,', height: ',height,' }, audio: false })
  .then(function(stream) {
    video.srcObject = stream;
    video.play();
  })
  .catch(function(err) {
    console.log("An error occurred! " + err);
  });


  function snap() {
    var canvas = document.getElementById("canvas") 
    context = canvas.getContext("2d")
    context.drawImage(video, 0, 0, ',width,', ',height,');
    imgBase = canvas.toDataURL("',encoding,'", ',quality,')
    Shiny.onInputChange("',inputId,':base64img", imgBase.replace(/^data:image.*;base64,/, ""))
  }

  setInterval(snap, ',as.integer(1000/fps),');

});

', collapse = "")))
    )
}

# convert base64 string into an OpenCV Mat (numpy.ndarray)
#
# @param data base64 string
# @param ... 
#
# @return
base64img2ndarray <- function(data, ...) {
  l_png <- base64enc::base64decode(what = data)
  l_mat <- cv2r$imdecode(reticulate::np_array(as.integer(l_png), dtype = "uint8"), -1L)
  l_mat
}