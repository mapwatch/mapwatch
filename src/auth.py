#!/usr/bin/env python
# Setup authentication for steamctl without user interaction. After running
# this, steamctl will remember the last user + password and other scripts can
# use it without authentication.
#
# Requires some environment variables: STEAMCTL_USER, STEAMCTL_PASSWD,
# STEAMCTL_SECRET, and optionally STEAMCTL_PATH.
#
# STEAMCTL_SECRET is obtained by setting up a steamctl authenticator manually,
# and viewing the authenticator file at $USER_DATA_DIR/authenticator/$USER.json
#
# Warning: do not use on shared machines, as STEAMCTL_SECRET is exposed to `ps`.
#
# Works on windows if wexpect is installed.

# https://wexpect.readthedocs.io/en/latest/api/index.html
# https://pexpect.readthedocs.io/en/stable/examples.html
try:
    import wexpect as xexpect
except:
    import pexpect as xexpect
import sys
import os
import time

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

def printcmd(str, secrets=[]):
    log = str
    for secret in secrets:
        log = log.replace(secret, "***")
    print("\n+", log, flush=True)
    return str

def authenticator_remove(steamctl, user):
    # Remove existing authenticator, if any
    cmd = printcmd(f"{steamctl} authenticator remove --force {user}")
    output, exitstatus = xexpect.run(cmd, withexitstatus=True)
    print(strcast(output))

def authenticator_add(steamctl, user, passwd, secret):
    # I don't like putting the secret in the command line like this - `ps` could see it.
    # But I'm running this on private CI machines, so it *should* be okay, I think.
    # Also, at least the password is still obscured.
    cmd = printcmd(f"{steamctl} authenticator add --from-secret {secret} {user}", secrets=[passwd, secret])
    child = xexpect.spawn(cmd, timeout=5)
    index = logexpect(child, [
        "Enter password for .*:",
        "There is already an authenticator for that account",
    ])
    # print("\n# auth_add expected", index)
    if index == 0:
        child.sendline(passwd)
        logexpect(child, "Authenticator added successfully")
        exitcode = child.wait()
        if (exitcode):
            raise Exception("steamctl exitstatus: "+str(exitcode))
    elif index == 1:
        child.wait()
    else:
        raise Exception("unexpected xexpect.index: "+str(index))

def authenticator_code(steamctl, user):
    cmd = printcmd(f"{steamctl} authenticator code {user}")
    output, exitstatus = xexpect.run(cmd, withexitstatus=True)
    if (exitstatus):
        raise Exception("steamctl exitstatus: "+str(exitstatus))
    return strcast(output).strip()

def login_with_2fa(steamctl, user, passwd):
    cmd = printcmd(f"{steamctl} --user {user} depot info -a 440", secrets=[passwd])
    child = xexpect.spawn(cmd)
    # `depot info` is verbose, and I don't need to see it.
    # instead of logexpect(), expect() with a logprompt() later -
    # if we're not logged in, output the login process; if we *are* logged in, hide output.
    index = child.expect([
        "Password:",
        xexpect.EOF, # already logged in
    ])
    if index == 0:
        logprompt(child)
        child.sendline(passwd)
        tries = 0
        max_tries = 3
        success = False
        while not success and tries < max_tries:
            index = logexpect(child, [
                "Enter 2FA code:" if tries == 0 else "Incorrect code. Enter 2FA code:",
                xexpect.EOF,
            ])

            if index == 0:
                # Input a 2fa code.
                # I don't understand why waitnoecho() is necessary - but without it,
                # 2fa codes that match my phone's are consistently rejected
                if hasattr(child, 'waitnoecho'):
                    child.waitnoecho()
                else:
                    time.sleep(10)

                if tries > 0:
                    time.sleep(5)
                code = authenticator_code(steamctl=steamctl, user=user)
                print(f"authenticator code #{tries+1}:", str(code))
                child.sendline(code)
            else:
                success = True
            tries += 1

        if not success:
            raise RuntimeException(f"too many authenticator failures: {max_tries}")
    elif index == 1:
        print("(already logged in, ignoring output)")
    exitstatus = child.wait()
    if (exitstatus):
        raise Exception("steamctl exitstatus: "+str(exitstatus))

def verify_auth_remembered(steamctl):
    cmd = printcmd(f"{steamctl} depot info -a 238960")
    output, exitstatus = xexpect.run(cmd, withexitstatus=True)
    # print(strcast(output))
    if (exitstatus):
        raise Exception("steamctl exitstatus: "+str(exitstatus))

def main():
    # Steam account login
    user = os.environ['STEAMPULL_USER']
    passwd = os.environ['STEAMPULL_PASSWD']
    # Mobile authenticator secret. We set up this machine as if it were a permanent
    # auntenticator, and generate a code to log in.
    secret = os.environ['STEAMPULL_SECRET']
    # steamctl binary path
    #steamctl = "./.local/bin/steamctl"
    steamctl = os.environ.get('STEAMCTL_PATH', "steamctl")

    authenticator_remove(steamctl=steamctl, user=user)
    authenticator_add(steamctl=steamctl, user=user, passwd=passwd, secret=secret)
    #print(authenticator_code(steamctl=steamctl, user=user))
    login_with_2fa(steamctl=steamctl, user=user, passwd=passwd)
    verify_auth_remembered(steamctl=steamctl)

if __name__=="__main__":
    main()
