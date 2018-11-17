library(shiny)
library(cv2r)

if ( cv2_available()) {
    ui <- fluidPage(
        inputCv2Cam("video"),
        cv2Output(outputId = "zoom")
    )
    
    server <- function(input, output, session) {
        
        output$zoom <- renderCv2({
            img <- input$video
            
            if (is.null(img))
                return(NULL)
            
            imshow("id", input$video[100:200,150:250]) })
    }
    
    # shinyApp(ui, server)
    
}


