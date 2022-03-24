get_language() = GlobalI18nConfig.current_language

function set_language(
    locale_name::AbstractString = get_system_language(),
    fallback::AbstractVector{<:AbstractString} = GlobalI18nConfig.fallback
)
    locale_name = parse_locale_name(locale_name)
    GlobalI18nConfig.current_language = locale_name
    GlobalI18nConfig.fallback = parse_locale_name.(fallback)
    nothing
end
set_language(locale_name, fallback::AbstractString) = set_language(locale_name, [fallback])

function get_entry(data::Union{I18nData, String}, path)
    for x in path
        data isa I18nData && haskey(data, x) || return nothing
        data = data[x]
    end
    data isa String ? data : nothing
end

function try_languages(ctx::I18nContext, path, languages)
    data = ctx.data
    for lang in languages
        haskey(data, lang) || continue
        entry = get_entry(ctx.data[lang], path)
        isnothing(entry) || return entry
    end
end

function i18n(ctx::I18nContext, key, default = key; language = nothing)
    language = if isnothing(language)
        GlobalI18nConfig.current_language
    else
        parse_locale_name(language)
    end
    path = split(key, '.')
    entry = try_languages(ctx, path, [language])
    isnothing(entry) || return entry
    entry = try_languages(ctx, path, ctx.fallback(language))
    isnothing(entry) ? default : entry
end

function i18n(current_module::Module, key, default = key; language = nothing)
    ctx = get(I18nContexts, current_module, nothing)
    isnothing(ctx) && return default
    i18n(ctx, key, default, language = language)
end

@noinline function i18n(key, default = key; language = nothing) 
    current_module = @caller_module(5)
    i18n(current_module, key, default, language = language)
end

macro i_str(s)
    :(i18n(@caller_module(2), $s))
end
