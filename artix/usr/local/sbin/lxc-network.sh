#!/bin/sh
set -e

MAX_RETRIES=15
DELAY=1

# Create and configure the bridge
ip link add name lxcbr0 type bridge 2>/dev/null || true
ip link set eth0 master lxcbr0
ip link set eth0 up
ip link set lxcbr0 up

# Stop any existing dhcpcd instances
dhcpcd -k 2>/dev/null || true
dhcpcd -k eth0 2>/dev/null || true
killall dhcpcd 2>/dev/null || true

# Wait for IPv4 address on lxcbr0 (retry up to 15 times)
i=1
while [ $i -le $MAX_RETRIES ]; do
    dhcpcd lxcbr0
    sleep 1

    if ip -4 -o addr show dev lxcbr0 2>/dev/null | grep -q 'inet '; then
        echo "lxcbr0 has IPv4 address after $i attempt(s)"
        ip -4 addr show dev lxcbr0
        exit 0
    fi

    echo "Attempt $i/$MAX_RETRIES: no IPv4 address yet on lxcbr0, waiting ${DELAY}s..."
    sleep $DELAY
    i=$((i + 1))
done

echo "ERROR: lxcbr0 did not get an IPv4 address after $MAX_RETRIES attempts" >&2
exit 1
