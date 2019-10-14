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

# Download latest Easel Driver for Mac (which we'll extract necessary components from)
wget -O - http://easel.inventables.com/downloads | perl -ne 'print $1 if /href="([^"]+EaselDriver\S+\.pkg[^"]*)/' | xargs wget -O EaselDriver.pkg &&

# Install p7zip to unpack xar archive
sudo apt-get install -y p7zip-full &&

# Unpack Easel Driver
7z x EaselDriver.pkg &&

# Unpack the primary Easel files
cd IrisLib*.pkg &&
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

# Install nodejs using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash - &&

source ~/.bashrc &&

# Install nodejs lts
nvm install --lts

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
If you want to run your CNC on a separate computer than the one you run Easel from, you can port forward from the machine you want to run Easel from. Easel uses ports 1338 for websocket and 1438 for TLS websockets, however the interface doesn't seem to use 1438 just yet.

**macOS/Linux**
```sh
# Port forward local 1338 to remote host raspberrypi.local:1338
sudo ncat --sh-exec "ncat raspberrypi.local 1338" -l 1338 --keep-open
```

**Windows**
```sh
# you may need to change "raspberrypi.local" to the IP address of the machine running easel-driver
netsh interface portproxy add v4tov4 listenport=1338 listenaddress=0.0.0.0 connectport=1338 connectaddress=raspberrypi.local
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

# Auto enumeration of the right COM/USB Port 
The easel auto enumeration of the right com/usb Port doesn't work on linux, don't know why. You can simply add your Port under lib/serial_port_controller.js. To find YOUR Port inspect the /dev folder on your system for new devices/files after plugging in your arduino. 

Before: 

    currentComName = comName;
    var thisPort = new SerialPort(comName, {
      baudrate: config.baud,
      parser: SerialPort.parsers.readline(config.separator),
      errorCallback: function(err){
        logger.log("ERROR: " + err, Debugger.logger.RED);
        return;
      }
    });


After: 

    currentComName = comName;
    var thisPort = new SerialPort('/dev/ttyUSB0', {          <<<<<<<------ Adjust here!
      baudrate: config.baud,
      parser: SerialPort.parsers.readline(config.separator),
      errorCallback: function(err){
        logger.log("ERROR: " + err, Debugger.logger.RED);
        return;
      }
    });
