#' Raster Hydrograph
#'
#' @param daily_values A previously create `whitewater::ww_dvUSGS()` object.
#' @param value_name The variable to include as the y-axis.
#' @param without_ggfx logical. FALSE (default).
#' @return A ggplot.
#' @importFrom dplyr "%>%"
#' @export
#'
#' @examples \dontrun{
#'
#' library(whitewater.extras)
#' library(whitewater)

#' #provide a USGS site number that you want to look at visually (we need the data first)
#' kootenai_river <- ww_dvUSGS(sites = '12305000')
#'
#' ww_raster_hydrograph(daily_values = kootenai_river)
#'
#' }
ww_raster_hydrograph <- function(daily_values, value_name, without_ggfx = FALSE) {

  xbreaks <- daily_values %>%
             dplyr::group_by(month) %>%
             dplyr::slice_min(day, with_ties = F) %>%
             dplyr::pull(wy_doy)

  dup_labels <- function(x) daily_values$month_abb[match(x, daily_values$wy_doy)]

  daily_values %>%
    ggplot2::ggplot(ggplot2::aes(wy_doy, wy)) +
    ggfx::with_outer_glow(ggplot2::geom_tile(ggplot2::aes(fill = {{value_name}}))) +
    ggplot2::scale_y_continuous( breaks = seq(min(daily_values$wy),
                                     max(daily_values$wy),
                                     by = 10),
                        name = 'Water Year') +
    ggplot2::scale_x_continuous(breaks = xbreaks,
                       name = 'Day of Year',
                       sec.axis = ggplot2::dup_axis(labels = dup_labels, name = NULL),
                       expand = c(0,0)) +
    ggplot2::scale_fill_gradientn(colors = hcl.colors(11, palette = 'Spectral'),
                         labels = scales::comma,
                         name = 'Discharge (cfs)',
                         trans = 'log') +
    ggplot2::labs(title = 'Raster-Hydrograph of Daily Discharge (cfs)',
         subtitle = paste0('at USGS site ', daily_values[1,]$site_no,
                           ' ',
                           daily_values[1,]$Station)) +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5),
          plot.subtitle = ggplot2::element_text(hjust = 0.5, size = 8),
          panel.grid.minor.x = ggplot2::element_blank(),
          panel.grid.major.y = ggplot2::element_blank(),
          panel.grid.major.x = ggplot2::element_blank(),
          panel.background = ggplot2::element_rect(fill = NA),
          panel.ontop = T,
          axis.ticks.x = ggplot2::element_blank(),
          axis.text.x.bottom = ggplot2::element_text(vjust = 5.5,face = 'bold'),
          axis.text.x.top = ggplot2::element_text(hjust = -.45, vjust = -5.5, face = 'bold'))
}

#' Hysteresis Plot
#'
#' @param daily_values A previously create `whitewater::ww_dvUSGS()` object.
#' @param value_name The variable to include as the y-axis.
#' @param lag_days Number of days to lag.
#'
#' @return A ggplot plot.
#' @export
#'
#' @examples \dontrun{
#'
#' library(whitewater.extras)
#' library(whitewater)

#' #provide a USGS site number that you want to look at visually (we need the data first)
#' kootenai_river <- ww_dvUSGS(sites = '12305000')
#'
#' ww_hysteresis_plot(daily_values = kootenai_river)
#'
#' }
ww_hysteresis_plot <- function(daily_values, value_name, lag_days = 1){

  lagged_df <- daily_values %>% dplyr::mutate(lag = dplyr::lag({{value_name}}, lag_days))

  lagged_df <- lagged_df %>% dplyr::filter(!is.na(lag))

  lagged_df_final <- lagged_df %>% dplyr::group_by(month_abb) %>%
    tidyr::nest() %>%
    dplyr::mutate(model = purrr::map(data, ~lm(.$lag~.$Flow, data = .)),
           pred = purrr::map2(data, model, ~as.numeric(predict(.y, .x)))) %>%
    dplyr::select(data, pred) %>%
    tidyr::unnest(c('data','pred'))

  lagged_df_final %>%
    ggplot2::ggplot(ggplot2::aes({{value_name}}, lag)) +
    ggplot2::geom_path(ggplot2::aes(color = wy),
              alpha = 0.1,
              arrow = ggplot2::arrow(
                length = ggplot2::unit(1.5, "mm"),
                ends = "last"
              )) +
    ggplot2::geom_abline(slope = 1, intercept = 0) +
    ggplot2::stat_smooth(geom = 'line',
                method = 'lm',
                linetype = 2, ggplot2::aes(Flow, pred)) +
    ggplot2::scale_x_continuous(labels = scales::comma) +
    ggplot2::scale_y_continuous(labels = scales::comma) +
    ggplot2::labs(y = 'Lagged Flow',title = 'Hysteresis of Daily Discharge (cfs) and Lagged 1-day Daily Discharge (cfs)',
         subtitle = paste0('at USGS site ', daily_values[1,]$site_no,
                           ' ',
                           daily_values[1,]$Station)) +
    ggplot2::facet_wrap(~month_abb, scales = 'free') +
    ggplot2::theme_bw()

}


#' Monthly Trends
#'
#' @param daily_values A previously create `whitewater::wym_dvUSGS()` object.
#' @param value_name The variable to include as the y-axis.
#' @return
#' @export
#'
#' @examples
ww_monthly_trends <- function(daily_values, value_name) {

  daily_values %>%
    ggplot2::ggplot(ggplot2::aes(wy, {{value_name}}, group = month)) +
    ggplot2::geom_point() +
    ggplot2::geom_line(alpha = 0.75, linewidth = 0.5) +
    ggplot2::geom_smooth(method = 'lm', se = F) +
    ggplot2::scale_y_continuous(labels = scales::comma) +
    ggplot2::facet_wrap(~month, scales = 'free')+
    ggplot2::theme_bw()
}
