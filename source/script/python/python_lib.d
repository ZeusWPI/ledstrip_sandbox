module script.python.python_lib;
// dfmt off

import script.common_lib : CommonLib;
import script.python.python_script_instance : PythonScriptInstance;
import script.python.python_script_instance_thread : PythonScriptInstanceThread;

import std.algorithm : map;
import std.conv : text;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import pyd.embedded : InterpContext;
import pyd.make_object : py;
import pyd.pydobject : PydObject;

import vibe.core.log;

@safe:

class PythonLib
{
    private alias enf = enforce!PythonLibException;

    @disable this();
    @disable this(ref typeof(this));

static:
    @trusted
    PydObject buildGlobals()
    {
        PydObject[string] modules;

        InterpContext ctx = new InterpContext;
        ctx.py_stmts(`
        import json
        class Module:
            def __getitem__(self, key):
                return getattr(self, key)
        `);

        void register(string module_, string name, PydObject obj)
        {
            if (module_ !in modules)
                modules[module_] = ctx.py_eval("Module()");
            enf(!modules[module_].hasattr(name), f!`buildGlobals: Duplicate value "%s.%s"`(module_, name));
            modules[module_].setattr(name, obj);
        }

        void reRegister(string module_, string name)
        {
            PydObject obj = ctx.py_eval(f!"%s.%s"(module_, name));
            register(module_, name, obj);
        }

        void reRegisterBuiltin(string name)
        {
            PydObject obj = ctx.py_eval(name);
            register("__builtins__", name, obj);
        }

        // Values
        reRegisterBuiltin("__debug__");

        // Core
        reRegisterBuiltin("callable");
        reRegisterBuiltin("dir");
        reRegisterBuiltin("eval");
        reRegisterBuiltin("exec");
        reRegisterBuiltin("globals");
        reRegisterBuiltin("hash");
        reRegisterBuiltin("id");
        reRegisterBuiltin("locals");
        reRegisterBuiltin("type");
        reRegisterBuiltin("vars");

        // Type ctors
        reRegisterBuiltin("Ellipsis");
        reRegisterBuiltin("bool");
        reRegisterBuiltin("bytearray");
        reRegisterBuiltin("bytes");
        reRegisterBuiltin("complex");
        reRegisterBuiltin("dict");
        reRegisterBuiltin("float");
        reRegisterBuiltin("frozenset");
        reRegisterBuiltin("int");
        reRegisterBuiltin("list");
        reRegisterBuiltin("memoryview");
        reRegisterBuiltin("object");
        reRegisterBuiltin("set");
        reRegisterBuiltin("slice");
        reRegisterBuiltin("str");
        reRegisterBuiltin("tuple");

        // Attributes
        reRegisterBuiltin("delattr");
        reRegisterBuiltin("getattr");
        reRegisterBuiltin("setattr");
        reRegisterBuiltin("hasattr");

        // Classes
        reRegisterBuiltin("classmethod");
        reRegisterBuiltin("isinstance");
        reRegisterBuiltin("issubclass");
        reRegisterBuiltin("property");
        reRegisterBuiltin("staticmethod");
        reRegisterBuiltin("super");

        // Collections / iteration
        reRegisterBuiltin("aiter");
        reRegisterBuiltin("all");
        reRegisterBuiltin("anext");
        reRegisterBuiltin("any");
        reRegisterBuiltin("enumerate");
        reRegisterBuiltin("filter");
        reRegisterBuiltin("iter");
        reRegisterBuiltin("len");
        reRegisterBuiltin("map");
        reRegisterBuiltin("max");
        reRegisterBuiltin("min");
        reRegisterBuiltin("next");
        reRegisterBuiltin("range");
        reRegisterBuiltin("reversed");
        reRegisterBuiltin("sorted");
        reRegisterBuiltin("sum");
        reRegisterBuiltin("zip");

        // Strings
        reRegisterBuiltin("ascii");
        reRegisterBuiltin("bin");
        reRegisterBuiltin("chr");
        reRegisterBuiltin("format");
        reRegisterBuiltin("hex");
        reRegisterBuiltin("oct");
        reRegisterBuiltin("ord");
        reRegisterBuiltin("repr");

        // Math
        reRegisterBuiltin("abs");
        reRegisterBuiltin("divmod");
        reRegisterBuiltin("pow");
        reRegisterBuiltin("round");

        // Error types
        reRegisterBuiltin("ArithmeticError");
        reRegisterBuiltin("AssertionError");
        reRegisterBuiltin("AttributeError");
        reRegisterBuiltin("BaseException");
        reRegisterBuiltin("BaseExceptionGroup");
        reRegisterBuiltin("BlockingIOError");
        reRegisterBuiltin("BrokenPipeError");
        reRegisterBuiltin("BufferError");
        reRegisterBuiltin("BytesWarning");
        reRegisterBuiltin("ChildProcessError");
        reRegisterBuiltin("ConnectionAbortedError");
        reRegisterBuiltin("ConnectionError");
        reRegisterBuiltin("ConnectionRefusedError");
        reRegisterBuiltin("ConnectionResetError");
        reRegisterBuiltin("DeprecationWarning");
        reRegisterBuiltin("EOFError");
        reRegisterBuiltin("EncodingWarning");
        reRegisterBuiltin("EnvironmentError");
        reRegisterBuiltin("Exception");
        reRegisterBuiltin("ExceptionGroup");
        reRegisterBuiltin("FileExistsError");
        reRegisterBuiltin("FileNotFoundError");
        reRegisterBuiltin("FloatingPointError");
        reRegisterBuiltin("FutureWarning");
        reRegisterBuiltin("GeneratorExit");
        reRegisterBuiltin("IOError");
        reRegisterBuiltin("ImportError");
        reRegisterBuiltin("ImportWarning");
        reRegisterBuiltin("IndentationError");
        reRegisterBuiltin("IndexError");
        reRegisterBuiltin("InterruptedError");
        reRegisterBuiltin("IsADirectoryError");
        reRegisterBuiltin("KeyError");
        reRegisterBuiltin("KeyboardInterrupt");
        reRegisterBuiltin("LookupError");
        reRegisterBuiltin("MemoryError");
        reRegisterBuiltin("ModuleNotFoundError");
        reRegisterBuiltin("NameError");
        reRegisterBuiltin("NotADirectoryError");
        reRegisterBuiltin("NotImplemented");
        reRegisterBuiltin("NotImplementedError");
        reRegisterBuiltin("OSError");
        reRegisterBuiltin("OverflowError");
        reRegisterBuiltin("PendingDeprecationWarning");
        reRegisterBuiltin("PermissionError");
        reRegisterBuiltin("ProcessLookupError");
        reRegisterBuiltin("RecursionError");
        reRegisterBuiltin("ReferenceError");
        reRegisterBuiltin("ResourceWarning");
        reRegisterBuiltin("RuntimeError");
        reRegisterBuiltin("RuntimeWarning");
        reRegisterBuiltin("StopAsyncIteration");
        reRegisterBuiltin("StopIteration");
        reRegisterBuiltin("SyntaxError");
        reRegisterBuiltin("SyntaxWarning");
        reRegisterBuiltin("SystemError");
        reRegisterBuiltin("SystemExit");
        reRegisterBuiltin("TabError");
        reRegisterBuiltin("TimeoutError");
        reRegisterBuiltin("TypeError");
        reRegisterBuiltin("UnboundLocalError");
        reRegisterBuiltin("UnicodeDecodeError");
        reRegisterBuiltin("UnicodeEncodeError");
        reRegisterBuiltin("UnicodeError");
        reRegisterBuiltin("UnicodeTranslateError");
        reRegisterBuiltin("UnicodeWarning");
        reRegisterBuiltin("UserWarning");
        reRegisterBuiltin("ValueError");
        reRegisterBuiltin("Warning");
        reRegisterBuiltin("ZeroDivisionError");

        // Json
        reRegister("json", "JSONDecodeError");
        reRegister("json", "dumps");
        reRegister("json", "loads");

        // Custom builtins
        register("__builtins__", "log", py(&PythonLib.log));

        // Led module
        register("led", "count",    py(CommonLib.LedModule.count));
        register("led", "set",      py(&CommonLib.LedModule.set));
        register("led", "setSlice", py(&CommonLib.LedModule.setSlice));
        register("led", "setAll",   py(&CommonLib.LedModule.setAll));

        // State module
        register("state", "activeName",                       py(&CommonLib.StateModule.activeName));
        register("state", "activeContainsThisScriptInstance", py(&CommonLib.StateModule.activeContainsThisScriptInstance));
        register("state", "setActiveByName",                  py(&CommonLib.StateModule.setActiveByName));
        register("state", "setDefaultActive",                 py(&CommonLib.StateModule.setDefaultActive));

        // Time module
        register("time", "stdTimeHnsecs",   py(&CommonLib.TimeModule.stdTimeHnsecs));
        register("time", "unixTimeSeconds", py(&CommonLib.TimeModule.unixTimeSeconds));
        register("time", "sleepMsecs",      py(&CommonLib.TimeModule.sleepMsecs));
        register("time", "waitFrames",      py(&CommonLib.TimeModule.waitFrames));

        // Mailbox module
        register("mailbox", "subscribe",      py(&CommonLib.MailboxModule.subscribe));
        register("mailbox", "unsubscribe",    py(&CommonLib.MailboxModule.unsubscribe));
        register("mailbox", "unsubscribeAll", py(&CommonLib.MailboxModule.unsubscribeAll));
        register("mailbox", "consume",        py(&CommonLib.MailboxModule.consume));

        return py(modules);
    }

    private
    PythonScriptInstanceThread thread()
        => PythonScriptInstanceThread.instance;

    private
    const(PythonScriptInstanceThread) constThread()
        => PythonScriptInstanceThread.constInstance;

    private
    PythonScriptInstance scriptInstance()
        => thread.pythonScriptInstance;

    private
    const(PythonScriptInstance) constScriptInstance()
        => constThread.constPythonScriptInstance;
    
    @trusted
    void log(PydObject obj)
    {
        logInfo(
            `Script instance "%s": log: %s`,
            constScriptInstance.name,
            (() @trusted => obj.toString)(),
        );
    }
}

class PythonLibException : Exception
{
    mixin basicExceptionCtors;
}
