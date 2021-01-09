import requests
import json
asd=0
with open("gamedata.csv","r") as fin:
    with open("gamedata2.csv","a") as fout:

        inpl = fin.readlines()
        for line in inpl:
            det=line[:-1].split(',')
            r=requests.get(f'http://data.nba.com/data/v2015/json/mobile_teams/nba/2020/scores/pbp/{det[0]}_full_pbp.json')
            gdat = r.text
            sind=gdat.find(f'"evt":{det[1]}')
            #print(sind)
            destart=0
            for i in range(sind,sind+50):
                if gdat[i:i+6] == '"de":"':
                    destart=i+6
                    break
            deend=gdat[destart:].find('"')
            #print(deend)
            #print(gdat[destart:destart+deend])
            endstr=gdat[destart:destart+deend].replace('\\n','').replace('\\r','')

            if asd<50:
                print(endstr)
            asd+=1

            fout.write(f"{line[:-1]},{endstr}\n")
