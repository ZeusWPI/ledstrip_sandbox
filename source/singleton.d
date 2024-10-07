module singleton;

@safe:

mixin template sharedSingleton(bool customCreateInstance = false)
{
    static assert(is(typeof(this) == class));
    static assert(is(typeof(this) == shared));

    private static typeof(this) s_instance;

    static if (!customCreateInstance)
    {
        public static
        void createInstance()
        in (s_instance is null)
        out (; s_instance !is null)
        {
            try
            {
                s_instance = new typeof(this);
            }
            catch (Exception e)
            {
                enum string name = typeof(this).stringof;
                string msg = (() @trusted => e.toString)();
                assert(false, f!`Failed to create instance of singleton "%s": %s`(name, msg));
            }
        }
    }

    @disable this(ref typeof(this));

    static nothrow @nogc
    typeof(this) instance()
    in (s_instance !is null, typeof(this).stringof ~ ".s_instance is null")
        => s_instance;

    static nothrow @nogc
    const(typeof(this)) constInstance()
    in (s_instance !is null, typeof(this).stringof ~ ".s_instance is null")
        => s_instance;
}

mixin template threadLocalSingleton(bool customCreateInstance = false)
{
    static assert(is(typeof(this) == class));
    static assert(!is(typeof(this) == shared));

    private static typeof(this) tls_instance;

    static if (!customCreateInstance)
    {
        public static
        void createInstance()
        in (tls_instance is null)
        out (; tls_instance !is null)
        {
            try
            {
                tls_instance = new typeof(this);
            }
            catch (Exception e)
            {
                import std.format : f = format;

                enum string name = typeof(this).stringof;
                string msg = (() @trusted => e.toString)();
                assert(false, f!`Failed to create instance of singleton "%s": %s`(name, msg));
            }
        }
    }

    static nothrow @nogc
    typeof(this) instance()
    in (tls_instance !is null, typeof(this).stringof ~ ".tls_instance is null")
        => tls_instance;

    static nothrow @nogc
    const(typeof(this)) constInstance()
    in (tls_instance !is null, typeof(this).stringof ~ ".tls_instance is null")
        => tls_instance;
}
