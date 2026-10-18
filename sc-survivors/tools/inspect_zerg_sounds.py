import os

SRC = r"C:\Users\toffe\Desktop\SCsurvivors\sound\zerg"
subdirs = ["guardian", "devourer", "queen", "avenger", "defiler"]

for s in subdirs:
    p = os.path.join(SRC, s)
    if os.path.exists(p):
        files = os.listdir(p)
        print(f"[{s}] -> {files}")
    else:
        print(f"[{s}] NOT FOUND")
