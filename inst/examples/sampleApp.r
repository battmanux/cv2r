library(shiny)
library(cv2r)

if ( cv2_available() ) {
    ui <- fluidPage(fluidRow(
        column(4,inputCv2Cam("video")),
        column(4,cv2Output(outputId = "zoom")),
        column(4,cv2Output(outputId = "border"))
    ))
    
    server <- function(input, output, session) {
        
        output$zoom <- renderCv2({
            input$video[100:200,120:280]
        })
        
        output$border <- renderCv2({
            cv2r$Canny(input$video, 10L, 50L)
        })
    }
    
    if (interactive()) {
        shinyApp(ui, server)
    }
    
}