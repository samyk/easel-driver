#!/bin/sh -x

# Move previous out of way if exists
if [ -e 'easel-driver' ]; then mv easel-driver easel-driver.bak.`date +%s`; fi &&

# Create dir to work in
mkdir -p easel-driver &&
cd easel-driver &&

# Download latest Easel Driver for Mac (which we'll extract necessary components from)
curl -L https://easel.inventables.com/downloads | perl -ne 'print $1 if /href="([^"]+EaselDriver\S*\.pkg[^"]*)/' | xargs curl -o EaselDriver.pkg &&

# Install p7zip to unpack xar archive, avrdude for firmware upgrades, screen to run in background
sudo apt-get install -y p7zip-full avrdude screen &&

# Unpack Easel Driver
7z x EaselDriver.pkg &&

# Unpack the primary Easel files
cd IrisLib*.pkg &&
zcat Payload | cpio -idv &&

# Grab the necessary files
cp -r lib iris.js package.json ssl avrdude/etc/avrdude.conf ../ &&
cd .. &&

# Move avrdude.conf into lib/etc as that's where the easel driver will look
mkdir lib/etc &&
mv avrdude.conf lib/etc &&
ln -s lib/etc etc &&

# Modify the firmware uploader to support Linux
perl -pi -e 'if (/var PLATFORMS/) { $x = chr(39); print; $_ = "\t${x}Linux${x}: {\n\t\troot: ${x}/usr/bin/avrdude${x},\n\t\texecutable: ${x}/usr/bin/avrdude${x},\n\t\tconfig: path.join(__dirname, ${x}etc/avrdude.conf${x})\n\t},\n"; }' lib/firmware_uploader.js &&

# Modify the serial port code to support CP210x/CH340/CH341-based serial devices by spoofing an FTDI chip
perl -pi -e 'if (/callback\(ports\)/) { print << "EOF"
        ports.forEach(function(part, i) {
          if (this[i].manufacturer === "1a86")
            this[i].manufacturer = "FTDI";
          if (this[i].manufacturer === "Silicon Labs")
            this[i].manufacturer = "FTDI";
          if (this[i].vendorId === "1a86")
            this[i].vendorId = "0403";
           if (this[i].vendorId === "10c4")
            this[i].vendorId = "0403";           
        }, ports);
EOF
}' lib/serial_port_controller.js &&

# Modify the machine.js to watch for an unknown message received, then trigger a FluidNC connection
# perl search string is temp

perl -pi -e 'if (/that\.dispatchEvent\(.unknown.\, message/) { print << "EOF"
        if (message.includes(\x{027}FluidNC\x{027}) && !isMachineConnected){
           onMachineConnected(\x{027}$Grbl 1.1 [\x{027}\$\x{027}$ for help]\x{027});
        }
EOF
}' lib/machine.js &&


# Install nodejs using nvm
# The installation script will clone the nvm repository from Github to the ~/.nvm directory 
# and add the nvm path to your Bash profile.
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash - &&

# Rerun Profile script to start NVM
if [ ! -e "$NVM_DIR" ]; then
        if [ -e "$HOME/.nvm" ]; then
                export NVM_DIR="$HOME/.nvm"
        else
                if [ -e "$HOME/.config/nvm" ]; then
                        export NVM_DIR="$HOME/.config/nvm"
                else
                        echo "Can't find NVM directory!"
                fi
        fi
fi &&
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && # This loads nvm bash_completion
. ~/.bashrc &&

# Ensure screen also respects the bashrc
echo 'shell -$SHELL' >> ~/.screenrc &&

# install nodejs v18
nvm install v18.4.0 &&
nvm use v18.4.0 &&

# Install the necessary node modules
npm install &&
echo "\n\n\n" &&

# Create a startup script
#echo '. ~/.bashrc ; . ~/.nvm/nvm.sh ; nvm use' \'v18.4.0\' '; cd ~/easel-driver ; node iris.js' > run.sh &&
#chmod 755 run.sh &&

# Allow installing on reboot
check_init() { 
        # Per sd_booted(8), the way to check if systemd is running is to check if this directory exists.
        if [ -d /run/systemd/system/ ]; then 
                # set if systemd is in use on this system.
                SYSD=1
        else
                SYSD=0
        fi
}

# Create simple start script and save in easel driver folder
create_start_script() { 
        driverdir=$(pwd)
        touch ${driverdir}/run.sh
        chmod +x ${driverdir}/run.sh
        cat <<EOF > run.sh
#!/bin/bash
. ~/.bashrc
. ~/.nvm/nvm.sh
nvm use 'v18.4.0'
cd ${driverdir}

echo "Starting easel-driver"
node iris.js
EOF
}

# Installs system specific service
install_service() {
        if [ "${SYSD}" = "1" ]; then
        touch ${driverdir}/EaselDriver.service
        cat <<EOF > ${driverdir}/EaselDriver.service
[Unit]
Description=EaselDriver systemd service unit file.

[Service]
User=$(whoami)
# use screen -D to keep 'screen' alive but detached so that systemd sees it is running.
ExecStart=screen -DmS easel /bin/bash ${driverdir}/run.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        sudo mv ${driverdir}/EaselDriver.service /etc/systemd/system/
        sudo systemctl daemon-reload
        sudo systemctl enable EaselDriver.service
        else # if init.d create start/stop script enable with chkconfig
        touch ${driverdir}/EaselDriver
        cat <<EOF > ${driverdir}/EaselDriver
#!/bin/bash
# chkconfig: 2345 20 80
# description: Serv

# Source function library.
. /etc/init.d/functions

start() {
    cd ${driverdir}
    chroot --userspec "$(whoami)": / screen -dmS easel ${driverdir}/run.sh
}

stop() {
    chroot --userspec "$(whoami): / /usr/bin/screen -X -S "easel" quit
}

case "$1" in 
    start)
       start
       ;;
    stop)
       stop
       ;;
    *)
       echo "Usage: $0 {start|stop}"
esac

exit 0 
EOF
        sudo mv ${driverdir}/EaselDriver /etc/init.d/
        sudo chkconfig --add EaselDriver
        sudo chkconfig --level 2345 EaselDriver on
fi
}

while true; do
  echo "Almost done! Do you want Easel driver to run on startup (will install system service) [yn]: "
  # It's important to use `read` like this so that we can be piped into `| sh`
  read yn <&1
  case $yn in
    [Yy]* ) 
        check_init
        create_start_script
        install_service
        break;;
    [Nn]* ) break;;
    * ) echo "Please answer yes/no";;
  esac
done &&

# Profit (run driver in the background)
screen -L -dmS easel node iris.js &&

# Output the screen log so we can see if it was successful
sleep 3 &&
echo "\n\n\n" &&
tail screenlog.0 &&

# Run `screen -r easel` to access the driver, and Ctrl+A (Cmd+A on macOS) followed by 'd' to detach)
echo '\n\nDone! Easel driver running in background. Run `screen -r` to bring it to foreground.'
