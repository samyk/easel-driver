# easel-driver
**UNOFFICIAL** [Easel](https://www.inventables.com/technologies/easel) driver for Linux (including Raspberry Pi/ARM processors), Mac, Windows + ability to run Easel from a remote computer (providing remote access to CNC mill).

Can be used with X-Carve, Carvey, and other GRBL-based controllers (though it might void your [warranty](http://carvey-instructions.inventables.com/warranty/CarveyLimitedWarranty11.18.16.pdf))

# Quick Start
Easiest way to get everything installed and running is to run the following:
`curl https://raw.githubusercontent.com/samyk/easel-driver/master/easel-driver.sh | sh`

Easel is now running on ports 1338 (WebSocket) and 1438 (TLS WebSocket).

You can see the console output by running `screen -r easel` and detach from the screen process by hitting `Ctrl+A` followed by `d`.

# Description
I use this to run my CNC mill connected to a Raspberry Pi, and then access it remotely from a non-Linux machine across the network. This is convenient if you don't want to have your CNC mill connected directly to your computer via USB or if you want to run your mill on Linux and still use Inventables' [Easel](https://www.inventables.com/technologies/easel).

The following commands will get the Easel driver running on Linux (tested on Raspberry Pi 3). Additionally, I've added port forwarding instructions if you wish to have your local computer port forward to your Easel machine (Easel's web interface will connect to the port forwarding mechanism on your computer which will forward to the computer your mill is actually connected to).

Note that while Inventables does now offer a [Linux driver](https://easel.inventables.com/sender_versions/legacy), it's _only_ for X86 processors and not ARM processors, like the Raspberry Pi.


# Start on boot

The shell script asks you if you want to run on boot, and if so, it will add it to your crontab. If you didn't add it initially and want to now, you can add it like so:

```sh
(crontab -l ; echo "@reboot cd ~/easel-driver && /usr/bin/screen -dmS easel node iris.js") | crontab
```

Ensure that iris.js is actually in ~/easel-driver, and if not, make sure to change the `cd` directory. You must cd into the directory and not just run iris.js from the directory as iris.js uses relative paths.

# Remote Port Forwarding
If you want to run your CNC on a separate computer than the one you run Easel from, you can port forward from the machine you want to run Easel from. Easel uses ports 1338 for websocket and 1438 for TLS websockets, however the interface used to use 1338 exclusively but now seems to use 1438 exclusively.

**macOS/Linux**
```sh
# Port forward local 1438 to remote host raspberrypi.local:1438
sudo ncat --sh-exec "ncat raspberrypi.local 1438" -l 1438 --keep-open &
sudo ncat --sh-exec "ncat raspberrypi.local 1438" -l 1438 --keep-open &
```

**Windows**
```sh
# you may need to change "raspberrypi.local" to the IP address of the machine running easel-driver
netsh interface portproxy add v4tov4 listenport=1438 listenaddress=0.0.0.0 connectport=1438 connectaddress=raspberrypi.local
netsh interface portproxy add v4tov4 listenport=1338 listenaddress=0.0.0.0 connectport=1338 connectaddress=raspberrypi.local
```

# Auto enumeration of the right COM/USB port

Some users have mentioned they had make the change below, while others have not. I have not had to do this on Carvey as of 2020/05/05, but you may need to.

The Easel auto enumeration of the right com/USB port doesn't work for everyone on Linux. You can simply add your Port under ~/easel-driver/lib/serial_port_controller.js. To find YOUR port inspect the /dev folder on your system for new devices/files after plugging in your Arduino/controller, `ls /dev/tty*`

Before:
```
    currentComName = comName;
    var thisPort = new SerialPort(comName, {
      baudrate: config.baud,
      parser: SerialPort.parsers.readline(config.separator),
      errorCallback: function(err){
        logger.log("ERROR: " + err, Debugger.logger.RED);
        return;
      }
    });
```

After:
```
    currentComName = comName;
    var thisPort = new SerialPort('/dev/ttyUSB0', {  //    <<<<<<<------ Adjust here!
      baudrate: config.baud,
      parser: SerialPort.parsers.readline(config.separator),
      errorCallback: function(err){
        logger.log("ERROR: " + err, Debugger.logger.RED);
        return;
      }
    });
```
