// S1 GSC for infect, modified by mikey for H2M

main()
{
    if (getdvar("mapname") == "mp_background")
        return;

    maps\mp\gametypes\_globallogic::init();
    maps\mp\gametypes\_callbacksetup::setupcallbacks();
    maps\mp\gametypes\_globallogic::setupcallbacks();

    if (isusingmatchrulesdata())
    {
        level.initializematchrules = ::initializematchrules;
        [[ level.initializematchrules ]]();
        level thread maps\mp\_utility::reinitializematchrulesonmigration();
    }
    else
    {
        maps\mp\_utility::registertimelimitdvar(level.gametype, 10);
        maps\mp\_utility::setoverridewatchdvar("scorelimit", 0);
        maps\mp\_utility::registerroundlimitdvar(level.gametype, 1);
        maps\mp\_utility::registerwinlimitdvar(level.gametype, 1);
        maps\mp\_utility::registernumlivesdvar(level.gametype, 0);
        maps\mp\_utility::registerhalftimedvar(level.gametype, 0);
        level.matchrules_numinitialinfected = 1;
        level.matchrules_damagemultiplier = 0;
    }

    //setdynamicdvar("scr_game_high_jump", 1);
    //setdynamicdvar("jump_slowdownEnable", 0);

    setup_survivor_classes();
    setspecialloadouts();

    level.teambased = true;
    level.doprematch = true;
    level.disableforfeit = true;
    level.nobuddyspawns = true;
    level.onstartgametype = ::onstartgametype;
    level.onspawnplayer = ::onspawnplayer;
    level.getspawnpoint = ::getspawnpoint;
    level.onplayerkilled = ::onplayerkilled;
    //level.ondeadevent = ::ondeadevent;
    level.ontimelimit = ::ontimelimit;
    level.autoassign = ::infectautoassign;
    level.bypassclasschoicefunc = ::infectedclass;

    if (level.matchrules_damagemultiplier)
        level.modifyplayerdamage = maps\mp\gametypes\_damage::gamemodemodifyplayerdamage;

    game["dialog"]["gametype"] = "inf_intro";

    if (getdvarint("g_hardcore"))
        game["dialog"]["gametype"] = "hc_" + game["dialog"]["gametype"];

    game["dialog"]["offense_obj"] = "inf_survive";
    game["dialog"]["defense_obj"] = "inf_survive";
    game["dialog"]["first_infected"] = "inf_patientzero";
    game["dialog"]["time_extended"] = "inf_extratime";
    game["dialog"]["lone_survivor"] = "inf_lonesurvivor";
    game["dialog"]["been_infected"] = "inf_been_infected";
}

init()
{
	setDvar("sv_cheats", 1);
	setDvar("sv_enableBounces", 1);
	setDvar("player_sustainammo", 0);
	setDvar("jump_slowdownEnable", 0);
	setDvar("g_speed", 245);
	setDvar("jump_stepSize" , 256);
	setDvar("jump_autoBunnyHop" , 1);
	SetDvar ("Players_jump_hight" , 256) ;
	setDvar("player_meleeRange" , 1);
	setDvar("jump_disablefalldamage" , 1);
	setDvar("sv_allowOwnerConsole" , 1);
	setDvar("g_intermissionTime" , 0);
	setDvar("bg_fallDamageMaxHeight", (9999) );
}

initializematchrules()
{
    maps\mp\_utility::setcommonrulesfrommatchrulesdata();

    level.matchrules_numinitialinfected = getmatchrulesdata("infectData", "numInitialInfected");
    if (!isdefined(level.matchrules_numinitialinfected))
    {
        level.matchrules_numinitialinfected = 1;
    }

    setdynamicdvar("scr_" + level.gametype + "_numLives", 0);
    maps\mp\_utility::registernumlivesdvar(level.gametype, 0);
    maps\mp\_utility::setoverridewatchdvar("scorelimit", 0);
    setdynamicdvar("scr_infect_roundswitch", 0);
    maps\mp\_utility::registerroundswitchdvar("infect", 0, 0, 9);
    setdynamicdvar("scr_infect_roundlimit", 1);
    maps\mp\_utility::registerroundlimitdvar("infect", 1);
    setdynamicdvar("scr_infect_winlimit", 1);
    maps\mp\_utility::registerwinlimitdvar("infect", 1);
    setdynamicdvar("scr_infect_halftime", 0);
    maps\mp\_utility::registerhalftimedvar("infect", 0);
    setdynamicdvar("scr_infect_playerrespawndelay", 0);
    setdynamicdvar("scr_infect_waverespawndelay", 0);
    setdynamicdvar("scr_player_forcerespawn", 1);
    setdynamicdvar("scr_team_fftype", 0);

    // TODO
    //setdynamicdvar("scr_game_hardpoints", 0);
}

onstartgametype()
{
    setclientnamemode("auto_change");

    maps\mp\_utility::setobjectivetext("allies", &"OBJECTIVES_INFECT");
    maps\mp\_utility::setobjectivetext("axis", &"OBJECTIVES_INFECT");

    if (level.splitscreen)
    {
        maps\mp\_utility::setobjectivescoretext("allies", &"OBJECTIVES_INFECT");
        maps\mp\_utility::setobjectivescoretext("axis", &"OBJECTIVES_INFECT");
    }
    else
    {
        maps\mp\_utility::setobjectivescoretext("allies", &"OBJECTIVES_INFECT_SCORE");
        maps\mp\_utility::setobjectivescoretext("axis", &"OBJECTIVES_INFECT_SCORE");
    }

    maps\mp\_utility::setobjectivehinttext("allies", &"OBJECTIVES_INFECT_HINT");
    maps\mp\_utility::setobjectivehinttext("axis", &"OBJECTIVES_INFECT_HINT");
    initspawns();
    var_0[0] = level.gametype;
    maps\mp\gametypes\_gameobjects::main(var_0);
    level.quickmessagetoall = 1;
    level.blockweapondrops = 1;
    level.infect_allowsuicide = 0;
    level.infect_chosefirstinfected = 0;
    level.infect_choosingfirstinfected = 0;
    level.infect_countdowninprogress = 0;
    level.infect_teamscores["axis"] = 0;
    level.infect_teamscores["allies"] = 0;
    level.infect_players = [];
    level thread onplayerconnect();
    level thread gametimer();
}

gametimer()
{
    level endon("game_ended");

    setdynamicdvar("scr_infect_timelimit", 0);

    var_0 = 0;

    for(;;)
    {
        level waittill("update_game_time", var_1);

        if (!isdefined(var_1))
            var_1 = (maps\mp\_utility::gettimepassed() + 1500) / 60000 + 2;

        setdynamicdvar("scr_infect_timelimit", var_1);
        level thread watchhostmigration(var_1);

        if (var_0)
            level thread maps\mp\_utility::leaderdialogbothteams("time_extended", "axis", "time_extended", "allies", "status");

        var_0 = 1;
    }
}

watchhostmigration(var_0)
{
    level notify("watchHostMigration");
    level endon("watchHostMigration");
    level endon("game_ended");
    level waittill("host_migration_begin");
    setdynamicdvar("scr_infect_timelimit", 0);
    waittillframeend;
    setdynamicdvar("scr_infect_timelimit", 0);
    level waittill("host_migration_end");
    level notify("update_game_time", var_0);
}

onplayerconnect()
{
    level endon("game_ended");
    for(;;)
    {
        level waittill("connected", player);

        player.infectedrejoined = 0;
        player.killsasinfected = 0;

        if (maps\mp\_utility::gameflag("prematch_done"))
        {
            if (isdefined(level.infect_chosefirstinfected) && level.infect_chosefirstinfected)
                player.survivalstarttime = gettime();
        }

        if (isdefined(level.infect_players[player.name]))
            player.infectedrejoined = 1;

        player thread monitorsurvivaltime();
    }
}

initspawns()
{
    level.spawnmins = (0, 0, 0);
    level.spawnmaxs = (0, 0, 0);
    maps\mp\gametypes\_spawnlogic::addspawnpoints("allies", "mp_tdm_spawn");
    maps\mp\gametypes\_spawnlogic::addspawnpoints("axis", "mp_tdm_spawn");
    level.mapcenter = maps\mp\gametypes\_spawnlogic::findboxcenter(level.spawnmins, level.spawnmaxs);
    setmapcenter(level.mapcenter);
}

infectautoassign()
{
    team = "allies";
    if (self.infectedrejoined)
        team = "axis";

    thread maps\mp\gametypes\_menus::setteam(team);
}

getspawnpoint()
{
    if (level.ingraceperiod)
    {
        var_0 = maps\mp\gametypes\_spawnlogic::getspawnpointarray("mp_tdm_spawn");
        var_1 = maps\mp\gametypes\_spawnlogic::getspawnpoint_random(var_0);
    }
    else
    {
        var_0 = maps\mp\gametypes\_spawnlogic::getteamspawnpoints(self.pers["team"]);
        var_1 = maps\mp\gametypes\_spawnscoring::getspawnpoint_nearteam(var_0);
    }

    maps\mp\gametypes\_spawnlogic::recon_set_spawnpoint(var_1);
    return var_1;
}

infectedclass()
{
    self.pers["class"] = "gamemode";
    self.pers["lastClass"] = "";
    self.pers["gamemodeLoadout"] = level.infect_loadouts[self.pers["team"]];
    self.class = self.pers["class"];
    self.lastclass = self.pers["lastClass"];
}

onspawnplayer()
{
    if (isdefined(self.teamchangedthisframe))
    {
        self.pers["gamemodeLoadout"] = level.infect_loadouts[self.pers["team"]];
        maps\mp\gametypes\_class::giveloadout(self.team, self.class);
        thread monitordisconnect();
    }

    self.teamchangedthisframe = undefined;
    updateteamscores();

    if (!level.infect_choosingfirstinfected)
    {
        level.infect_choosingfirstinfected = 1;
        level thread choosefirstinfected();
    }

    if (self.infectedrejoined)
    {
        if (!level.infect_allowsuicide)
        {
            level notify("infect_stopCountdown");
            level.infect_chosefirstinfected = 1;
            level.infect_allowsuicide = 1;

            foreach (var_1 in level.players)
            {
                if (isdefined(var_1.infect_isbeingchosen))
                    var_1.infect_isbeingchosen = undefined;
            }
        }

        foreach (var_1 in level.players)
        {
            if (isdefined(var_1.isinitialinfected))
                var_1 thread setinitialtonormalinfected();
        }

        if (level.infect_teamscores["axis"] == 1)
            self.isinitialinfected = 1;

        clearsurvivaltime();
    }

    if (isdefined(self.isinitialinfected))
    {
        self.pers["gamemodeLoadout"] = level.infect_loadouts["axis_initial"];
        maps\mp\gametypes\_class::giveloadout(self.team, self.class);
    }

    thread onspawnfinished();
    level notify("spawned_player");
}

onspawnfinished()
{
    self endon("death");
    self endon("disconnect");
    self waittill("applyLoadout");
    updateloadouts();
}

updateloadouts()
{
    //if (self.pers["team"] == "allies")
    //    maps\mp\_utility::giveperk("specialty_extended_battery", 0);

    if (self.pers["team"] == "axis")
    {
        thread setinfectedmsg();
        self setmovespeedscale(1.2); // TODO: zombies are .2 faster than humans
    }
}

gotinfectedevent()
{
    maps\mp\_utility::incplayerstat("careless", 1);
    level thread maps\mp\gametypes\_rank::awardgameevent("got_infected", self);
}

setinfectedmsg()
{
    if (!isdefined(self.showninfected) || !self.showninfected)
    {
        gotinfectedevent();
        self playsoundtoplayer("mp_inf_got_infected", self);
        maps\mp\_utility::leaderdialogonplayer("been_infected", "status");
        self.showninfected = 1;
    }
}

choosefirstinfected()
{
    level endon("game_ended");
    level endon("infect_stopCountdown");
    level.infect_allowsuicide = 0;
    maps\mp\_utility::gameflagwait("prematch_done");
    level.infect_countdowninprogress = 1;
    maps\mp\gametypes\_hostmigration::waitlongdurationwithhostmigrationpause(1.0);
    var_0 = 15;
    setomnvar("ui_match_countdown_title", 7);
    setomnvar("ui_match_countdown_toggle", 1);

    while (var_0 > 0 && !level.gameended)
    {
        var_0--;
        setomnvar("ui_match_countdown", var_0 + 1);
        maps\mp\gametypes\_hostmigration::waitlongdurationwithhostmigrationpause(1.0);
    }

    setomnvar("ui_match_countdown", 1);
    setomnvar("ui_match_countdown_title", 0);
    setomnvar("ui_match_countdown_toggle", 0);
    level.infect_countdowninprogress = 0;
    var_1 = [];
    var_2 = undefined;

    foreach (var_4 in level.players)
    {
        if (maps\mp\_utility::matchmakinggame() && level.players.size > 1 && var_4 ishost())
        {
            var_2 = var_4;
            continue;
        }

        if (var_4.team == "spectator")
            continue;

        if (!var_4.hasspawned)
            continue;

        var_1[var_1.size] = var_4;
    }

    if (!var_1.size && isdefined(var_2))
        var_1[var_1.size] = var_2;

    var_6 = var_1[randomint(var_1.size)];
    var_6 setfirstinfected(1);

    foreach (var_4 in level.players)
    {
        if (var_4 == var_6)
            continue;

        var_4.survivalstarttime = gettime();
    }
}



prepareforclasschange()
{
    self endon("disconnect");
    level endon("game_ended");

    while (!maps\mp\_utility::isreallyalive(self) || maps\mp\_utility::isusingremote())
        wait 0.05;

    if (isdefined(self.iscarrying) && self.iscarrying == 1)
    {
        self notify("force_cancel_placement");
        wait 0.05;
    }

    while (self ismeleeing())
        wait 0.05;

    while (self ismantling())
        wait 0.05;

    while (!self isonground() && !self isonladder())
        wait 0.05;

    if (maps\mp\_utility::isjuggernaut())
    {
        self notify("lost_juggernaut");
        wait 0.05;
    }

    //maps\mp\_exo_ping::stop_exo_ping();
    //maps\mp\_extrahealth::stopextrahealth();
    //maps\mp\_adrenaline::stopadrenaline();
    //maps\mp\_exo_cloak::active_cloaking_disable();
    //maps\mp\_exo_mute::stop_exo_mute();
    //maps\mp\_exo_repulsor::stop_repulsor();
    wait 0.05;

    while (!maps\mp\_utility::isreallyalive(self))
        wait 0.05;
}

firstinfectedevent()
{
    maps\mp\_utility::incplayerstat("patientzero", 1);
    maps\mp\_utility::playsoundonplayers("mp_enemy_obj_captured");
    level thread maps\mp\_utility::teamplayercardsplash("callout_first_infected", self);
    level thread maps\mp\gametypes\_rank::awardgameevent("first_infected", self);
    self.patient_zero = 0;
}

setfirstinfected(var_0)
{
    self endon("disconnect");
    prepareforclasschange();

    if (var_0)
    {
        self.infect_isbeingchosen = 1;
        maps\mp\gametypes\_menus::addtoteam("axis", undefined, 1);
        thread monitordisconnect();
        level.infect_chosefirstinfected = 1;
        self.infect_isbeingchosen = undefined;
        level notify("update_game_time");
        updateteamscores();
        level.infect_allowsuicide = 1;
        level.infect_players[self.name] = 1;
    }

    self.isinitialinfected = 1;
    self.showninfected = 1;
    self notify("faux_spawn");
    self.pers["gamemodeLoadout"] = level.infect_loadouts["axis_initial"];
    maps\mp\gametypes\_class::giveandapplyloadout(self.team, "gamemode");
    updateloadouts();
    firstinfectedevent();
    self playsoundtoplayer("mp_inf_got_infected", self);
    maps\mp\_utility::leaderdialogonplayer("first_infected", "status");
    clearsurvivaltime();
}

setinitialtonormalinfected()
{
    level endon("game_ended");
    self.isinitialinfected = undefined;
    prepareforclasschange();
    self notify("faux_spawn");
    self.pers["gamemodeLoadout"] = level.infect_loadouts["axis"];
    thread onspawnfinished();
    maps\mp\gametypes\_class::giveandapplyloadout(self.team, "gamemode");
}

plagueevent()
{
    maps\mp\_utility::incplayerstat("plague", 1);
    level thread maps\mp\gametypes\_rank::awardgameevent("infected_plague", self);
}

infectedsurvivorevent()
{
    maps\mp\_utility::incplayerstat("contagious", 1);
    level thread maps\mp\_utility::teamplayercardsplash("callout_infected_survivor", self, "axis");
    level thread maps\mp\gametypes\_rank::awardgameevent("infected_survivor", self);
}

onplayerkilled(var_0, var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9)
{
    if (!isdefined(var_1))
        return;

    if (self.team == "axis" && isplayer(var_1) && var_1.team == "allies" && maps\mp\_utility::ismeleemod(var_3))
        var_1 maps\mp\gametypes\_missions::processchallenge("ch_infect_tooclose");

    if (self.team == "axis")
        return;

    var_10 = var_1 == self || !isplayer(var_1);

    if (var_10 && !level.infect_allowsuicide)
        return;

    level notify("update_game_time");
    self notify("delete_explosive_drones");
    self.teamchangedthisframe = 1;
    maps\mp\gametypes\_menus::addtoteam("axis");
    setsurvivaltime(1);
    updateteamscores();
    maps\mp\_utility::playsoundonplayers("mp_enemy_obj_captured", "allies");
    maps\mp\_utility::playsoundonplayers("mp_war_objective_taken", "axis");
    level.infect_players[self.name] = 1;
    level thread maps\mp\_utility::teamplayercardsplash("callout_got_infected", self, "allies");

    if (!var_10)
    {
        var_1 infectedsurvivorevent();
        var_1 playsoundtoplayer("mp_inf_infection_kill", var_1);
        var_1.killsasinfected++;

        if (var_1.killsasinfected == 3)
        {
            var_1 plagueevent();
            var_1.killsasinfected = 0;
        }
    }

    if (level.infect_teamscores["axis"] == 2)
    {
        foreach (var_12 in level.players)
        {
            if (isdefined(var_12.isinitialinfected))
                var_12 thread setinitialtonormalinfected();
        }
    }

    if (level.infect_teamscores["allies"] == 0)
    {
        onsurvivorseliminated();
        return;
    }

    if (level.infect_teamscores["allies"] == 1)
    {
        onfinalsurvivor();
        return;
    }
}

finalsurvivorevent()
{
    maps\mp\_utility::incplayerstat("omegaman", 1);
    maps\mp\_utility::playsoundonplayers("mp_obj_captured");
    level thread maps\mp\_utility::teamplayercardsplash("callout_final_survivor", self);
    level thread maps\mp\gametypes\_rank::awardgameevent("final_survivor", self);
    maps\mp\gametypes\_missions::processchallenge("ch_" + level.gametype + "_survivor");
}

onfinalsurvivor()
{
    foreach (var_1 in level.players)
    {
        if (!isdefined(var_1))
            continue;

        if (var_1.team != "allies")
            continue;

        if (isdefined(var_1.awardedfinalsurvivor))
            continue;

        var_1.awardedfinalsurvivor = 1;
        var_1 thread finalsurvivorevent();
        var_1 thread maps\mp\_utility::leaderdialogonplayer("lone_survivor", "status");
        level thread finalsurvivoruav(var_1);
        break;
    }
}

finalsurvivoruav(var_0)
{
    level endon("game_ended");
    var_0 endon("disconnect");
    var_0 endon("eliminated");
    level endon("infect_lateJoiner");
    level thread enduavonlatejoiner(var_0);
    var_1 = 0;
    level.radarmode["axis"] = "normal_radar";

    foreach (var_3 in level.players)
    {
        if (var_3.team == "axis")
            var_3.radarmode = "normal_radar";
    }

    setteamradarstrength("axis", 1);

    for (;;)
    {
        var_5 = var_0.origin;
        wait 4;

        if (var_1)
        {
            setteamradar("axis", 0);
            var_1 = 0;
        }

        wait 6;

        if (distance(var_5, var_0.origin) < 200)
        {
            setteamradar("axis", 1);
            var_1 = 1;

            foreach (var_3 in level.players)
                var_3 playlocalsound("recondrone_tag");
        }
    }
}

enduavonlatejoiner(var_0)
{
    level endon("game_ended");
    var_0 endon("disconnect");
    var_0 endon("eliminated");

    for (;;)
    {
        if (level.infect_teamscores["allies"] > 1)
        {
            level notify("infect_lateJoiner");
            wait 0.05;
            setteamradar("axis", 0);
            break;
        }

        wait 0.05;
    }
}

monitordisconnect()
{
    level endon("game_ended");
    self endon("eliminated");
    self notify("infect_monitor_disconnect");
    self endon("infect_monitor_disconnect");
    var_0 = self.team;

    if (!isdefined(var_0) && isdefined(self.bot_team))
        var_0 = self.bot_team;

    self waittill("disconnect");
    updateteamscores();

    if (isdefined(self.infect_isbeingchosen) || level.infect_chosefirstinfected)
    {
        if (level.infect_teamscores["axis"] && level.infect_teamscores["allies"])
        {
            if (var_0 == "allies" && level.infect_teamscores["allies"] == 1)
                onfinalsurvivor();
            else if (var_0 == "axis" && level.infect_teamscores["axis"] == 1)
            {
                foreach (var_2 in level.players)
                {
                    if (var_2 != self && var_2.team == "axis")
                        var_2 setfirstinfected(0);
                }
            }
        }
        else if (level.infect_teamscores["allies"] == 0)
            onsurvivorseliminated();
        else if (level.infect_teamscores["axis"] == 0)
        {
            if (level.infect_teamscores["allies"] == 1)
            {
                level.finalkillcam_winner = "allies";
                level thread maps\mp\gametypes\_gamelogic::endgame("allies", game["end_reason"]["infected_eliminated"]);
            }
            else if (level.infect_teamscores["allies"] > 1)
            {
                level.infect_chosefirstinfected = 0;
                level thread choosefirstinfected();
            }
        }
    }
    else if (level.infect_countdowninprogress && level.infect_teamscores["allies"] == 0 && level.infect_teamscores["axis"] == 0)
    {
        level notify("infect_stopCountdown");
        level.infect_choosingfirstinfected = 0;
        setomnvar("ui_match_start_countdown", 0);
    }

    self.isinitialinfected = undefined;
}

ontimelimit()
{
    level.finalkillcam_winner = "allies";
    level thread maps\mp\gametypes\_gamelogic::endgame("allies", game["end_reason"]["time_limit_reached"]);
}

onsurvivorseliminated()
{
    level.finalkillcam_winner = "axis";
    level thread maps\mp\gametypes\_gamelogic::endgame("axis", game["end_reason"]["survivors_eliminated"]);
}

getteamsize(var_0)
{
    var_1 = 0;

    foreach (var_3 in level.players)
    {
        if (var_3.sessionstate == "spectator" && !var_3.spectatekillcam)
            continue;

        if (var_3.team == var_0)
            var_1++;
    }

    return var_1;
}

updateteamscores()
{
    level.infect_teamscores["allies"] = getteamsize("allies");
    game["teamScores"]["allies"] = level.infect_teamscores["allies"];
    setteamscore("allies", level.infect_teamscores["allies"]);
    level.infect_teamscores["axis"] = getteamsize("axis");
    game["teamScores"]["axis"] = level.infect_teamscores["axis"];
    setteamscore("axis", level.infect_teamscores["axis"]);
}

// class utils
setup_survivor_classes()
{
    level.infect_survivor_classes = [];
    for (i = 0; i < 10; i++)
    {
        level.infect_survivor_classes[i] = [];
        level.infect_survivor_classes[i]["attachment"] = "none";
        level.infect_survivor_classes[i]["second_attachment"] = "none";
        level.infect_survivor_classes[i]["equipment"] = "h1_c4_mp";
    }

    level.infect_survivor_classes[0]["weapon"] = "h2_glock";
    level.infect_survivor_classes[0]["attachment"] = "akimbo";

    level.infect_survivor_classes[1]["weapon"] = "h2_striker";

    level.infect_survivor_classes[2]["weapon"] = "h2_barrett";
    level.infect_survivor_classes[2]["second_weapon"] = "h2_usp";
    level.infect_survivor_classes[2]["second_attachment"] = "akimbo";

    level.infect_survivor_classes[3]["weapon"] = "h2_p90";
    level.infect_survivor_classes[3]["second_weapon"] = "h2_coltanaconda";
    level.infect_survivor_classes[3]["second_attachment"] = "akimbo";
    level.infect_survivor_classes[3]["equipment"] = "h1_claymore_mp";

    level.infect_survivor_classes[4]["weapon"] = "h2_m16";
    level.infect_survivor_classes[4]["attachment"] = "holosightmwr";
    level.infect_survivor_classes[4]["equipment"] = "h1_claymore_mp";

    level.infect_survivor_classes[5]["weapon"] = "h2_model1887";
    level.infect_survivor_classes[5]["attachment"] = "akimbo";
    level.infect_survivor_classes[5]["equipment"] = "h2_semtex_mp";

    level.infect_survivor_classes[6]["weapon"] = "h2_mp5k";
    level.infect_survivor_classes[6]["second_weapon"] = "h2_deserteagle";
    level.infect_survivor_classes[6]["second_attachment"] = "akimbo";
    level.infect_survivor_classes[6]["equipment"] = "h1_claymore_mp";

    level.infect_survivor_classes[7]["weapon"] = "h2_famas";
    level.infect_survivor_classes[7]["attachment"] = "reflex";
    level.infect_survivor_classes[7]["equipment"] = "h2_semtex_mp";

    level.infect_survivor_classes[8]["weapon"] = "h1_m14";
    level.infect_survivor_classes[8]["second_weapon"] = "h2_colt45";
    level.infect_survivor_classes[8]["second_attachment"] = "akimbo";

    level.infect_survivor_classes[9]["second_weapon"] = "h2_beretta393";
    level.infect_survivor_classes[9]["second_attachment"] = "akimbo";
}

get_survivor_class_data()
{
    if (!isdefined(level.infect_survivor_class_index))
    {
        level.infect_survivor_class_index = randomintrange(0, level.infect_survivor_classes.size);
    }
    return level.infect_survivor_classes[level.infect_survivor_class_index];
}

// TODO: match rules need re-wrote, review LUI
setspecialloadouts()
{
    level.infect_loadouts["allies"] = maps\mp\gametypes\_class::getemptyloadout();

    // setup custom class data
    class_data = get_survivor_class_data();
    if (isdefined(class_data["weapon"]))
    {
        level.infect_loadouts["allies"]["loadoutPrimary"] = class_data["weapon"];
        level.infect_loadouts["allies"]["loadoutPrimaryAttachKit"] = class_data["attachment"];
    }

    if (isdefined(class_data["second_weapon"]))
    {
        level.infect_loadouts["allies"]["loadoutSecondary"] = class_data["second_weapon"];
        level.infect_loadouts["allies"]["loadoutSecondaryAttachKit"] = class_data["second_attachment"];
    }

    level.infect_loadouts["allies"]["loadoutPerks"][4] = "specialty_class_scavenger";

    if (isdefined(class_data["equipment"]))
        level.infect_loadouts["allies"]["loadoutEquipment"] = class_data["equipment"];

    level.infect_loadouts["allies"]["loadoutOffhand"] = "none";

    level.infect_loadouts["axis_initial"] = maps\mp\gametypes\_class::getemptyloadout();
    level.infect_loadouts["axis_initial"]["loadoutPrimary"] = "h2_usp";
    level.infect_loadouts["axis_initial"]["loadoutSecondary"] = "h2_infect";
    level.infect_loadouts["axis_initial"]["loadoutEquipment"] = "iw9_throwknife_mp";

    level.infect_loadouts["axis"] = maps\mp\gametypes\_class::getemptyloadout();
    level.infect_loadouts["axis"]["loadoutPrimary"] = "h2_infect";
    level.infect_loadouts["axis"]["loadoutEquipment"] = "iw9_throwknife_mp";
}

survivorevent()
{
    maps\mp\_utility::incplayerstat("survivor", 1);
    level thread maps\mp\gametypes\_rank::awardgameevent("survivor", self);
}

monitorsurvivaltime()
{
    self endon("death");
    self endon("disconnect");
    self endon("infected");
    level endon("game_ended");
    var_0 = 0;

    for (;;)
    {
        if (!level.infect_chosefirstinfected || !isdefined(self.survivalstarttime) || !isalive(self))
        {
            wait 0.05;
            continue;
        }

        setsurvivaltime(0);
        var_0++;
        maps\mp\gametypes\_hostmigration::waitlongdurationwithhostmigrationpause(1.0);

        if (var_0 == 30)
        {
            survivorevent();
            var_0 = 0;
        }

        wait 0.05;
    }
}

clearsurvivaltime()
{
    maps\mp\_utility::setextrascore0(0);
    self notify("infected");
    maps\mp\_utility::setextrascore1(1);
}

setsurvivaltime(var_0)
{
    if (!isdefined(self.survivalstarttime))
        self.survivalstarttime = self.spawntime;

    var_1 = int((gettime() - self.survivalstarttime) / 1000);

    if (var_1 > 999)
        var_1 = 999;

    maps\mp\_utility::setextrascore0(var_1);

    if (isdefined(var_0) && var_0)
    {
        self notify("infected");
        maps\mp\_utility::setextrascore1(1);
    }
}
