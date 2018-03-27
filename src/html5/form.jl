module Form # Bukdu.HTML5

export change, form_for, text_input, submit

import ...Bukdu: ApplicationController, Assoc, Changeset, Router, Naming, post
import Documenter.Utilities.DOM: @tags

"""
    change(M::Type, params::Assoc)::Changeset
"""
function change(M::Type, params::Assoc)::Changeset
    modelnameprefix = Naming.model_prefix(M)
    ntkeys = []
    ntvalues = []
    modelfieldnames = fieldnames(M)
    for (idx::Int, (k::String, v)) in pairs(params)
        if startswith(k, modelnameprefix)
            key = Symbol(k[length(modelnameprefix)+1:end])
            if key in modelfieldnames
                typ = fieldtype(M, key)
                push!(ntkeys, key)
                if typ === Any || typ === String
                    push!(ntvalues, v)
                else
                    push!(ntvalues, parse(typ, v))
                end
            elseif key != Symbol("")
                push!(ntkeys, key)
                push!(ntvalues, v)
            end
        end
    end
    changes = NamedTuple{tuple(ntkeys...)}(tuple(ntvalues...))
    Changeset(M, changes)
end

"""
    change(changeset::Changeset, params::Assoc; primary_key::Union{String,Nothing}=nothing)::Changeset
"""
function change(changeset::Changeset, params::Assoc; primary_key::Union{String,Nothing}=nothing)::Changeset
    p = change(changeset.model, params)
    nt = changeset.changes
    ntkeys = []
    ntvalues = []
    for (k::Symbol, v) in pairs(p.changes)
        if haskey(nt, k)
            typ = typeof(nt[k])
            if v isa typ
                val = v
            else
                val = parse(typ, v)
            end
            if val == nt[k]
                if !(primary_key isa Nothing) && Symbol(primary_key) == k
                    push!(ntkeys, k)
                    push!(ntvalues, val)
                end
            else
                push!(ntkeys, k)
                push!(ntvalues, val)
            end
        end
    end
    changes = NamedTuple{tuple(ntkeys...)}(tuple(ntvalues...))
    Changeset(changeset.model, changes)
end

"""
    form_for(f, changeset::Changeset, controller_action::Tuple; method=post, kwargs...)
"""
function form_for(f, changeset::Changeset, controller_action::Tuple; method=post, kwargs...)
    (C, action) = controller_action
    form_action = Router.Helpers.url_path(method, C, action)
    form_for(f, changeset, form_action; method=method, kwargs...)
end

"""
    form_for(f, changeset::Changeset, form_action::String; method=post, multipart::Bool=false)
"""
function form_for(f, changeset::Changeset, form_action::String; method=post, multipart::Bool=false)
    @tags form
    attrs = [:action => form_action, :method => Naming.verb_name(method)]
    multipart && push!(attrs, :enctype => "multipart/form-data")
    form[attrs...](f(changeset))
end

function form_value(f::Changeset, field::Symbol, value)
    if value isa Nothing
        get(f.changes, field, "")
    else
        value
    end
end

"""
    text_input(f::Changeset, field::Symbol, value=nothing; kwargs...)
"""
function text_input(f::Changeset, field::Symbol, value=nothing; kwargs...)
    @tags input
    name = Naming.model_prefix(f.model, field)
    input[:id => name,
          :name => name,
          :type => "text",
          :value => form_value(f, field, value),
          kwargs...]()
end

"""
    submit(block_option)
"""
function submit(block_option)
    @tags button
    button[:type => "submit"](block_option)
end

end # module Bukdu.HTML5.Form
