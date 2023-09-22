
#' Richards-Baker Flashiness index (RBI)
#' @description Adds RBI of observation (flow).
#'
#' @param data A daily value data.frame.
#' @param flow_var A column name for flow, e.g. Flow.
#' @param ... values to pass to `dplyr::group_by()` to perform RBI calculation on. (optional)
#'
#' @return A rbi column within data.frame.
#' @note The user must specify the `flow_var` column but it's optional whether to use `dplyr::group_by()` or not.
#' @export
#'
#' @examples
#' stream_flow <- data.frame(flow = c(seq(30, 60), seq(60, 30, length.out = 60)))
#' stream_flow %>% ww_get_rbi(flow)

ww_get_rbi <- function(data, flow_var, ...) {

  data %>%
    dplyr::mutate(lagged_flow = dplyr::lag({{flow_var}})) %>%
    dplyr::group_by(...) %>%
    dplyr::transmute(rbi = sum(abs({{flow_var}}-lagged_flow), na.rm = T)/sum({{flow_var}}, na.rm = T)) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup()

}


#' Rolling Stats
#' @description Adds rolling stats based on window size.
#'
#' @param data A data.frame.
#' @param vars A vector of columns names to mutate.
#' @param ... values to pass to `slider::slide()`, e.g. `.after = 7`.
#'
#' @return Returns numerous stats (mean, median, sd) based on a rolling window.
#' @note The user must specify the `vars` used but has more flexibility with inputs to `slider::slide()`. In addition, this is assuming that
#' all of your data is complete and has no magic to know otherwise.
#' @export
#'
#' @examples
#' rolling_flow <- data.frame(flow = c(seq(30, 60), seq(60, 30, length.out = 60)))
#' rolling_flow %>% ww_get_rolling(vars = 'Flow', .after = 7)

ww_get_rolling <- function(data, vars, ...) {

  data %>%
  dplyr::mutate(dplyr::across(dplyr::any_of(vars),
                              list(
                                sum = ~as.numeric(slider::slide(.x, ~sum(.x, na.rm = T), ...)),
                                max = ~as.numeric(slider::slide(.x, ~max(.x, na.rm = T), ...)),
                                min = ~as.numeric(slider::slide(.x, ~min(.x, na.rm = T), ...)),
                                mean = ~as.numeric(slider::slide(.x, ~mean(.x, na.rm = T), ...)),
                                median = ~as.numeric(slider::slide(.x, ~median(.x, na.rm = T), ...)),
                                stdev = ~as.numeric(slider::slide(.x, ~sd(.x, na.rm = T), ...)),
                                coef_var = ~as.numeric(slider::slide(.x, ~sd(.x, na.rm = T), ...))/as.numeric(slider::slide(.x, ~mean(.x, na.rm = T), ...))),
                              .names = "{.col}_rolling_{.fn}"))

}



