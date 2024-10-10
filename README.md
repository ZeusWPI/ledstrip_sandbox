# ledstrip_sandbox: a multi-program programmable LED strip

Blogpost for the first version: https://zeus.ugent.be/blog/21-22/ledstrip_sandbox/.

## Run locally (for testing only)

With a D compiler and dub installed, run:

```
dub
```

## Build for the raspberry pi 2

With a recent docker version installed, run:

```
docker build -o . .
```

This will output a `ledstrip` binary and `public` folder, that you can copy over, along with the `data` folder template:

```
rsync -r ledstrip data public root@ledstrip:ledstrip
ssh root@ledstrip systemctl restart ledstrip
```
