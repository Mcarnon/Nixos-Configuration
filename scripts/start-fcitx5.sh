#!/bin/sh
# Wrapper script to start fcitx5 reliably on session startup.
# Starts systemd --user if not already running, then launches fcitx5.

# Ensure systemd --user is running
if ! pgrep -x "systemd" > /dev/null 2>&1; then
    systemd --user &
    sleep 2
fi

# Start fcitx5 and keep it running
exec fcitx5
