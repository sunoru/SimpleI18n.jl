get_language(config::I18nConfig = GlobalI18nConfig) = config.current_language
get_language(ctx::I18nContext) = get_language(get_config(ctx))

function set_language!(
    config::I18nConfig,
    locale_name::AbstractString = get_system_language(),
    fallback::Union{AbstractString, AbstractVector{<:AbstractString}} = GlobalI18nConfig.fallback
)
    if fallback isa AbstractString
        fallback = [fallback]
    end
    previous = config.current_language
    locale_name = parse_locale_name(locale_name)
    config.current_language = locale_name
    config.fallback = parse_locale_name.(fallback)
    for func in get(OnLanguageChange, config, [])
        func(locale_name, previous)
    end
    config
end

set_language(
    locale_name::AbstractString = get_system_language(),
    fallback::Union{AbstractString, AbstractVector{<:AbstractString}} = GlobalI18nConfig.fallback
) = set_language!(GlobalI18nConfig, locale_name, fallback)

function set_language!(
    ctx::I18nContext,
    locale_name::Union{AbstractString, Nothing} = nothing,
    fallback::Union{AbstractString, AbstractVector{<:AbstractString}} = get_config(ctx).fallback
)
    config = get_config(ctx)
    if isnothing(locale_name)
        isnothing(config) && return ctx
        ctx.override_config = nothing
        pop!(OnLanguageChange, config, nothing)
        return ctx
    end
    if isnothing(config)
        config = ctx.config = I18nConfig()
    end
    set_language!(config, locale_name, fallback)
end

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
        get_language(ctx)
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
