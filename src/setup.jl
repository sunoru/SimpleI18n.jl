import YAML

function parse_locale_name(locale)
    locale = split(locale, '.')[1]
    locale = replace(locale, '-' => '_')
    lowercase(locale)
end

parse_locale_data(data::String, _) = data
parse_locale_data(data, locale_root) = I18nData(
    data = Dict(
        (locale_root ? parse_locale_name(key) : key) =>
        parse_locale_data(value, false)
        for (key, value) in data
    )
)

function load_locales_file(locales_file, locale_root = true)
    data = YAML.load_file(locales_file)
    parse_locale_data(data, locale_root)
end

load_locales_dir(locales_dir) = I18nData(
    data = Dict(
        parse_locale_name(basename(file)) =>
        load_locales_file(joinpath(locales_dir, file), false)
        for file in readdir(locales_dir)
    )
)


function setup_i18n(;
    locale_name = get_system_language(),
    locales_dir = nothing,
    locales_file = nothing,
    fallback = nothing,
    set_global = true
)
    pctx = GLOBAL_I18N_CONTEXT[]
    current_language = parse_locale_name(locale_name)
    system_language = get_system_language()
    fallback_rules = if isnothing(fallback)
        set_global ? pctx.fallback_rules : default_fallback_rule
    elseif fallback isa Dict
        (lang) -> get(fallback, lang, system_language)
    elseif fallback isa Function
        fallback
    elseif fallback isa AbstractString
        fallback = string(fallback)
        (_) -> [fallback]
    else
        default_fallback_rule
    end
    data = if !isnothing(locales_file)
        load_locales_file(locales_file)
    elseif !isnothing(locales_dir)
        load_locales_dir(locales_dir)
    elseif set_global
        pctx.data
    else
        I18nData()
    end
    ctx = I18nContext(
        current_language = current_language,
        fallback_rules = fallback_rules,
        data = data
    )
    if set_global
        GLOBAL_I18N_CONTEXT[] = ctx
    end
    ctx
end

setup_i18n(locale_name_or_file; kwargs...) = if isdir(locale_name_or_file)
    setup_i18n(locales_dir = locale_name_or_file; kwargs...)
elseif isfile(locale_name_or_file)
    setup_i18n(locales_file = locale_name_or_file; kwargs...)
else
    setup_i18n(locale_name = locale_name_or_file; kwargs...)
end
