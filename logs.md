# Logs

### View nginx logs
```sh
journalctl -u nginx.service -e
```

#### Nginx logs indicating out-of-memory failure and recovery
```
Dec 22 10:41:29 johnpaul-server systemd[1]: nginx.service: Killing process 2047135 (nginx) with signal SIGKILL.
Dec 22 10:41:29 johnpaul-server systemd[1]: nginx.service: Main process exited, code=killed, status=9/KILL
Dec 22 10:41:29 johnpaul-server systemd[1]: nginx.service: Failed with result 'oom-kill'.
Dec 22 10:41:29 johnpaul-server systemd[1]: Stopped A high performance web server and a reverse proxy server.
Dec 22 10:41:29 johnpaul-server systemd[1]: nginx.service: Consumed 6.913s CPU time.
Dec 22 10:41:29 johnpaul-server systemd[1]: Starting A high performance web server and a reverse proxy server...
Dec 22 10:41:35 johnpaul-server systemd[1]: Started A high performance web server and a reverse proxy server.
-- Boot d0bcfbbb7a42453ba0c16dddfcd8857c --
Dec 25 12:34:42 johnpaul-server systemd[1]: Starting A high performance web server and a reverse proxy server...
Dec 25 12:35:09 johnpaul-server systemd[1]: Started A high performance web server and a reverse proxy server.
Feb 13 06:24:47 johnpaul-server systemd[1]: Stopping A high performance web server and a reverse proxy server...
Feb 13 06:24:47 johnpaul-server systemd[1]: nginx.service: A process of this unit has been killed by the OOM killer.
Feb 13 06:24:49 johnpaul-server systemd[1]: nginx.service: A process of this unit has been killed by the OOM killer.
Feb 13 06:24:49 johnpaul-server systemd[1]: nginx.service: Killing process 884 (nginx) with signal SIGKILL.
Feb 13 06:24:49 johnpaul-server systemd[1]: nginx.service: Killing process 889 (nginx) with signal SIGKILL.
Feb 13 06:24:50 johnpaul-server systemd[1]: nginx.service: Main process exited, code=killed, status=9/KILL
Feb 13 06:24:50 johnpaul-server systemd[1]: nginx.service: Failed with result 'oom-kill'.
Feb 13 06:24:50 johnpaul-server systemd[1]: Stopped A high performance web server and a reverse proxy server.
Feb 13 06:24:50 johnpaul-server systemd[1]: nginx.service: Consumed 10min 9.891s CPU time.
Feb 13 06:24:50 johnpaul-server systemd[1]: Starting A high performance web server and a reverse proxy server...
Feb 13 06:24:56 johnpaul-server systemd[1]: Started A high performance web server and a reverse proxy server.
Feb 13 06:25:00 johnpaul-server systemd[1]: nginx.service: A process of this unit has been killed by the OOM killer.
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: State 'stop-sigterm' timed out. Killing.
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: Killing process 1103462 (nginx) with signal SIGKILL.
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: Killing process 1103464 (nginx) with signal SIGKILL.
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: Killing process 1103539 (nginx) with signal SIGKILL.
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: Main process exited, code=killed, status=9/KILL
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: Killing process 1103464 (nginx) with signal SIGKILL.
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: Failed with result 'oom-kill'.
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: Unit process 1103464 (nginx) remains running after unit stopped.
Feb 13 06:25:05 johnpaul-server systemd[1]: nginx.service: Consumed 17.084s CPU time.
Feb 13 06:25:07 johnpaul-server systemd[1]: Stopped A high performance web server and a reverse proxy server.
Feb 13 06:25:07 johnpaul-server systemd[1]: nginx.service: Consumed 17.185s CPU time.
Feb 13 06:25:07 johnpaul-server systemd[1]: Starting A high performance web server and a reverse proxy server...
Feb 13 06:25:13 johnpaul-server systemd[1]: Started A high performance web server and a reverse proxy server.
Mar 23 12:06:25 johnpaul-server systemd[1]: Stopping A high performance web server and a reverse proxy server...
Mar 23 12:06:30 johnpaul-server systemd[1]: nginx.service: Stopping timed out. Terminating.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: State 'stop-sigterm' timed out. Killing.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Killing process 1103570 (nginx) with signal SIGKILL.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Killing process 1103571 (nginx) with signal SIGKILL.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Killing process 1103572 (nginx) with signal SIGKILL.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Main process exited, code=killed, status=9/KILL
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Killing process 1103572 (nginx) with signal SIGKILL.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Failed with result 'timeout'.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Unit process 1103572 (nginx) remains running after unit stopped.
Mar 23 12:06:35 johnpaul-server systemd[1]: Stopped A high performance web server and a reverse proxy server.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Consumed 8min 49.586s CPU time.
Mar 23 12:06:35 johnpaul-server systemd[1]: nginx.service: Found left-over process 1103572 (nginx) in control group while starting unit. Ignoring.
Mar 23 12:06:35 johnpaul-server systemd[1]: This usually indicates unclean termination of a previous run, or service implementation deficiencies.
Mar 23 12:06:35 johnpaul-server systemd[1]: Starting A high performance web server and a reverse proxy server...
Mar 23 12:06:42 johnpaul-server systemd[1]: Started A high performance web server and a reverse proxy server.
```
