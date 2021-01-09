
f=open("gamedata.csv","r")
f2=open("gamedata2.csv","a")

for ln in f.readlines():
	if ",," in ln:
		continue
	if "nolink" in ln:
		continue
	if ",-1,0" in ln:
		continue
	f2.write(ln)
	
f.close()
f2.close()