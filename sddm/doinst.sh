config() {
  NEW="$1"
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  # If there's no config file by that name, mv it over:
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "$(cat $OLD | md5sum)" = "$(cat $NEW | md5sum)" ]; then
    # toss the redundant copy
    rm $NEW
  fi
  # Otherwise, we leave the .new copy for the admin to consider...
}

# Create the daemon account and homedirectory otherwise SDDM won't start:
sddmuid=64
sddmgid=64
sddmhome=/var/lib/sddm

if ! chroot . getent group sddm > /dev/null; then
  chroot . groupadd -g $sddmgid sddm
  res=$?
  if [ $res -ne 0 ]; then
cat <<EOT
A group with GID $sddmgid already exists!
You'll have add a 'sddm' group manually.  Run this command (as root):
  groupadd -g GID sddm
and select a free value for GID that is below 500 (check /etc/group)"
Then, run an "upgradepkg --reinstall" of this sddm-qt5 package so that it can run the rest of the install script.
EOT
  fi
fi
if ! chroot . getent passwd sddm > /dev/null; then
  chroot . useradd -c "SDDM Daemon Owner" -d $sddmhome -u $sddmuid \
    -g sddm -s /bin/false sddm
  res=$?
  if [ $res -ne 0 ]; then
    cat <<EOT
Could not create 'sddm' user account.
Does an account with UID $sddmuid already exist?
You'll have add a 'sddm' user manually.  Run these commands (as root):
  useradd -c "SDDM Daemon Owner" -d $sddmhome -u UID -g sddm -s /bin/false sddm
  passwd -l sddm
and select a free value for UID that is below 500 (check /etc/passwd)
Then, run an "upgradepkg --reinstall" of this sddm-qt5 package so that it can run the rest of the install script.
EOT
  fi
fi

# Without a homedirectory, sddm will not start:
chroot . mkdir -p $sddmhome
chroot . chown -R ${sddmuid}:${sddmgid} $sddmhome 1>/dev/null

# Execute this regardless of the pre-existence of the sddm account:
chroot . usermod -d $sddmhome sddm 1>/dev/null
chroot . passwd -l sddm 1>/dev/null
chroot . gpasswd -a sddm video 1>/dev/null

# Generate a new configuration file if it does not exist:
chroot . sddm --example-config > etc/sddm.conf.new

if ! grep -q "Current=breeze" etc/sddm.conf.new ; then
  # Set the KDE5 theme 'breeze' as default, integrates better with Plasma 5:
  sed -i -e "/\[Theme\]/,/^\[/s/^Current.*/Current=breeze/" etc/sddm.conf.new
fi

if ! grep -q "MinimumVT=7" etc/sddm.conf.new ; then
  # SDDM follows the systemd convention of starting the first graphical session
  # on tty1.  We prefer the old convention where tty1 through tty6
  # are reserved for text consoles:
  cat <<EOT >> etc/sddm.conf.new

[XDisplay]
MinimumVT=7
EOT
fi

# Move over the new confguration file if needed:
if [ -f etc/sddm.conf.new ]; then
  config etc/sddm.conf.new
fi
# And our defaults file:
config etc/default/sddm.new
