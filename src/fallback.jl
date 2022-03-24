function default_fallback_function(
    data::I18nData,
    default_languages::AbstractDict
)
    default_languages = Dict(
        string(key) => parse_locale_name.(value)
        for (key, value) in default_languages
    )
    if !haskey(default_languages, "_")
        default_languages["_"] = String[]
    end
    cached = Dict{String, Vector{String}}()
    (lang) -> get!(cached, lang) do
        t = split(lang, '_')
        base_lang = t[1]
        fallbacks = if length(t) > 1 && haskey(data, base_lang)
            String[base_lang]
        else
            String[]
        end
        append!(fallbacks, String[
            key for key in keys(data)
            if key != lang && contains(key, "_") && startswith(key, base_lang)
        ])
        append!(fallbacks, GlobalI18nConfig.fallback)
        append!(fallbacks, get(default_languages, lang, default_languages["_"]))
        fallbacks
    end
end


get_fallback_function(data::I18nData, fallback::AbstractString) = get_fallback_function(data, [fallback])
get_fallback_function(data::I18nData, fallback::AbstractVector{<:AbstractString}) =
    default_fallback_function(data, Dict("_" => fallback))
get_fallback_function(_::I18nData, fallback::AbstractDict) =
    default_fallback_function(data, fallback)
get_fallback_function(_::I18nData, fallback::Function) = fallback
