import getpass

print("Try to automate this cli! piping to stdin won't work, sadly.", flush=True)

print("Here is an input():", flush=True)
a = input()
print("Your input: "+a, flush=True)

print("Here is a getpass(): (beware, I will print your input!)", flush=True)
b = getpass.getpass()
print("Your password: "+b, flush=True)

print("Goodbye", flush=True)
# raise Exception("oops")
