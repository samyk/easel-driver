# easel-driver
**UNOFFICIAL** [Easel](https://www.inventables.com/technologies/easel) driver for Linux (and Mac/Windows) + ability to run Easel from a remote computer (providing remote access to CNC mill).

Can be used with X-Carve, Carvey, and other GRBL-based controllers (though it might void your [warranty](http://carvey-instructions.inventables.com/warranty/CarveyLimitedWarranty11.18.16.pdf))

# Description
I use this to run my CNC mill connected to a Raspberry Pi, and then access it remotely from a non-Linux machine across the network. This is convenient if you don't want to have your CNC mill connected directly to your computer via USB or if you want to run your mill on Linux and still use Inventables' [Easel](https://www.inventables.com/technologies/easel).

The following commands will get the Easel driver running on Linux (tested on Raspberry Pi 3). Additionally, I've added port forwarding instructions if you wish to have your local computer port forward to your Easel machine (Easel's web interface will connect to the port forwarding mechanism on your computer which will forward to the computer your mill is actually connected to).

# Commands
```sh
# Move previous out of way if exists
if [ -e 'easel-driver' ]; then mv easel-driver easel-driver.bak.`date +%s`; fi &&

# Create dir to work in
mkdir -p easel-driver &&
cd easel-driver &&

# Install wget to grab official Easel Driver
sudo apt-get install -y wget &&

# Download official Easel Driver 0.3.7 for Mac (which we'll extract necessary components from)
wget -O - http://easel.inventables.com/downloads | perl -ne 'print $1 if /href="([^"]+EaselDriver-0.3.7.pkg[^"]*)/' | xargs wget -O EaselDriver-0.3.7.pkg &&

# Install p7zip to unpack xar archive
sudo apt-get install -y p7zip-full &&

# Unpack Easel Driver
7z x EaselDriver-0.3.7.pkg &&

# Unpack the primary Easel files
cd IrisLib-0.3.7.pkg &&
zcat Payload | cpio -idv &&

# Grab the necessary files
cp -r lib iris.js package.json ssl arduino-flash-tools/tools_darwin/avrdude/etc/avrdude.conf ../ &&
cd .. &&

# Move avrdude.conf into lib/etc as that's where the easel driver will look
mkdir lib/etc &&
mv avrdude.conf lib/etc &&
ln -s lib/etc etc &&

# Modify the firmware uploader to support Linux
perl -pi -e 'if (/var PLATFORMS/) { $x = chr(39); print; $_ = "\t${x}Linux${x}: {\n\t\troot: ${x}/usr/bin/avrdude${x},\n\t\texecutable: ${x}/usr/bin/avrdude${x},\n\t\tconfig: path.join(__dirname, ${x}etc/avrdude.conf${x})\n\t},\n"; }' lib/firmware_uploader.js &&

# Install nodejs v6 repo in apt
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - &&

# Install nodejs v6
sudo apt-get install -y nodejs &&

# Install avrdude for firmware upgrades
sudo apt-get install -y avrdude &&

# Install screen to run in background
sudo apt-get install -y screen &&

# Install the necessary node modules
npm install &&

# Profit (run driver in the background)
screen -dmS easel node iris.js

# Run `screen -r easel` to access the driver, and Ctrl+A (Cmd+A on macOS) followed by 'd' to detach)
```

Easel is now running on ports 1338 (WebSocket) and 1438 (TLS WebSocket).

You can see the console output by running `screen -r easel` and detach from the screen process by hitting `Ctrl+A` followed by `d`.

# Start on boot
To start the driver on bootup, run:

```sh
(crontab -l ; echo "@reboot cd ~/easel-driver && /usr/bin/screen -dmS easel node iris.js") | crontab
```

Ensure that iris.js is actually in ~/easel-driver, and if not, make sure to change the `cd` directory. You must cd into the directory and not just run iris.js from the directory as iris.js uses relative paths.

# Remote Port Forwarding
If you want to run your CNC on a separate computer than the one you run Easel from, you can port forward from the machine you want to run Easel from. On my Mac, to port forward, I run:

```sh
# Port forward local 1338 to remote host raspberrypi.local:1338
sudo ncat --sh-exec "ncat raspberrypi.local 1338" -l 1338 --keep-open

# I don't think this next forwarder is necessary (yet) as it's for TLS WebSockets
sudo ncat --sh-exec "ncat raspberrypi.local 1438" -l 1438 --keep-open
```

# Firmware Upgrade Support

I've added and tested firmware upgrade support for Linux, so firmware upgrades to your mill will work through Easel, even remotely over your network or Internet. The commands above do this automatically by adding the following code to `lib/firmware_uploader.js` directly after the `var PLATFORMS = {` line:

```javascript
  'Linux': {
    root: '/usr/bin/avrdude',
    executable: '/usr/bin/avrdude',
    config: path.join(__dirname, 'etc/avrdude.conf')
  },
```