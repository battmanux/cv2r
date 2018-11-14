py_inject_r <- function (envir) 
{
    reticulate::py_run_string("class R(object): pass")
    main <- reticulate::import_main(convert = F)
    R <- main$R
    if (is.null(envir)) {
        .knitEnv <- yoink("knitr", ".knitEnv")
        envir <- .knitEnv$knit_global
    }
    getter <- function(self, code) {
        
        str_code <- reticulate:::as_r_value(code)
        r_variable <- eval(parse(text = str_code), envir = envir)
        
        if ( is.function(r_variable) ) {
            main_f <- reticulate::import_main(convert = T) # convert required for functions
            main_f[[paste0("_r_",str_code)]]  <-  r_variable
            return(reticulate::py_eval(paste0("_r_",str_code)))
        }
        
        return(r_to_py(r_variable))
    }
    setter <- function(self, name, value) {
        envir[[reticulate:::as_r_value(name)]] <<- reticulate:::as_r_value(value)
    }
    reticulate::py_set_attr(R, "__getattr__", getter)
    reticulate::py_set_attr(R, "__setattr__", setter)
    reticulate::py_set_attr(R, "__getitem__", getter)
    reticulate::py_set_attr(R, "__setitem__", setter)
    reticulate::py_run_string("r = R()")
}
