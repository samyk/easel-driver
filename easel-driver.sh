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