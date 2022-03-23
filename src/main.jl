function get_entry(data::Union{I18nData, String}, path)
    for x in path
        data isa I18nData && haskey(data, x) || return nothing
        data = data[x]
    end
    data isa String ? data : nothing
end

function get_fallbacks(ctx::I18nContext, language)
    t = split(language, '_')
    fallbacks = if length(t) > 1
        String[t[1]]
    else
        String[]
    end
    append!(fallbacks, ctx.fallback_rules(language))
    fallbacks
end

function i18n(ctx::I18nContext, key, default = key; language = nothing)
    language = if isnothing(language)
        ctx.current_language
    else
        parse_locale_name(language)
    end
    path = split(key, '.')
    data = ctx.data
    if haskey(data, language)
        entry = get_entry(ctx.data[language], path)
        isnothing(entry) || return entry
    end
    fallbacks = get_fallbacks(ctx, language)
    for lang in fallbacks
        haskey(data, lang) || continue
        entry = get_entry(ctx.data[lang], path)
        isnothing(entry) || return entry
    end
    default
end

i18n(key, default = key; language = nothing) = i18n(
    GLOBAL_I18N_CONTEXT[], key, default, language = language
)

macro i_str(s)
    :(i18n($s))
end
