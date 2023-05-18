#' Hydrograph Animation
#'
#' @param daily_values A previously create `whitewater::ww_dvUSGS()` object.
#' @param dir character. A path to store the GIF files. `tempfile()` (if NULL) or ex. `some/file/path/`.
#'
#' @return A GIF.
#' @export
#'
#' @examples \dontrun{
#'
#' library(whitewater.extras)
#' library(whitewater)

#' #provide a USGS site number that you want to look at visually (we need the data first)
#' kootenai_river <- ww_dvUSGS(sites = '12305000')
#'
#' ww_animate_hydrograph(daily_values = kootenai_river)
#'
#' }
ww_animate_hydrograph <- function(daily_values, dir = NULL){

  steps <- daily_values %>% dplyr::group_by(wy) %>% dplyr::slice(1) %>% nrow()

  qmax <- daily_values %>%
    ggplot2::ggplot(ggplot2::aes(wy_doy, Flow_max_prop)) +
    ggfx::with_blur(ggplot2::geom_line(linewidth = 1, alpha = 0.75, color = '#336a98')) +
    ggplot2::theme_bw() +
    ggplot2::labs(title = '',
         subtitle = 'Water Year: {frame_time}', x = 'Day of Year', y = 'Q-Max')  +
    gganimate::transition_events(wy) +
    gganimate::transition_time(wy) +
    gganimate::ease_aes('linear')

  rh <- ww_raster_hydrograph(daily_values, Flow) +
    gganimate::transition_manual(wy, cumulative = TRUE) +
    gganimate::ease_aes('linear')

  qmax_gif <- gganimate::animate(qmax, nframes = steps, renderer = gganimate::magick_renderer())

  if(is.null(dir)) {gganimate::anim_save(tempfile(fileext = '.gif'), qmax_gif) } else  {gganimate::anim_save(paste0(dir, '/qmax_gif.gif'), qmax_gif)}

  rh_gif <- gganimate::animate(rh, nframes = steps, renderer = gganimate::magick_renderer())

  if(is.null(dir)){ gganimate::anim_save(tempfile(fileext = '.gif'), rh_gif) } else {gganimate::anim_save(paste0(dir, '/rh_gif.gif'), rh_gif)}

  new_gif <- magick::image_append(c(qmax_gif[1], rh_gif[1]))

  for(i in 2:steps){
    combined <- magick::image_append(c(qmax_gif[i], rh_gif[i]))
    new_gif <- c(new_gif, combined)
  }

  if(is.null(dir)) {gganimate::anim_save(tempfile(fileext = '.gif'), new_gif)} else {gganimate::anim_save(paste0(dir, 'hydrograph.gif'), new_gif)}

  new_gif
}
