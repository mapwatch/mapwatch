# https://wexpect.readthedocs.io/en/latest/api/index.html
# https://pexpect.readthedocs.io/en/stable/examples.html
try:
    import wexpect as xexpect
except:
    import pexpect as xexpect
import sys
import os.path

def strcast(bytes_or_str):
    if hasattr(bytes_or_str, "decode"):
        # pexpect: it's bytes, decode to str
        return bytes_or_str.decode("utf-8")
    # wexpect: it's str, fine as-is
    return bytes_or_str

def logprompt(child):
    print(strcast(child.before), end='')
    print(strcast(child.after), end='')

def logexpect(child, *args, **kwargs):
    ret = child.expect(*args, **kwargs)
    logprompt(child)
    return ret

cwd=os.path.dirname(os.path.abspath(__file__))
child = xexpect.spawn("python input-getpass-cli.py", cwd=cwd)
logexpect(child, "Here is an input")
child.sendline("input abc123")
logexpect(child, "Your input: input abc123")

logexpect(child, "Here is a getpass")
logexpect(child, "Password:")
child.sendline("password xyz098")
logexpect(child, "Goodbye")
exitcode = child.wait()
print()
print()
print('exit:', exitcode)

output2, exitcode2 = xexpect.run("python --version", cwd=cwd, withexitstatus=True)
print()
print(strcast(output2))
print('exit2:', exitcode2)
