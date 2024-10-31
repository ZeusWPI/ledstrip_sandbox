module script.python.python_lib;
// dfmt off

import script.common_lib : CommonLib;
import script.python.python_script : PythonScript;
import script.python.python_script_task : PythonScriptTask;

import std.algorithm : map;
import std.conv : text;
import std.exception : basicExceptionCtors, enforce;
import std.format : f = format;

import pyd.embedded : py_eval;
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
        PydObject[string][string] modules;

        void register(string module_, string name, PydObject obj)
        {
            if (module_ !in modules)
                modules[module_] = null;
            enf(name !in modules[module_], f!`buildGlobals: Duplicate value "%s.%s"`(module_, name));
            modules[module_][name] = obj;
        }

        void registerBuiltin(string name)
        {
            register("__builtins__", name, py_eval(name));
        }

        // Values
        registerBuiltin("__debug__");

        // Core
        registerBuiltin("callable");
        registerBuiltin("dir");
        registerBuiltin("eval");
        registerBuiltin("exec");
        registerBuiltin("globals");
        registerBuiltin("hash");
        registerBuiltin("id");
        registerBuiltin("locals");
        registerBuiltin("type");
        registerBuiltin("vars");

        // Type ctors
        registerBuiltin("Ellipsis");
        registerBuiltin("bool");
        registerBuiltin("bytearray");
        registerBuiltin("bytes");
        registerBuiltin("complex");
        registerBuiltin("dict");
        registerBuiltin("float");
        registerBuiltin("frozenset");
        registerBuiltin("int");
        registerBuiltin("list");
        registerBuiltin("memoryview");
        registerBuiltin("object");
        registerBuiltin("set");
        registerBuiltin("slice");
        registerBuiltin("str");
        registerBuiltin("tuple");

        // Attributes
        registerBuiltin("delattr");
        registerBuiltin("getattr");
        registerBuiltin("setattr");
        registerBuiltin("hasattr");

        // Classes
        registerBuiltin("classmethod");
        registerBuiltin("isinstance");
        registerBuiltin("issubclass");
        registerBuiltin("property");
        registerBuiltin("staticmethod");
        registerBuiltin("super");

        // Collections / iteration
        registerBuiltin("aiter");
        registerBuiltin("all");
        registerBuiltin("anext");
        registerBuiltin("any");
        registerBuiltin("enumerate");
        registerBuiltin("filter");
        registerBuiltin("iter");
        registerBuiltin("len");
        registerBuiltin("map");
        registerBuiltin("max");
        registerBuiltin("min");
        registerBuiltin("next");
        registerBuiltin("range");
        registerBuiltin("reversed");
        registerBuiltin("sorted");
        registerBuiltin("sum");
        registerBuiltin("zip");

        // Strings
        registerBuiltin("ascii");
        registerBuiltin("bin");
        registerBuiltin("chr");
        registerBuiltin("format");
        registerBuiltin("hex");
        registerBuiltin("oct");
        registerBuiltin("ord");
        registerBuiltin("repr");

        // Math
        registerBuiltin("abs");
        registerBuiltin("divmod");
        registerBuiltin("pow");
        registerBuiltin("round");

        // Error types
        registerBuiltin("ArithmeticError");
        registerBuiltin("AssertionError");
        registerBuiltin("AttributeError");
        registerBuiltin("BaseException");
        registerBuiltin("BaseExceptionGroup");
        registerBuiltin("BlockingIOError");
        registerBuiltin("BrokenPipeError");
        registerBuiltin("BufferError");
        registerBuiltin("BytesWarning");
        registerBuiltin("ChildProcessError");
        registerBuiltin("ConnectionAbortedError");
        registerBuiltin("ConnectionError");
        registerBuiltin("ConnectionRefusedError");
        registerBuiltin("ConnectionResetError");
        registerBuiltin("DeprecationWarning");
        registerBuiltin("EOFError");
        registerBuiltin("EncodingWarning");
        registerBuiltin("EnvironmentError");
        registerBuiltin("Exception");
        registerBuiltin("ExceptionGroup");
        registerBuiltin("FileExistsError");
        registerBuiltin("FileNotFoundError");
        registerBuiltin("FloatingPointError");
        registerBuiltin("FutureWarning");
        registerBuiltin("GeneratorExit");
        registerBuiltin("IOError");
        registerBuiltin("ImportError");
        registerBuiltin("ImportWarning");
        registerBuiltin("IndentationError");
        registerBuiltin("IndexError");
        registerBuiltin("InterruptedError");
        registerBuiltin("IsADirectoryError");
        registerBuiltin("KeyError");
        registerBuiltin("KeyboardInterrupt");
        registerBuiltin("LookupError");
        registerBuiltin("MemoryError");
        registerBuiltin("ModuleNotFoundError");
        registerBuiltin("NameError");
        registerBuiltin("NotADirectoryError");
        registerBuiltin("NotImplemented");
        registerBuiltin("NotImplementedError");
        registerBuiltin("OSError");
        registerBuiltin("OverflowError");
        registerBuiltin("PendingDeprecationWarning");
        registerBuiltin("PermissionError");
        registerBuiltin("ProcessLookupError");
        registerBuiltin("RecursionError");
        registerBuiltin("ReferenceError");
        registerBuiltin("ResourceWarning");
        registerBuiltin("RuntimeError");
        registerBuiltin("RuntimeWarning");
        registerBuiltin("StopAsyncIteration");
        registerBuiltin("StopIteration");
        registerBuiltin("SyntaxError");
        registerBuiltin("SyntaxWarning");
        registerBuiltin("SystemError");
        registerBuiltin("SystemExit");
        registerBuiltin("TabError");
        registerBuiltin("TimeoutError");
        registerBuiltin("TypeError");
        registerBuiltin("UnboundLocalError");
        registerBuiltin("UnicodeDecodeError");
        registerBuiltin("UnicodeEncodeError");
        registerBuiltin("UnicodeError");
        registerBuiltin("UnicodeTranslateError");
        registerBuiltin("UnicodeWarning");
        registerBuiltin("UserWarning");
        registerBuiltin("ValueError");
        registerBuiltin("Warning");
        registerBuiltin("ZeroDivisionError");

        // Custom builtins
        register("__builtins__", "log", py(&PythonLib.log));

        // Led module
        register("led", "count",    py(CommonLib.LedModule.count));
        register("led", "set",      py(&CommonLib.LedModule.set));
        register("led", "setSlice", py(&CommonLib.LedModule.setSlice));
        register("led", "setAll",   py(&CommonLib.LedModule.setAll));

        // State module
        register("state", "activeName",               py(&CommonLib.StateModule.activeName));
        register("state", "activeContainsThisScript", py(&CommonLib.StateModule.activeContainsThisScript));
        register("state", "setActiveByName",          py(&CommonLib.StateModule.setActiveByName));
        register("state", "setDefaultActive",         py(&CommonLib.StateModule.setDefaultActive));

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
    PythonScriptTask task()
        => PythonScriptTask.instance;

    private
    const(PythonScriptTask) constTask()
        => PythonScriptTask.constInstance;

    private
    PythonScript script()
        => task.pythonScript;

    private
    const(PythonScript) constScript()
        => constTask.constPythonScript;
    
    @trusted
    void log(PydObject obj)
    {
        logInfo(
            `Script "%s": log: %s`,
            constScript.name,
            (() @trusted => obj.toString)(),
        );
    }
}

class PythonLibException : Exception
{
    mixin basicExceptionCtors;
}
