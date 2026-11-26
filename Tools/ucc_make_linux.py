import subprocess, sys, os
os.chdir('/home/claude/utgame/System64')
try: os.remove('../System/UTMillenium.u')
except FileNotFoundError: pass
p = subprocess.Popen(['./ucc-bin-amd64','make','INI=/home/claude/utgame/System64/UnrealTournament.ini','USERINI=/home/claude/utgame/System64/User.ini'],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=0)
buf = b''
out = []
while True:
    c = p.stdout.read(1)
    if not c: break
    buf += c
    if buf.endswith(b'([Y]es/[N]o): '):
        line = buf.decode('latin-1').splitlines()[-1]
        ans = b'n\n' if ('instead' in line or 'superfield' in line) else b'y\n'
        out.append('[PROMPT] ' + line[-160:] + ' -> ' + ans.decode().strip())
        p.stdin.write(ans); p.stdin.flush()
        buf = b''
    elif c == b'\n':
        out.append(buf.decode('latin-1').rstrip()); buf = b''
p.wait()
skip = ('Analyzing','Parsing','Compiling','---','WARNING: Using','WARNING: using','===','ucc.exe','Copyright 1999','Importing Defaults')
for l in out:
    if l and not l.startswith(skip): print(l)
print("EXIT", p.returncode)
import shutil
src='/root/.utpg/System/UTMillenium.u'
if os.path.exists(src):
    shutil.copy(src, '/home/claude/utgame/System/UTMillenium.u'); os.remove(src)
    shutil.copy('/home/claude/ut-millenium/UTMillenium/UTMillenium.int', '/home/claude/utgame/System/UTMillenium.int')
    print("copied")
