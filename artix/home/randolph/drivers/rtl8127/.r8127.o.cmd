savedcmd_r8127.o := ld -m elf_x86_64 -z noexecstack --no-warn-rwx-segments   -r -o r8127.o @r8127.mod  ; /usr/lib/modules/7.1.8-artix1-3/build/tools/objtool/objtool --hacks=jump_label --hacks=noinstr --hacks=skylake --ibt --orc --retpoline --rethunk --sls --static-call --uaccess --prefix=16  --link  --module r8127.o

r8127.o: $(wildcard /usr/lib/modules/7.1.8-artix1-3/build/tools/objtool/objtool)
