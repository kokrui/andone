from nba_api.stats.static import teams
from nba_api.stats.endpoints import leaguegamefinder, playbyplayv2
from nba_api.stats.library.parameters import Season, SeasonType
import json
import requests


nba_teams = teams.get_teams()

#response = requests.get('http://data.nba.com/data/v2015/json/mobile_teams/nba/2020/scores/pbp/0022000054_full_pbp.json')

#gameobj = json.loads(response.text)
#print(len(gameobj['g']))
#print(len(gameobj['g']['pd']))

event_map = {
    "FIELD_GOAL_MADE" : 1,
    "FIELD_GOAL_MISSED" : 2,
    "FREE_THROW" : 3, # dont want, use only for harden level thing detection lmao
    "REBOUND" : 4, # no team rebounds lmao
    "TURNOVER" : 5, # can, but exclude off. foul turnover (those will be covered in foul). run on oob?
    "FOUL" : 6,
    "VIOLATION" : 7,
    "SUBSTITUTION" : 8, # lol no
    "TIMEOUT" : 9, # nope
    "JUMP_BALL" : 10, # nah
    "EJECTION" : 11, # dont want
    "PERIOD_BEGIN" : 12, # dont want
    "PERIOD_END" : 13, # dont want
}

subevent_map = {
    # (etype,mtype)
    # only including stuff i will actually include in game

    # ALLOW ALL MADE/MISSED SHOTS

    # FOULS 
    "SHOOTING_FOUL":(6,2),
    "PERSONAL_FOUL":(6,1),
    "AWAY_FROM_BALL_FOUL":(6,6), # same as personal tbh
    "LOOSE_BALL_FOUL":(6,3), # same as personal again lol
    "OFFENSIVE_FOUL":(6,4),
    "OFFENSIVE_CHARGE_FOUL":(6,26), # same as offensive tbh
    "DEFENSIVE_3SEC_FOUL":(6,17),
    # (ignored: intentional fouls)

    # VIOLATIONS
    "GOALTENDING_VIOLATION":(7,2),
    # (ignored: delay of game, lane, kick. all these cos no video. also ignore offensive goaltending cos i dont have the time to manually find the code LMAO i search thru 10+ games all dont have)

    # TURNOVERS
    "OUT_OF_BOUNDS_TURNOVER":(5,39),
    "TRAVELLING_TURNOVER":(5,4), # yes
    "SHOT_CLOCK_TURNOVER":(5,11), # maybe
    "LOST_BALL_PICKPOCKET_TURNOVER":(5,2), # use this for hard, cos reachin vs successful == ???
    "OFFENSIVE_3SEC_TURNOVER":(5,8),
    
    #"OUT_OF_BOUNDS_BAD_PASS_TURNOVER":(5,45), # idk
    #"LIVE_BALL_BAD_PASS_TURNOVER":(5,1), # same idk
    #"OUT_OF_BOUNDS_LOST_BALL_TURNOVER":(5,30), # maybe not ah LOL    
    # (ignored: offensive foul turnover cos overlap, inbound cos rare, backcourt cos easy)

    # REBOUNDS
    "NORMAL_REBOUND":(4,0), # will have overlap with misses, but thats ok
    # (ignored: no team reb, usually overlap)

}



outfile = open("2020-21.csv", "a") # output file

gamesdone = {} # save time, prevent overlaps in games
for season in ["2020-21"]:
    for team in nba_teams:
        team_id = team['id']
        game_find = leaguegamefinder.LeagueGameFinder(team_id_nullable=team_id,
                            season_nullable=season,
                            season_type_nullable=SeasonType.regular)
        team_games = game_find.get_normalized_dict()['LeagueGameFinderResults']
        for gamedict in team_games:
            #print(gamedict)
            gid = gamedict['GAME_ID']
            if gid in gamesdone:
                continue
            gamesdone[gid]=True
            pbp_resp = requests.get(f'http://data.nba.com/data/v2015/json/mobile_teams/nba/{season[:4]}/scores/pbp/{gid}_full_pbp.json')
            pbp_obj = json.loads(pbp_resp.text)
            for period in pbp_obj['g']['pd']:
                for i in range(len(period['pla'])):
                    event = period['pla'][i]
                    if (event['etype'],event['mtype']) in subevent_map.values() or event['etype'] == 1 or event['etype'] == 2:
                    # now this is valid event
                        outstr = ""
                        outstr+=f"{gid},{event['evt']},{event['etype']},{event['mtype']}"

                        # check and add needwhistle
                        if event['etype'] == 1 or event['etype'] == 2 or event['etype'] == 4 or (event['etype'] == 5 and event['mtype'] == 2):
                            # if made shot, missed shot, live rebound, live "pickpocket" steal, dont need detect whistle!
                            outstr+=",0"
                        else:
                            # try detect whistle!
                            outstr+=",1"

                        # the harden thing LOL
                        if "Harden" in event['de']:
                            outstr+=",HARDEN0"  
                        elif "Harden Free Throw 1 of 2" in period['pla'][i+1]['de']: # dont need to care about i==n, because last event will be "period end" which wont reach this if statement (I THINK LOL PLS WORK)
                            outstr+=",HARDEN2"
                        elif "Harden Free Throw 1 of 3" in period['pla'][i+1]['de']: 
                            outstr+=",HARDEN3"
                        else:
                           outstr+=",0"

                        outstr+="\n"
                        outfile.write(outstr)
                        
# OUTPUT FILE FORMAT, NO RDBMS
# gameid, eventid, eventtype, eventsubtype, needwhistle, hardenelig
