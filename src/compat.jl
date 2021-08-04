@static if VERSION < v"1.2"
    function hasfield(T::Type, name::Symbol)
        Base.@_pure_meta
        Base.fieldindex(T, name, false) > 0
    end
end
