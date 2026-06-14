#include <YSI_Coding\y_hooks>

#define LOADING_BAR_MAX_WIDTH   44.0
#define LOADING_BAR_TICK        50

new Text:LoadingBar[4];
new Text:LoadingBarFill;

new bool:LB_Active[MAX_PLAYERS];
new       LB_Elapsed[MAX_PLAYERS];
new       LB_Duration[MAX_PLAYERS];
new Timer:LB_Timer[MAX_PLAYERS];

hook OnGameModeInit()
{
    LoadingBar[0] = TextDrawCreate(14.000, 247.000, "LD_DUAL:white");
    TextDrawTextSize(LoadingBar[0], 72.000, 25.000);
    TextDrawAlignment(LoadingBar[0], 1);
    TextDrawColor(LoadingBar[0], 255);
    TextDrawSetShadow(LoadingBar[0], 0);
    TextDrawSetOutline(LoadingBar[0], 0);
    TextDrawBackgroundColor(LoadingBar[0], 255);
    TextDrawFont(LoadingBar[0], 4);
    TextDrawSetProportional(LoadingBar[0], 1);

    LoadingBar[1] = TextDrawCreate(38.000, 255.000, "LD_DUAL:white");
    TextDrawTextSize(LoadingBar[1], 44.000, 8.000);
    TextDrawAlignment(LoadingBar[1], 1);
    TextDrawColor(LoadingBar[1], 1768516095);
    TextDrawSetShadow(LoadingBar[1], 0);
    TextDrawSetOutline(LoadingBar[1], 0);
    TextDrawBackgroundColor(LoadingBar[1], 255);
    TextDrawFont(LoadingBar[1], 4);
    TextDrawSetProportional(LoadingBar[1], 1);

    LoadingBarFill = TextDrawCreate(38.000, 255.000, "LD_DUAL:white");
    TextDrawTextSize(LoadingBarFill, 44.000, 8.000);
    TextDrawAlignment(LoadingBarFill, 1);
    TextDrawColor(LoadingBarFill, -1);
    TextDrawSetShadow(LoadingBarFill, 0);
    TextDrawSetOutline(LoadingBarFill, 0);
    TextDrawBackgroundColor(LoadingBarFill, 255);
    TextDrawFont(LoadingBarFill, 4);
    TextDrawSetProportional(LoadingBarFill, 1);

    LoadingBar[2] = TextDrawCreate(18.000, 251.000, "_");
    TextDrawTextSize(LoadingBar[2], 15.000, 15.000);
    TextDrawAlignment(LoadingBar[2], 1);
    TextDrawColor(LoadingBar[2], -1);
    TextDrawSetShadow(LoadingBar[2], 0);
    TextDrawSetOutline(LoadingBar[2], 0);
    TextDrawBackgroundColor(LoadingBar[2], 0);
    TextDrawFont(LoadingBar[2], 5);
    TextDrawSetProportional(LoadingBar[2], 0);
    TextDrawSetPreviewModel(LoadingBar[2], 1316);
    TextDrawSetPreviewRot(LoadingBar[2], 90.000, 0.000, 0.000, 1.000);
    TextDrawSetPreviewVehCol(LoadingBar[2], 0, 0);

    LoadingBar[3] = TextDrawCreate(60.000, 255.000, "LOADING");
    TextDrawLetterSize(LoadingBar[3], 0.189, 0.898);
    TextDrawAlignment(LoadingBar[3], 2);
    TextDrawColor(LoadingBar[3], 255);
    TextDrawSetShadow(LoadingBar[3], 0);
    TextDrawSetOutline(LoadingBar[3], 0);
    TextDrawBackgroundColor(LoadingBar[3], 150);
    TextDrawFont(LoadingBar[3], 1);
    TextDrawSetProportional(LoadingBar[3], 1);

    return 1;
}

hook OnPlayerConnect(playerid)
{
    LB_Active[playerid]   = false;
    LB_Elapsed[playerid]  = 0;
    LB_Duration[playerid] = 0;
    LB_Timer[playerid]    = Timer:-1;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    LoadingBar_Hide(playerid);
    return 1;
}

stock LoadingBar_Show(playerid, duration_ms, const label[] = "LOADING", previewmodel = 1316)
{
    if (!IsPlayerConnected(playerid)) return;

    LoadingBar_Hide(playerid);

    LB_Active[playerid]   = true;
    LB_Elapsed[playerid]  = 0;
    LB_Duration[playerid] = duration_ms;

    TextDrawSetString(LoadingBar[3], label);
    TextDrawSetPreviewModel(LoadingBar[2], previewmodel);
    TextDrawTextSize(LoadingBarFill, 0.5, 8.000);

    TextDrawShowForPlayer(playerid, LoadingBar[0]);
    TextDrawShowForPlayer(playerid, LoadingBar[1]);
    TextDrawShowForPlayer(playerid, LoadingBarFill);
    TextDrawShowForPlayer(playerid, LoadingBar[2]);
    TextDrawShowForPlayer(playerid, LoadingBar[3]);

    LB_Timer[playerid] = repeat LoadingBar_Tick(playerid);
}

stock LoadingBar_Hide(playerid)
{
    if (!IsPlayerConnected(playerid)) return;

    if (LB_Timer[playerid] != Timer:-1) {
        stop LB_Timer[playerid];
        LB_Timer[playerid] = Timer:-1;
    }

    if (LB_Active[playerid]) {
        TextDrawHideForPlayer(playerid, LoadingBar[0]);
        TextDrawHideForPlayer(playerid, LoadingBar[1]);
        TextDrawHideForPlayer(playerid, LoadingBarFill);
        TextDrawHideForPlayer(playerid, LoadingBar[2]);
        TextDrawHideForPlayer(playerid, LoadingBar[3]);
        LB_Active[playerid] = false;
    }

    LB_Elapsed[playerid]  = 0;
    LB_Duration[playerid] = 0;
}

timer LoadingBar_Tick[LOADING_BAR_TICK](playerid)
{
    if (!IsPlayerConnected(playerid)) {
        LoadingBar_Hide(playerid);
        return;
    }

    LB_Elapsed[playerid] += LOADING_BAR_TICK;

    if (LB_Elapsed[playerid] >= LB_Duration[playerid]) {
        LoadingBar_Hide(playerid);
        return;
    }

    new Float:barW = (float(LB_Elapsed[playerid]) / float(LB_Duration[playerid])) * LOADING_BAR_MAX_WIDTH;
    if (barW < 0.5) barW = 0.5;

    TextDrawTextSize(LoadingBarFill, barW, 8.000);
    TextDrawShowForPlayer(playerid, LoadingBarFill);
}
