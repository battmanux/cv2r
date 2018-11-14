cv2Output <- r2d3::d3Output

renderCv2 <- r2d3::renderD3

#' Capture WebCam
#'
#' @param inputId  The input slot that will be used to access the value
#' @param width    Width of the captured image
#' @param height   Height of the captured image
#' @param fps      Frames per secondes
#' @param show_live  Shall we show webcam stream
#' @param show_captured  Shall we show the captured image
#'
#' @return A WebCam capture control that can be added to a UI definition
#' @export
#'
#' @examples
#' 
#' library(shiny)
#' 
#' ui <- fluidPage(
#'     inputCv2Cam("video")
#' )
#' 
#' server <- function(input, output, session) {
#'     observe({ print(nchar(input$video)) })
#' }
#' 
#' shinyApp(ui, server)
#' 
inputCv2Cam <- function(inputId, width=320, height=240, fps=10, display=T) {
    shiny::div(
        shiny::tags$video(id=inputId, width=width, height=height, style="display:none;"),
        shiny::tags$canvas(id="canvas", width=width, height=height, style=if (!display) "display:none;" else ""),
        shiny::tags$script(HTML(paste0('
$(document).ready(function(){
  let video = document.getElementById("',inputId,'"); // video is the id of video tag
  navigator.mediaDevices.getUserMedia({ video: true, audio: false })
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
    imgBase = canvas.toDataURL("image/png")
    Shiny.onInputChange("',inputId,'", imgBase)
  }

  setInterval(snap, ',as.integer(1000/fps),');

});

', collapse = "")))
    )
}