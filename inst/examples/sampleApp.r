library(shiny)
library(cv2r)
library(ggplot2)
library(bioacoustics)
library(data.table)

if ( cv2_available() ) {
    ui <- fluidPage(fluidRow(
        actionButton(inputId = "snap", label = "Take"),
        actionButton(inputId = "snap2", label = "Take2"),
        actionButton(inputId = "plot_audio", label = "Audio")),
        fluidRow(
          column(3,inputCv2Cam("capture",
                               auto_send_audio = T, audio = T)),
          column(3,cv2Output(outputId = "zoom")),
          column(3,cv2Output(outputId = "border"))
    ),
    fluidRow(column(12, plotOutput(outputId = "envelop", height = 200))),
    fluidRow(column(12, plotOutput(outputId = "fullplot_veryhigh", height = 200))),
    fluidRow(column(12, plotOutput(outputId = "fullplot_high", height = 200))),
    fluidRow(column(12, plotOutput(outputId = "fullplot_low", height = 200)))
    )
    
    server <- function(input, output, session) {
        
        full_data <- numeric(0)
        
        observeEvent(input$capture_audio, {
        
            l_data_sel <- input$capture_audio
            
            cat(length(full_data), "\n")
            full_data <<- c(full_data, l_data_sel)
        })
        
        observeEvent(input$plot_audio, {
            l_data_sel <- full_data
            full_data <<- numeric(0)
            
            .GlobalEnv$l_data_sel <- l_data_sel
            #plot.Wav(tuneR::Wave(left = l_data_sel, right =  l_data_sel, bit=16, samp.rate=44100))
            
            l_plot <- data.table(
              time = seq_along(l_data_sel)/44100,
              amplitude = l_data_sel,
              envelope = abs(l_data_sel)
              )
            
            output$envelop <- renderPlot({
                ggplot(l_plot[sample.int(nrow(l_plot), 1000),] ) +
                    geom_line(aes(x=time, y=envelope )) + 
                    theme_minimal() + stat_smooth(aes(x=time, y=envelope ))
            })
            
            output$fullplot_veryhigh <- renderPlot({
              spectro(tuneR::Wave(left = l_data_sel, bit=16, samp.rate=44100),
                      flim = c(3000, 10000),
                      FFT_size = 512  )
            })
            
            output$fullplot_high <- renderPlot({
              spectro(tuneR::Wave(left = l_data_sel, bit=16, samp.rate=44100),
                    flim = c(1000, 3000),
                    FFT_size = 1024  )
              })
            
            output$fullplot_low <- renderPlot({
              spectro(tuneR::Wave(left = l_data_sel, bit=16, samp.rate=44100),
                      flim = c(0, 1000),
                      FFT_size = 2048  )
            })
            
        })
        
        observeEvent(input$snap, {
          inputCv2CamSnap(session, "capture")
        })

        observeEvent(input$snap2, {
          inputCv2CamSnap(session, "capture", top = 100, left = 100, width = 200, height = 100)
        })
        
                
        output$zoom <- renderCv2({
          if ( !is.null(input$capture)) input$capture[5:200,5:200]
        })
        
        output$border <- renderCv2({
            imshow(mat = cv2r$Canny(input$capture, 10L, 50L) )
        })
    }
    
    if (interactive()) {
      shinyApp(ui, server)
    }
    
}

