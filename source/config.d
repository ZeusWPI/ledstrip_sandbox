module config;

import vibe.data.json : deserializeJson, serializeToPrettyJson;

@safe:

struct Config
{
    string[] httpBindAddresses = ["0.0.0.0"];
    ushort httpPort = 80;

    uint ledCount = 690;
    uint fps = 15;
    int dmaNumber = 10;
    int gpioPin = 18;
    ConfigScript[string] scripts;
    ConfigState[string] states;

    static
    typeof(this) fromJsonString(string s)
        => s.deserializeJson!(typeof(this));

    string toJsonString()
        => this.serializeToPrettyJson;
}

struct ConfigScript
{
    string fileName;
    uint ledCount;
    bool autoStart;
}

struct ConfigState
{
    ConfigSegment[] segments;
}

struct ConfigSegment
{
    uint begin, end;
    string scriptName;
}
