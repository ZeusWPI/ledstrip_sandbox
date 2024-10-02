module main;
// dfmt off

import config : Config, ConfigSegment;
import data_dir : DataDir;
import ledstrip;
import ledstrip.led_assignments : LedAssignments, Segment;
import script.bf.bf_script : BfScript;
import script.lua.lua_script : LuaScript;
import script.script : Script;
import webserver.webserver : Webserver;

import core.time : Duration, seconds;

import std.algorithm : each, endsWith;
import std.exception : enforce;
import std.format : f = format;

import bindbc.rpi_ws281x.rpi_ws281x : WS2811_TARGET_FREQ, WS2812_STRIP;

import vibe.core.core : runEventLoop, Task;
import vibe.core.log;

@safe:

// TODO: store filename in script
// TODO: editor

enum uint ct_targetFreq = WS2811_TARGET_FREQ;
enum uint ct_ledStripType = WS2812_STRIP;

int main()
{
    setLogLevel(LogLevel.diagnostic);

    Config config = DataDir.loadConfig;

    Duration frameTime = 1.seconds / config.fps;

    LedAssignments ledAssignments = new LedAssignments(config.ledCount);

    Ledstrip ledstrip;
    version (LedstripWs2811)
    {
        ledstrip = new LedstripWs2811(
            ledAssignments, frameTime,
            ct_targetFreq, config.dmaNumber, config.gpioPin, ct_ledStripType,
        );
    }
    else
    {
        ledstrip = new LedstripVirtual(
            ledAssignments, frameTime,
        );
    }
    scope (exit) (() @trusted => destroy(ledstrip))();
    ledstrip.startRenderLoop;

    Script[] scripts;
    Task[] scriptTasks;
    foreach (string state, ConfigSegment[] segments; config.states)
        foreach (ConfigSegment segment; segments)
        {
            string scriptString = DataDir.loadScript(segment.scriptFileName);
            enforce(Segment(segment.begin, segment.end).isValid(config.ledCount, /*ignoreSlice:*/ true));
            Script script;
            if (segment.scriptFileName.endsWith(".bf"))
                script = new BfScript(scriptString, segment.end - segment.begin);
            else if (segment.scriptFileName.endsWith(".lua"))
                script = new LuaScript(scriptString, segment.end - segment.begin);
            else
                throw new Exception(f!`Unknown script type for filename "%s"`(segment.scriptFileName));
            scripts ~= script;
            ledAssignments.assign(state, segment.begin, segment.end, script.leds);
        }

    scripts.each!(s => scriptTasks ~= s.start);
    scope (exit) scriptTasks.each!(t => t.interrupt);

    Webserver webserver = new Webserver(config.httpBindAddresses, config.httpPort);
    webserver.start;

    return runEventLoop;
}