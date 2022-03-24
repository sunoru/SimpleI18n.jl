import YAML


parse_locale_data(data::String, _) = data
parse_locale_data(data, locale_root) = I18nData(
    data = Dict(
        (locale_root ? parse_locale_name(key) : key) =>
        parse_locale_data(value, false)
        for (key, value) in data
    )
)

function load_locale_file(locale_file, locale_root = true)
    data = YAML.load_file(locale_file)
    parse_locale_data(data, locale_root)
end

load_locale_dir(locale_dir) = I18nData(
    data = Dict(
        parse_locale_name(basename(file)) =>
        load_locale_file(joinpath(locale_dir, file), false)
        for file in readdir(locale_dir)
    )
)

"""
    link(src_module, dest_module)

Link the i18n data of `dest_module` to `src_module`.
"""
function link(src_module::Module, dest_module::Module)
    ctx = get!(I18nContexts, dest_module) do
        I18nContext()
    end
    I18nContexts[src_module] = ctx
end

"""
    setup([module=current_module], locale_file_or_dir, fallback)

Setup the i18n data for `module`. `fallback` can be one of the following (with examples):

    * A string: `"en"`
    * A list of strings: `["zh", "en"]`
    * A Dict{String, Vector{String}}: `Dict("zh" => ["zh-CN", "zh-TW"], "_" => ["en"])`
    * A function from language code to a vector of language codes: `(language) -> ["zh", "en"]`
"""
function setup(
    current_module::Module,
    locale_file_or_dir::AbstractString,
    fallback
)
    data = if isdir(locale_file_or_dir)
        load_locale_dir(locale_file_or_dir)
    elseif isfile(locale_file_or_dir)
        load_locale_file(locale_file_or_dir)
    else
        @info "I18n file not found: $locale_file_or_dir"
        I18nData()
    end
    ctx = I18nContext(
        data = data,
        srcpath = locale_file_or_dir,
        fallback = get_fallback_function(data, fallback)
    )
    I18nContexts[current_module] = ctx
end

@noinline setup(locale_file_or_dir, default_fallback) = setup(@caller_module(3), locale_file_or_dir, default_fallback)

"""
    on_language_changed(callback)

`callback(language, previous_langauge)` will be called when the language is changed.
"""
function on_language_changed(callback)
    callback(get_language(), "")
    push!(OnLanguageChange, callback)
    nothing
end