module Naming # moudle Bukdu

function verb_name(verb)::String
    uppercase(string(nameof(verb)))
end

model_prefix(M::Type)::String                               = string(lowercase(String(nameof(M))), '_')
model_prefix(M::Type, field::Symbol)::String                = string(model_prefix(M), field)
model_prefix(M::Type, field::Symbol, value::String)::String = string(model_prefix(M), field, '_', value)

end # moudle Bukdu.Naming
