function default_fallback_function(
    data::I18nData,
    default_languages::AbstractVector{<:AbstractString}
)
    default_languages = parse_locale_name.(default_languages)
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
        append!(fallbacks, default_languages)
        fallbacks
    end
end


get_fallback_function(data::I18nData, fallback::AbstractString) = default_fallback_function(data, [fallback])
get_fallback_function(data::I18nData, fallback::AbstractVector{<:AbstractString}) =
    default_fallback_function(data, fallback)
get_fallback_function(_::I18nData, fallback::AbstractDict) = (lang) -> begin
    langs = get(fallback, lang, nothing)
    isnothing(langs) || return langs
    get(fallback, "_", String[])
end
get_fallback_function(_::I18nData, fallback::Function) = fallback
