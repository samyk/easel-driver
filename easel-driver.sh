#!/bin/sh -x

# Move previous out of way if exists
if [ -e 'easel-driver' ]; then mv easel-driver easel-driver.bak.`date +%s`; fi &&

# Create dir to work in
mkdir -p easel-driver &&
cd easel-driver &&

# Download latest Easel Driver for Mac (which we'll extract necessary components from)
curl -L https://easel.inventables.com/downloads | perl -ne 'print $1 if /href="([^"]+EaselDriver\S+\.pkg[^"]*)/' | xargs curl -o EaselDriver.pkg &&

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

# Modify the serial port code to support CH340-based serial devices
perl -pi -e 'if (/callback\(ports\)/) { print << "EOF"
        ports.forEach(function(part, i) {
          if (this[i].manufacturer === "1a86")
            this[i].manufacturer = "FTDI";
          if (this[i].vendorId === "1a86")
            this[i].vendorId = "0403";
        }, ports);
EOF
}' lib/serial_port_controller.js &&

# Install nodejs using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash - &&

export NVM_DIR="$HOME/.nvm" &&
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && # This loads nvm bash_completion
. ~/.bashrc &&

# Install nodejs lts
nvm install --lts &&
nvm use 'lts/*' && # LTS 10.x

# Install the necessary node modules
npm install &&
echo "\n\n\n" &&

# Allow installing on reboot
while true; do
  echo "Almost done! Do you want Easel driver to run on startup (will install to crontab) [yn]: "
  # It's important to use `read` like this so that we can be piped into `| sh`
  read yn <&1
  case $yn in
    [Yy]* ) ((crontab -l 2>>/dev/null | egrep -v '^@reboot.*easel node iris\.js') | echo "@reboot source ~/.bashrc ; cd ~/easel-driver && /usr/bin/screen -L -dmS easel node iris.js") | crontab ; echo '\nAdded to crontab (`crontab -l` to view)'; break;;
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
