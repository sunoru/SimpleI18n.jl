import YAML


parse_locale_data(data::String, _) = data
parse_locale_data(data::AbstractVector{String}, _) = join(data, '\n')
parse_locale_data(data, locale_root) = I18nData(
    data = Dict(
        (locale_root ? parse_locale_name(key) : key) =>
        parse_locale_data(value, false)
        for (key, value) in data
    )
)

function load_locale_file(locale_file, locale_root = true)
    if isfile(locale_file) && endswith(locale_file, r".yaml|.yml"i)
        data = YAML.load_file(locale_file)
        parse_locale_data(data, locale_root)
    elseif isdir(locale_file)
        dict = Dict{String, Union{I18nData, String}}()
        for file in readdir(locale_file)
            filename = splitext(file)[1]
            filename = locale_root ? parse_locale_name(filename) : filename
            data = load_locale_file(joinpath(locale_file, file), false)
            if haskey(dict, filename)
                merge!(dict[filename].data, data.data)
            else
                dict[filename] = data
            end
        end
        I18nData(dict)
    end
end

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
    data = load_locale_file(locale_file_or_dir)
    if isnothing(data)
        @warn "I18n file not found: $locale_file_or_dir"
        data = I18nData()
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
    on_language_changed(callback, [config_or_context])

`callback(language, previous_langauge)` will be called when the language is changed.
"""
function on_language_changed(callback, config::I18nConfig = GlobalI18nConfig)
    callback(get_language(), "")
    callbacks = get!(OnLanguageChange, config) do
        Set{Function}()
    end
    push!(callbacks, callback)
    config
end
on_language_changed(callback, config::I18nContext) = on_language_changed(callback, get_config(config))
