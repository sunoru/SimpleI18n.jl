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
    fallback::T
end

const GlobalI18nConfig = I18nConfig()

const I18nContexts = Dict{Module, I18nContext}()
