module config;

import std.exception : basicExceptionCtors, enforce;

import vibe.data.json;

@safe:

struct Config
{
    string[] httpBindAddresses = ["0.0.0.0"];
    ushort httpPort = 80;

    size_t ledCount = 690;
    uint fps = 15;
    int dmaNumber = 10;
    int gpioPin = 18;
    ConfigSegment[][string] states;

    static
    typeof(this) fromJsonString(string s)
    {
        return s.deserializeJson!(typeof(this));
    }

    string toJsonString()
    {
        Json j = this.serializeToJson;
        return j.toPrettyString;
    }
}

struct ConfigSegment
{
    uint begin, end;
    string scriptFileName;
}

class ConfigException : Exception
{
    mixin basicExceptionCtors;
}
