import scipy.io.wavfile
import scipy.signal
import requests
import subprocess
import math
import os
with open("../nba_get_link/2020-21_links_done_1.csv","r") as inpf:
    with open("2020-21_withlinks.csv","a") as outf:
        inputlmao = inpf.readlines()[:6490]
        inputlmao.reverse()
        try:
            for line in inputlmao:
                det = line.split(',')

                #print(url)
                need_download = int(det[4])
                if need_download == 0:
                    outf.write(line[:-1]+",0,0"+"\n") # whistle time, ambiguity
                    continue
                if len(det[6])<5:
                    outf.write(line[:-1]+",nolink,nolink\n")
                    continue
                # GET VIDEO AND WAV
                url = det[6][:-1]
                if os.path.exists("temp.mp4"):
                    os.remove("temp.mp4")

                video = open("temp.mp4","wb")

                r=requests.get(url)
                for chunk in r.iter_content(chunk_size=255): 
                    if chunk: # filter out keep-alive new chunks
                        video.write(chunk)
                video.close()

                subprocess.run("ffmpeg -i temp.mp4 -ac 1 -f wav temp.wav -y",shell=True) # mp4 -> mono wav
                 

                # DO THE SIGNAL SHIT
                
                fs,wave = scipy.io.wavfile.read('temp.wav')
                f,t,sxx=scipy.signal.spectrogram(wave,fs)

                fmin_ind = 0
                fmax_ind = 0


                #get frequency range indexes
                for i in range(len(f)):
                    if f[i]>3700:
                        fmin_ind = i-1
                        break

                for i in range(fmin_ind,len(f)):
                    if f[i]>4500:
                        fmax_ind = i
                        break

                print('good1')
                candidate_ranges = {}
                for freq in range(fmin_ind,fmax_ind+1):
                    print("THIS FREQ",freq)
                    peak_arr = scipy.signal.find_peaks(sxx[freq],prominence=300,distance=30)[0]
                    for tim in range(300,len(t)):
                        if t[tim]<2.5:
                            continue
                        if sxx[freq][tim] > 300:
                            start_tim_index = tim
                            end_tim_index = tim

                            # get at least .13s
                            for temptim in t[tim+1:]:
                                end_tim_index+=1
                                if temptim - 0.13 > t[start_tim_index]:
                                    break

                            if sum(sxx[freq][start_tim_index:end_tim_index+1])/(end_tim_index-start_tim_index) < 300:
                                continue

                            _3short5me = False
                            for i in range(start_tim_index,end_tim_index+1):
                                if sum(sxx[freq][i:i+5])/5 < 80:
                                    #print(sxx[freq][i:i+5])
                                    #print(sum(sxx[freq][i:i+5])/5)
                                    _3short5me=True
                                    break
                            if _3short5me:
                                continue

                            while sum(sxx[freq][start_tim_index:end_tim_index+1])/(end_tim_index-start_tim_index) > 300 and sum(sxx[freq][end_tim_index:end_tim_index+5])/5 > 80:
                                # stop if avg for candidate < 300, or next 5 avg < 100
                                end_tim_index+=1

                            contain_peak = False
                            print(start_tim_index,end_tim_index)
                            print(peak_arr)
                            for peak in peak_arr:
                                if peak > start_tim_index and peak < end_tim_index:
                                    contain_peak = True
                                    break

                            if contain_peak:
                                candidate_ranges[freq]=(start_tim_index,end_tim_index)
                                break
                print("findranges")

                bestind = 0
                bestmax = 0
                print(candidate_ranges)

                if len(candidate_ranges) == 0:
                    outf.write(line[:-1]+",-1,0\n")
                    print(f"for {url} we cant detect")
                    continue

                if len(candidate_ranges) == 1:
                    whistle_start = t[candidate_ranges[list(candidate_ranges.keys())[0]][0]] # i think this works
                    outf.write(f"{line[:-1]},{whistle_start},sole1\n")
                    print(f"for {url} we think whistle start at {whistle_start}, sole1")
                    continue
                
                #for ind in candidate_ranges:
                    #print(ind)
                    #print(candidate_ranges[ind])
                    #print(candidate_ranges[ind][1]-candidate_ranges[ind][0])
                    #for i in sxx[ind][candidate_ranges[ind][0]:candidate_ranges[ind][1]]:
                    #    print(int(i),end=" ")

                    # HIGHEST PEAK WINS!!!!!!
                    #if max(sxx[ind][candidate_ranges[ind][0]:candidate_ranges[ind][1]])>bestmax: # maybe instead of highest peak try longest whistle?
                    #    bestind = ind
                    #    bestmax = max(sxx[ind][candidate_ranges[ind][0]:candidate_ranges[ind][1]])

                    # LONGEST PEAK WINS!!!!!!
                    #if candidate_ranges[ind][1] - candidate_ranges[ind][0] > bestmax:
                    #   bestind = ind
                    #   bestmax = candidate_ranges[ind][1] - candidate_ranges[ind][0]

                # IF GOT 2 SIMILAR, THEY WIN (most whistles seem to go across 2 freqs). IF MORE THAN 3 SIMILAR, THEN SUS
                spt = []
                for ind in candidate_ranges:
                    spt.append(candidate_ranges[ind][0])
                spt.sort()

                gotpair = False
                
                for i in range(len(spt)-1):
                    if math.isclose(spt[i],spt[i+1],abs_tol=50):
                        # make sure ONLY 2
                        morethantwo = False
                        for j in spt[:i]: # check before i
                            if math.isclose(spt[i], j, abs_tol=50):
                                morethantwo=True
                                break

                        for j in spt[i+2:]: # check after i+1
                            if math.isclose(spt[i+1],j, abs_tol=50):
                                morethantwo=True
                                break
                        if morethantwo:
                            continue
                        
                        whistle_start = min(t[spt[i]],t[spt[i+1]])
                        outf.write(f"{line[:-1]},{whistle_start},confclose\n")
                        print(f"for {url} we think whistle start at {whistle_start}, confclose")
                        gotpair=True
                        break
                if gotpair:
                    continue
                
                # NEXT DO LONGEST PEAK?? 
                for ind in candidate_ranges:
                    if candidate_ranges[ind][1] - candidate_ranges[ind][0] > bestmax:
                        bestind = ind
                        bestmax = candidate_ranges[ind][1] - candidate_ranges[ind][0]
                
                whistle_start = t[candidate_ranges[bestind][0]]
                print(f"for {url} we think whistle start at {whistle_start}, conflongest")
                outf.write(f"{line[:-1]},{whistle_start},conflong\n")

                
        except Exception as e:
            print(e)
   

