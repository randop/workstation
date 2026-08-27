#!/usr/bin/env fish

cgjoin

if not test -d /sys/fs/cgroup/user/randolph/lxc
    echo $fish_pid > /sys/fs/cgroup/user/randolph/cgroup.procs
    sleep 1
    mkdir -pv /sys/fs/cgroup/user/randolph/lxc
    sleep 1
end

echo $fish_pid > /sys/fs/cgroup/user/randolph/lxc/cgroup.procs
