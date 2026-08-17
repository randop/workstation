savedcmd_r8127.mod := printf '%s\n'   r8127_n.o rtl_eeprom.o rtltool.o r8127_fiber.o | awk '!x[$$0]++ { print("./"$$0) }' > r8127.mod
