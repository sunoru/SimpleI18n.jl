using MacroTools: @forward

default_fallback_rule(_) = [get_system_language()]

Base.@kwdef struct I18nData
    data::Dict{String, Union{I18nData, String}} = Dict()
end
@forward I18nData.data Base.haskey, Base.get, Base.get!, Base.getindex, Base.setindex!

Base.@kwdef mutable struct I18nContext{T <: Function}
    current_language::String = get_system_language()
    fallback_rules::T = default_fallback_rule
    data::I18nData = I18nData()
end

const GLOBAL_I18N_CONTEXT = Ref{I18nContext}(I18nContext())
