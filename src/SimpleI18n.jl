module SimpleI18n

export get_language, set_language, set_language!,
    i18n, @i_str

include("utils.jl")
include("locales.jl")
include("types.jl")
include("fallback.jl")
include("setup.jl")
include("main.jl")

end # module
