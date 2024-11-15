module config;

import core.time : Duration, seconds;

import std.algorithm : each;
import std.conv : to;

@safe pure nothrow @nogc:

struct Config
{
    string[] httpBindAddresses = ["0.0.0.0"];
    ushort httpPort = 80;
    uint ledCount = 690;
    uint fps = 15;
    ubyte maxBrightness = 0x80;
    int dmaNumber = 10;
    int gpioPin = 18;
    ConfigScriptInstance[string] scriptInstances;
    ConfigState[string] states;

    pure nothrow @nogc
    Duration frameTime() const shared
        => 1.seconds / fps;

    pure
    shared(Config) sharedDup() const
    {
        shared(Config) ret;
        // dfmt off
        ret.httpBindAddresses = httpBindAddresses.to!(shared(string)[]);
        ret.httpPort          = httpPort;
        ret.ledCount          = ledCount;
        ret.fps               = fps;
        ret.maxBrightness     = maxBrightness;
        ret.dmaNumber         = dmaNumber;
        ret.gpioPin           = gpioPin;
        foreach (k, v; scriptInstances) ret.scriptInstances[k] = v;
        foreach (k, v; states)  ret.states[k]  = v.sharedDup;
        // dfmt on
        return ret;
    }
}

struct ConfigScriptInstance
{
    string sourceFileName;
    uint ledCount;
    bool autoStart;
}

struct ConfigState
{
    ConfigSegment[] segments;

    pure
    shared(ConfigState) sharedDup() const
    {
        shared ConfigState ret;
        ret.segments = segments.to!(shared(ConfigSegment[]));
        return ret;
    }
}

struct ConfigSegment
{
    uint begin, end;
    string scriptInstanceName;
}
