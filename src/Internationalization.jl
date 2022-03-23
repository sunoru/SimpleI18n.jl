module Internationalization

export get_system_language, setup_i18n, i18n, @i_str
include("locales.jl")
include("context.jl")
include("setup.jl")
include("main.jl")

end # module
