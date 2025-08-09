# Building

## Additional libraries required

The following libraries are required to be installed.

```
| Library Name | Arch/MXE Package | Ubuntu Packages        |
|--------------|------------------|------------------------|
| SLIRP        | libslirp         | libslirp-dev           |
|              |                  | libslirp0              |
| Boost        | boost            | libboost-all-dev       |
| SDL2         | sdl2             | libsdl2-dev            |
|              |                  | libsdl2-2.0-0          |
| SDL2_image   | sdl2_image       | libsdl2-image-dev      |
|              |                  | libsdl2-image-2.0-0    |
| ZLIB         | zlib             |                        |
```

For Ubuntu users, you can install all required packages with:
```bash
sudo apt update && sudo apt install libslirp-dev libslirp0 libboost-all-dev libsdl2-dev libsdl2-2.0-0 libsdl2-image-dev libsdl2-image-2.0-0
```

## building for linux

```bash
git submodule update --init --recursive
# c = clean, b = build. use -h for help
./build.sh -cb
```

## cross compiling to windows

```bash
git submodule update --init --recursive
# c = clean, b = build. use -h for help
./build.sh -cbw
```

You can then run the binary under WINE with:

```bash
env -i DISPLAY=:0 XDG_SESSION_TYPE=x11 wine ./build/sa2.exe
```
The XDG env var is needed if you have wayland on your machine, the SDL2 library works for x11 under WINE.
