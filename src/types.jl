using MacroTools: @forward


Base.@kwdef struct I18nData
    data::Dict{String, Union{I18nData, String}} = Dict()
end
@forward I18nData.data Base.haskey, Base.keys, Base.values, Base.get, Base.get!, Base.getindex, Base.setindex!

Base.@kwdef mutable struct I18nConfig
    current_language::String = get_system_language()
    fallback::Vector{String} = String[]
end

Base.@kwdef mutable struct I18nContext{T <: Function}
    data::I18nData = I18nData()
    srcpath::String = ""
    override_config::Union{Nothing, I18nConfig} = nothing
    fallback::T
end
get_config(ctx::I18nContext) = if isnothing(ctx.override_config)
    GlobalI18nConfig
else
    ctx.override_config
end

const GlobalI18nConfig = I18nConfig()

const I18nContexts = Dict{Module, I18nContext}()

const OnLanguageChange = Dict{I18nConfig, Set{Function}}()
