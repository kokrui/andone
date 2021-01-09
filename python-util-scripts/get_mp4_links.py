from selenium import webdriver
import time
import random
finp = open("2020-21.csv","r")
finp2= open("caa0655lmao.csv","r")
fout = open("2020-21_links2.csv","a+")

options = webdriver.ChromeOptions()
browser = webdriver.Chrome('./chromedriver.exe',options=options)

inp_csv = finp.readlines()
inp2_csv = finp2.readlines()
event_freq = {}

for line in inp2_csv:
    det = line.split(',')
    kstr = f"{det[2]}_{det[3]}_{det[4]}"
    if kstr not in event_freq:
        event_freq[kstr]=0
    event_freq[kstr]+=1

#print(event_freq)

 


for line in inp_csv[4314:]:
    
    det=line.split(',')
    
    sstr = f"{det[2]}_{det[3]}_{det[4]}"

    # "population control" I MESSED UP
    '''
    if int(det[2]) == 1 or det[2] == 2: # 3pt shot population can destroy (2k -> 30), since those are rarely ambiguous
        print(det[2])
        lol = random.randint(event_freq[sstr])
        print(lol)
        if lol<25:
            fout.write(line)
            #print("yeet")
            continue
    if det[2] == 4: # rebounds
        if random.randint(event_freq[sstr])<80:
            fout.write(line)
            #print("yeet")
            continue

    if det[2] == 5 and det[3] == 2: # pickpocket turnover
        if random.randint(event_freq[sstr])<100:
            fout.write(line)
            #print("yeet")
            continue
    '''
    if sstr not in event_freq:
        event_freq[sstr] = 0
        
    if int(det[2]) < 5 or ((int(det[2]) == 5 and int(det[3]) == 2)):
        if event_freq[sstr] > 10:
            continue

    #everything else just get fully, cos rely on whistle!
    try:
        print(det)
        browser.get(f"https://www.nba.com/stats/events/?GameEventID={det[1]}&GameID={det[0]}&Season=2020-21&flag=1")
        time.sleep(2)
        nav = browser.find_element_by_id("stats-videojs-player_html5_api")
        vidlink = nav.get_attribute("src")

        finstr = line[:-1] + "," + vidlink + "\n"
        print("WRITTEN",finstr)
        fout.write(finstr)
        
    except KeyboardInterrupt:
        fout.close()
        break
    except Exception:
        print('oi error for '+line)
        pass

fout.close()
browser.quit()
