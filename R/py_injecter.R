#' Fix reticulate injecter so that functions are supported
#'
#' See [https://github.com/rstudio/reticulate/pull/384]
#'
#' @param envir envir to be exposed to python
#'
py_inject_r <- function (envir)
{
    as_r_value <- function (x) 
    {
        if (inherits(x, "python.builtin.object")) 
            reticulate::py_to_r(x)
        else x
    }
    
    reticulate::py_run_string("class R(object): pass")
    main <- reticulate::import_main(convert = F)
    R <- main$R
    
    getter <- function(self, code) {

        object <- eval(parse(text = as_r_value(code)), envir = envir)
        reticulate::r_to_py(object, convert = is.function(object))

    }
    setter <- function(self, name, value) {
        envir[[as_r_value(name)]] <<- as_r_value(value)
    }
    reticulate::py_set_attr(R, "__getattr__", getter)
    reticulate::py_set_attr(R, "__setattr__", setter)
    reticulate::py_set_attr(R, "__getitem__", getter)
    reticulate::py_set_attr(R, "__setitem__", setter)
    reticulate::py_run_string("r = R()")
}
