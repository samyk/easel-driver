# easel-driver
**UNOFFICIAL** Easel driver for Linux (and Mac/Windows) + ability to run Easel from a remote computer (providing remote access to CNC mill)

# Description
I use this to run my CNC mill connected to a Raspberry Pi, and then access it remotely from a non-Linux machine across the network. This is convenient if you don't want to have your CNC mill connected directly to your computer via USB or if you want to run your mill on Linux and still use Inventables' Easel.

The following commands will get the Easel driver running on Linux (tested on Raspberry Pi 3). Additionally, I've added port forwarding instructions if you wish to have your local computer port forward to your Easel machine (Easel's web interface will connect to the port forwarding mechanism on your computer which will forward to the computer your mill is actually connected to).

# Commands
```sh
# Create temp dir to work in
EASELRAND=`date +%N`
mkdir easel-driver-$EASELRAND
cd easel-driver-$EASELRAND

# Install wget to grab official Easel Driver
sudo apt-get install -y wget

# Download official Easel Driver 0.3.6 for Mac (which we'll extract necessary components from)
wget -O - http://easel.inventables.com/downloads | perl -ne 'print $1 if /href="([^"]+EaselDriver-0.3.6.pkg[^"]*)/' | xargs wget -O EaselDriver-0.3.6.pkg

# Install p7zip to unpack xar archive
sudo apt-get install -y p7zip-full

# Unpack Easel Driver
7z x EaselDriver-0.3.6.pkg

# Unpack the primary Easel files
cd IrisLib-0.3.6.pkg
zcat Payload | cpio -idv

# Grab the necessary files
cp -r lib iris.js package.json ssl arduino-flash-tools/tools_darwin/avrdude/etc/avrdude.conf ../
cd ..

# Install nodejs v6 repo in apt
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

# Install nodejs v6
sudo apt-get install -y nodejs

# Install avrdude for firmware upgrades
sudo apt-get install -y avrdude

# Install the necessary node modules
npm install

# Install screen to run in background
sudo apt-get install -y screen

# Profit
screen -dm node iris.js
```

Easel is now running on ports 1338 (WebSocket) and 1438 (TLS WebSocket).

# Remote Port Forwarding
If you want to run your CNC on a separate computer than the one you run Easel from, you can port forward from the machine you want to run Easel from. On my Mac, to port forward, I run:

```sh
# Port forward local 1338 to remote host raspberrypi.local:1338
sudo ncat --sh-exec "ncat raspberrypi.local 1338" -l 1338 --keep-open

# I don't think this next forwarder is necessary (yet) as it's for TLS WebSockets
sudo ncat --sh-exec "ncat raspberrypi.local 1438" -l 1438 --keep-open
```

# Todo
The firmware upgrade won't work because `lib/firmware_uploader.js` has a `PLATFORMS` variable that only defines Darwin and Windows_NT. You should be able to add the following code after `var PLATFORMS = {` to make it work, though I have not tested this.

```javascript
  'Linux': {
    root: '/usr/bin/avrdude',
    executable: '/usr/bin/avrdude',
    config: 'etc/avrdude.conf'
  },
```
