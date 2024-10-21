---@meta _

---
---A global variable (not a function) that holds the global environment (see [§2.2](http://www.lua.org/manual/5.1/manual.html#2.2)). Lua itself does not use this variable; changing its value does not affect any environment, nor vice versa.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-_G)
---
---@class _G
_G = {}

---
---A global variable (not a function) that holds a string containing the running Lua version.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-_VERSION)
---
_VERSION = "Lua 5.1"

---@alias type
---| "nil"
---| "number"
---| "string"
---| "boolean"
---| "table"
---| "function"
---| "thread"
---| "userdata"

---
---Returns the type of its only argument, coded as a string. The possible results of this function are `"nil"` (a string, not the value `nil`), `"number"`, `"string"`, `"boolean"`, `"table"`, `"function"`, `"thread"`, and `"userdata"`.
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-type)
---
---@param v any
---@return type type
---@nodiscard
function type(v) end

---
---Raises an error if the value of its argument v is false (i.e., `nil` or `false`); otherwise, returns all its arguments. In case of error, `message` is the error object; when absent, it defaults to `"assertion failed!"`
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-assert)
---
---@generic T
---@param v? T
---@param message? any
---@param ... any
---@return T
---@return any ...
function assert(v, message, ...) end

---
---Terminates the last protected function called and returns message as the error object.
---
---Usually, `error` adds some information about the error position at the beginning of the message, if the message is a string.
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-error)
---
---@param message any
---@param level?  integer
function error(message, level) end

---
---Calls the function `f` with the given arguments in *protected mode*. This means that any error inside `f` is not propagated; instead, `pcall` catches the error and returns a status code. Its first result is the status code (a boolean), which is true if the call succeeds without errors. In such case, `pcall` also returns all results from the call, after this first result. In case of any error, `pcall` returns `false` plus the error object.
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-pcall)
---
---@param f     async fun(...):...
---@param arg1? any
---@param ...   any
---@return boolean success
---@return any result
---@return any ...
function pcall(f, arg1, ...) end

---
---Calls function `f` with the given arguments in protected mode with a new message handler.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-xpcall)
---
---@param f     async fun(...):...
---@param msgh  function
---@param arg1? any
---@param ...   any
---@return boolean success
---@return any result
---@return any ...
function xpcall(f, msgh, arg1, ...) end

---
---When called with no `base`, `tonumber` tries to convert its argument to a number. If the argument is already a number or a string convertible to a number, then `tonumber` returns this number; otherwise, it returns `fail`.
---
---The conversion of strings can result in integers or floats, according to the lexical conventions of Lua (see [§3.1](http://www.lua.org/manual/5.1/manual.html#3.1)). The string may have leading and trailing spaces and a sign.
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-tonumber)
---
---@overload fun(e: string, base: integer):integer
---@param e any
---@return number?
---@nodiscard
function tonumber(e) end

---
---Receives a value of any type and converts it to a string in a human-readable format.
---
---If the metatable of `v` has a `__tostring` field, then `tostring` calls the corresponding value with `v` as argument, and uses the result of the call as its result. Otherwise, if the metatable of `v` has a `__name` field with a string value, `tostring` may use that string in its final result.
---
---For complete control of how numbers are converted, use [string.format](http://www.lua.org/manual/5.1/manual.html#pdf-string.format).
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-tostring)
---
---@param v any
---@return string
---@nodiscard
function tostring(v) end

---
---Returns the elements from the given `list`. This function is equivalent to
---```lua
---    return list[i], list[i+1], ···, list[j]
---```
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-unpack)
---
---@generic T
---@param list T[]
---@param i?   integer
---@param j?   integer
---@return T   ...
---@nodiscard
function unpack(list, i, j) end

---@generic T1, T2, T3, T4, T5, T6, T7, T8, T9
---@param list {[1]: T1, [2]: T2, [3]: T3, [4]: T4, [5]: T5, [6]: T6, [7]: T7, [8]: T8, [9]: T9 }
---@return T1, T2, T3, T4, T5, T6, T7, T8, T9
---@nodiscard
function unpack(list) end

---
---Returns three values (an iterator function, the table `t`, and `0`) so that the construction
---```lua
---    for i,v in ipairs(t) do body end
---```
---will iterate over the key–value pairs `(1,t[1]), (2,t[2]), ...`, up to the first absent index.
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-ipairs)
---
---@generic T: table, V
---@param t T
---@return fun(table: V[], i?: integer):integer, V
---@return T
---@return integer i
function ipairs(t) end

---
---Allows a program to traverse all fields of a table. Its first argument is a table and its second argument is an index in this table. A call to `next` returns the next index of the table and its associated value. When called with `nil` as its second argument, `next` returns an initial index and its associated value. When called with the last index, or with `nil` in an empty table, `next` returns `nil`. If the second argument is absent, then it is interpreted as `nil`. In particular, you can use `next(t)` to check whether a table is empty.
---
---The order in which the indices are enumerated is not specified, *even for numeric indices*. (To traverse a table in numerical order, use a numerical `for`.)
---
---The behavior of `next` is undefined if, during the traversal, you assign any value to a non-existent field in the table. You may however modify existing fields. In particular, you may set existing fields to nil.
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-next)
---
---@generic K, V
---@param table table<K, V>
---@param index? K
---@return K?
---@return V?
---@nodiscard
function next(table, index) end

---
---If `t` has a metamethod `__pairs`, calls it with t as argument and returns the first three results from the call.
---
---Otherwise, returns three values: the [next](http://www.lua.org/manual/5.1/manual.html#pdf-next) function, the table `t`, and `nil`, so that the construction
---```lua
---    for k,v in pairs(t) do body end
---```
---will iterate over all key–value pairs of table `t`.
---
---See function [next](http://www.lua.org/manual/5.1/manual.html#pdf-next) for the caveats of modifying the table during its traversal.
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-pairs)
---
---@generic T: table, K, V
---@param t T
---@return fun(table: table<K, V>, index?: K):K, V
---@return T
function pairs(t) end

---
---If `index` is a number, returns all arguments after argument number `index`; a negative number indexes from the end (`-1` is the last argument). Otherwise, `index` must be the string `"#"`, and `select` returns the total number of extra arguments it received.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-select)
---
---@param index integer|"#"
---@param ...   any
---@return any
---@nodiscard
function select(index, ...) end


---Receives any number of arguments and prints their values to the syslog.
---@param ... any
function log(...) end


---Led module.
---@class ledlib
---
---The total number of leds. Does not change during script execution.
---@field count number
led = {}

---Sets the led at `index` to the color `r`, `g`, `b`.
---@param index number
---@param r number
---@param g number
---@param b number
function led.set(index, r, g, b) end

---
---Sets the leds starting from index `begin` up to `end` (exclusive) to the color `r`, `g`, `b`.
---
---@param begin number
---@param end number
---@param r number
---@param g number
---@param b number
function led.setSlice(begin, end, r, g, b) end

---
---Sets all leds to the color `r`, `g`, `b`.
---
---@param r number
---@param g number
---@param b number
function led.setAll(r, g, b) end


---State module.
---@class statelib
state = {}

---
---@return string
---@nodiscard
function state.activeName() end

---Returns true if the currently active state is one that shows this script.
---A single script can be shown in multiple states.
---@return boolean
---@nodiscard
function state.activeContainsThisScript() end

---Change the active state to the state with name `stateName`.
---@param stateName string
function state.setActiveByName(stateName) end

---Change the active state to the default one.
function state.setDefaultActive() end


---Time module.
---@class timelib
time = {}

---Returns the number of hnsecs since midnight, January 1st, 1 A.D. UTC.
---@return number
---@nodiscard
function time.stdTimeHnsecs() end

---Returns the number of seconds since midnight, January 1st, 1970 UTC.
---@return number
---@nodiscard
function time.unixTimeSeconds() end

---Suspends execution for `msecs` milliseconds.
---@param msecs number
function time.sleepMsecs(msecs) end

---Suspends execution until `frames` number of frames have been rendered.
---`waitFrames(0)` just returns. `waitFrames(1)` waits until the next render...
---@param frames number
function time.waitFrames(frames) end


---Mailbox module.
---@class mailbox
mailbox = {}

---Returns and deletes any message in the mailbox for topic `topic`.
---Returns an empty string if no message was available.
---@param topic string
---@return string
---@nodiscard
function mailbox.consume(topic) end
