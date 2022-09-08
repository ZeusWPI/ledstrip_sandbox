# ledstrip_sandbox: a multi-program programmable LED strip

To see what this does and how it works, see [this blog post](https://zeus.ugent.be/blog/21-22/ledstrip_sandbox/).

Get started:

```
# Fetch/update submodules:
git submodule update --init --recursive

# To set up a build in directory `build`:
cmake -B build
# To build in directory `build`:
cmake --build build
```

There are two possible 'backends': a `ws2811` backend (that uses the ledstrip hardware)
and a `virtual` backend (that prints what leds would have been set). They can be
configured in the `config.json` file. The virtual backend can be used in development
when not working on the real hardware.

Note that the scripts in the `saved/` directory are loaded at startup.