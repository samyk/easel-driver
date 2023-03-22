# easel-driver for Linux/macOS/RPi/Windows + GRBL/gCarvin/FluidNC/clones + ARM/x86/more + FTDI/USB/clones

**UNOFFICIAL** [Easel](https://www.inventables.com/technologies/easel) driver for Linux, Mac, Windows, Raspberry Pi (x86/x86-64/ARM) + ability to run Easel from a remote computer (providing remote access to CNC mill).

Can be used with X-Carve, Carvey, and other GRBL/gCarvin/FluidNC-based controllers including Arduino, FTDI, and CP210x/CH34x-based controllers (though it might void your [warranty](http://carvey-instructions.inventables.com/warranty/CarveyLimitedWarranty11.18.16.pdf))

## Quick Start

Easiest way to get everything installed and running is to run the following:

`curl https://raw.githubusercontent.com/samyk/easel-driver/master/easel-driver.sh | sh -x`

Easel is now running on ports 1338 (WebSocket) and 1438 (TLS WebSocket).

You can see the console output by running `screen -r easel` and detach from the screen process by hitting `Ctrl+A` followed by `d`.

## Description

I use this to run my CNC mill connected to a Raspberry Pi, and then access it remotely from a non-Linux machine across the network. This is convenient if you don't want to have your CNC mill connected directly to your computer via USB or if you want to run your mill on Linux and still use Inventables' [Easel](https://www.inventables.com/technologies/easel).

The following commands will get the Easel driver running on Linux (tested on Raspberry Pi 3). Additionally, I've added port forwarding instructions if you wish to have your local computer port forward to your Easel machine (Easel's web interface will connect to the port forwarding mechanism on your computer which will forward to the computer your mill is actually connected to).

Note that while Inventables does now offer a [Linux driver](https://easel.inventables.com/sender_versions/legacy), it's _only_ for X86 processors and not ARM processors, like the Raspberry Pi.


## Remote Port Forwarding

If you want to run your CNC on a separate computer than the one you run Easel from, you can port forward from the machine you want to run Easel from. Easel uses ports 1338 for websocket and 1438 for TLS websockets, however the interface used to use 1338 exclusively but now seems to use 1438 exclusively.

**macOS/Linux**
```sh
# on macOS, you can first install MacPorts from https://guide.macports.org/#installing.macports
# ncat is installed via nmap, I personally installed nmap via MacPorts by running
sudo port install nmap

# Now port forward local 1438 to remote host raspberrypi.local:1438 - may need to adjust raspberrypi.local to your controller's IP/hostname
ncat --sh-exec "ncat raspberrypi.local 1438" -l 1438 --keep-open
```

**Windows**
```sh
# you may need to change "raspberrypi.local" to the IP address of the machine running easel-driver
netsh interface portproxy add v4tov4 listenport=1438 listenaddress=0.0.0.0 connectport=1438 connectaddress=raspberrypi.local
```

## Start on boot

The shell script asks you if you want to run on boot, and if so, it will add it to your crontab. If you didn't add it initially and want to now, you can add it like so:

```sh
(crontab -l ; echo "@reboot cd ~/easel-driver && /usr/bin/screen -dmS easel node iris.js") | crontab
```

Ensure that iris.js is actually in ~/easel-driver, and if not, make sure to change the `cd` directory. You must cd into the directory and not just run iris.js from the directory as iris.js uses relative paths.
