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

# Move over the new policy files:
config etc/polkit-1/rules.d/10-enable-suspend.rules.new
config etc/polkit-1/localauthority/50-local.d/30-org.freedesktop.upower.pkla.new
config  etc/polkit-1/localauthority/50-local.d/40-org.freedesktop.consolekit.system.stop-multiple-users.pkla.new
config etc/polkit-1/localauthority/50-local.d/41-org.freedesktop.consolekit.system.restart-multiple-users.pkla.new

