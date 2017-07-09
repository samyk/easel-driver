# Create dir to work in
mkdir easel-driver
cd easel-driver

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

# Move avrdude.conf into lib/etc as that's where Iris will look
mkdir lib/etc
mv avrdude.conf lib/etc
ln -s lib/etc etc

# Install nodejs v6 repo in apt
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

# Install nodejs v6
sudo apt-get install -y nodejs

# Install avrdude for firmware upgrades
sudo apt-get install -y avrdude

# Install screen to run in background
sudo apt-get install -y screen

# Install the necessary node modules
npm install

# Profit (run driver in the background)
screen -dmS easel node iris.js