get_module(method_instance::Core.MethodInstance) = method_instance.def.module
get_module(_) = Main

# Not sure if this is the best way to do this.
macro caller_module(i)
    quote
        st = stacktrace()
        get_module(st[$i].linfo)
    end
end
