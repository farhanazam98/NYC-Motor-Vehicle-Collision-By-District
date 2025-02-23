
#===============  some customization functions =================
#
# customize a ggplot2 theme:
# http://joeystanley.com/blog/custom-themes-in-ggplot2
#
# can specify another base fond family: base_family = ""
# see package "extrafont", 'loadfonts()', ggsave(), etc.
# http://blog.revolutionanalytics.com/2012/09/how-to-use-your-favorite-fonts-in-r-charts.html
# by Winston Chang
#
theme_hua <- function (base_size = 12, base_family = "",
                       
                       plot.title = element_text(hjust=0.5, size = 18, face = "bold", 
                                                 margin=margin(t = 20, b = 20, unit = "pt")),
                       legend.text = element_text(size = 10),
                       axis.text = element_text(size = 12),
                       axis.title = element_text(size = 14, face = "bold"),
                       
                       axis.line = element_line(color = 'black'), 
                       panel.border = element_blank(),
                       
                       #'gray96', i.e. #F4F4F4, is a comfortable color for background.
                       panel.background = element_rect(fill="gray96", colour=NA),
                       plot.background = element_rect(fill="gray96", colour=NA), 
                       legend.background = element_rect(fill="transparent", colour=NA),
                       
                       legend.key = element_rect(fill="transparent", colour=NA), ...
                       ) { 
  
  theme_bw(base_size, base_family) + 
    # "+" is to update target theme_bw w/ new specified changes
    # "%+replace%"  is to only use the following specified changes, 
    # all other unspecified params in the original theme are completely overriden.
    theme(
      # new changes 
      plot.title = plot.title,
      legend.text = legend.text,
      axis.text = axis.text,
      axis.title = axis.title,
      
      axis.line = axis.line, 
      panel.border = panel.border,
      
      panel.background = panel.background,
      plot.background = plot.background, 
      legend.background = legend.background,
      
      legend.key = legend.key, ...
    )
}

# fine control:
#"expand" param: default: data is placed some distance away from the axes

scale_y_continuous_hua <- function (expand = c(0, 0), 
                                    labels = scales::comma, ...) {
  scale_y_continuous(expand = expand, labels = labels, ...)
}

scale_x_continuous_hua <- function (expand = c(0, 0), 
                                    labels = scales::comma, ...) {
  scale_x_continuous(expand = expand, labels = labels, ...)
}

barWidth <- 0.6

function(input, output, session) {
  
  #===================================================
  #=========        Map View tab           =========== 
  #===================================================
  
  #--------- Render base map ----------
  
  output$myMap = renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      #addProviderTiles("Esri.WorldStreetMap") %>%
      #addProviderTiles('CartoDB.DarkMatter') %>% # dark background map
      setView(lng = -73.935242, lat = 40.730610, zoom = 11)
  })
  
  
  #--------- Reactively update selected data info,
  #          when UI input data selection is changed. ---------
  mapData <- reactive({
    mvc %>%
      filter( 
        (input$mapBoro == 'All' | borough == input$mapBoro) &
          (input$mapYear == 'All' | year    == input$mapYear) &
          (month >= input$mapSliderMonth[1] & month <= input$mapSliderMonth[2]) &
          ((severity == 'nohurt'  & 'No hurt' %in% input$mapSeverity) | 
             (severity == 'injured' & 'Injured' %in% input$mapSeverity) | 
             (severity == 'lethal'  & 'Lethal'  %in% input$mapSeverity)) &
          (('Lethal'  %in% input$mapSeverity & #check lethal: 
              ((pedKill > 0 & 'Pedestrian' %in% input$mapVictim) |
                 (cycKill > 0 & 'Cyclist'    %in% input$mapVictim) |
                 (motKill > 0 & 'Motorist'   %in% input$mapVictim))) |
             ('Injured'  %in% input$mapSeverity & #check injured: 
                ((pedInj > 0 & 'Pedestrian' %in% input$mapVictim) |
                   (cycInj > 0 & 'Cyclist'    %in% input$mapVictim) |
                   (motInj > 0 & 'Motorist'   %in% input$mapVictim))) |
             ('No hurt'  %in% input$mapSeverity))
      )
  })
  
  #-------- instantly update map with updated data,
  #         when UI input data selection is changed. -----------
  observe({
    
    if (input$showHeatMap) {
      leafletProxy('myMap', data = mapData()) %>% #don't forget mapData()
        clearWebGLHeatmap() %>%
        addWebGLHeatmap(~long, ~lat, size = input$mapSliderSensitivity, units = 'p', opacity = 0.6)
    } else {
      leafletProxy('myMap', data = mapData()) %>% 
        clearWebGLHeatmap()
    }
    
    if (input$showClusterMap) {
      factpal <- colorFactor(c('green', 'blue', 'red'), Sevr)
      
      leafletProxy('myMap', data = mapData()) %>% 
        clearMarkerClusters() %>% 
        addCircleMarkers(lng = ~long, lat=~lat, radius = 3, stroke = F,
                         color = ~factpal(severity), fillOpacity = 0.2,
                         clusterOptions = markerClusterOptions())
    } else {
      leafletProxy('myMap', data = mapData()) %>% 
        clearMarkerClusters()     
    }
    
    if (input$mapMarkLethal) {
      
      x <- mapData() %>%
        filter(pedKill > 0 | cycKill > 0 | motKill > 0)
      
      leafletProxy('myMap', data = x) %>%
        clearMarkers() %>%
        addMarkers(lng = ~long, lat=~lat, 
                   popup = ~paste('<font color="Black"><b>','Collision Information','</b><br/>',
                                  'Date and time:', x$dtime,'<br/>',
                                  'Killed: ','ped ', x$pedKill, ', cyc ', x$cycKill, ', mot ', x$motKill, '<br/>',
                                  'Injured: ', 'ped ', x$pedInj, ', cyc ', x$cycInj, ', mot ', x$motInj, '<br/>',
                                  'Cause:', x$cFactor1, x$cFactor2, x$cFactor3, x$cFactor4, x$cFactor5, 
                                  '<br/></font>'))
    } else {
      leafletProxy('myMap', data = mapData()) %>%
        clearMarkers()
    }
    
  })

}