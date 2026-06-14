#include <YSI_Coding\y_hooks>

#define DI_BAR_MAX_WIDTH    61.0
#define DI_HIDE_DELAY       4000

new Text:DamageIndicator_Background;
new Text:DamageIndicator_NamePlayer;
new Text:DamageIndicator_BackgroundHP;
new Text:DamageIndicator_BackgroundAR;
new Text:DamageIndicator_Health;
new Text:DamageIndicator_Armor;

new bool:DI_IsShowing[MAX_PLAYERS];
new DI_HideTimer[MAX_PLAYERS];
new DI_CurrentTarget[MAX_PLAYERS];

hook OnGameModeInit()
{
    DamageIndicator_Background = TextDrawCreate(370.000, 248.000, "LD_SPAC:black");
    TextDrawTextSize(DamageIndicator_Background, 67.000, 29.000);
    TextDrawAlignment(DamageIndicator_Background, 1);
    TextDrawColor(DamageIndicator_Background, -1);
    TextDrawSetShadow(DamageIndicator_Background, 0);
    TextDrawSetOutline(DamageIndicator_Background, 0);
    TextDrawBackgroundColor(DamageIndicator_Background, 255);
    TextDrawFont(DamageIndicator_Background, 4);
    TextDrawSetProportional(DamageIndicator_Background, 1);

    DamageIndicator_NamePlayer = TextDrawCreate(403.000, 242.000, "AufaaaQ Ganteng");
    TextDrawLetterSize(DamageIndicator_NamePlayer, 0.179, 1.199);
    TextDrawAlignment(DamageIndicator_NamePlayer, 2);
    TextDrawColor(DamageIndicator_NamePlayer, -1);
    TextDrawSetShadow(DamageIndicator_NamePlayer, 1);
    TextDrawSetOutline(DamageIndicator_NamePlayer, 1);
    TextDrawBackgroundColor(DamageIndicator_NamePlayer, 150);
    TextDrawFont(DamageIndicator_NamePlayer, 1);
    TextDrawSetProportional(DamageIndicator_NamePlayer, 1);

    DamageIndicator_BackgroundHP = TextDrawCreate(373.000, 256.000, "LD_DUAL:white");
    TextDrawTextSize(DamageIndicator_BackgroundHP, 61.000, 7.000);
    TextDrawAlignment(DamageIndicator_BackgroundHP, 1);
    TextDrawColor(DamageIndicator_BackgroundHP, -2147483393);
    TextDrawSetShadow(DamageIndicator_BackgroundHP, 0);
    TextDrawSetOutline(DamageIndicator_BackgroundHP, 0);
    TextDrawBackgroundColor(DamageIndicator_BackgroundHP, 255);
    TextDrawFont(DamageIndicator_BackgroundHP, 4);
    TextDrawSetProportional(DamageIndicator_BackgroundHP, 1);

    DamageIndicator_BackgroundAR = TextDrawCreate(373.000, 266.000, "LD_DUAL:white");
    TextDrawTextSize(DamageIndicator_BackgroundAR, 61.000, 7.000);
    TextDrawAlignment(DamageIndicator_BackgroundAR, 1);
    TextDrawColor(DamageIndicator_BackgroundAR, 1768516095);
    TextDrawSetShadow(DamageIndicator_BackgroundAR, 0);
    TextDrawSetOutline(DamageIndicator_BackgroundAR, 0);
    TextDrawBackgroundColor(DamageIndicator_BackgroundAR, 255);
    TextDrawFont(DamageIndicator_BackgroundAR, 4);
    TextDrawSetProportional(DamageIndicator_BackgroundAR, 1);

    DamageIndicator_Health = TextDrawCreate(373.000, 256.000, "LD_DUAL:white");
    TextDrawTextSize(DamageIndicator_Health, 61.000, 7.000);
    TextDrawAlignment(DamageIndicator_Health, 1);
    TextDrawColor(DamageIndicator_Health, -16776961);
    TextDrawSetShadow(DamageIndicator_Health, 0);
    TextDrawSetOutline(DamageIndicator_Health, 0);
    TextDrawBackgroundColor(DamageIndicator_Health, 255);
    TextDrawFont(DamageIndicator_Health, 4);
    TextDrawSetProportional(DamageIndicator_Health, 1);

    DamageIndicator_Armor = TextDrawCreate(373.000, 266.000, "LD_DUAL:white");
    TextDrawTextSize(DamageIndicator_Armor, 61.000, 7.000);
    TextDrawAlignment(DamageIndicator_Armor, 1);
    TextDrawColor(DamageIndicator_Armor, -1);
    TextDrawSetShadow(DamageIndicator_Armor, 0);
    TextDrawSetOutline(DamageIndicator_Armor, 0);
    TextDrawBackgroundColor(DamageIndicator_Armor, 255);
    TextDrawFont(DamageIndicator_Armor, 4);
    TextDrawSetProportional(DamageIndicator_Armor, 1);

    return 1;
}

hook OnPlayerConnect(playerid)
{
    DI_IsShowing[playerid]     = false;
    DI_HideTimer[playerid]     = -1;
    DI_CurrentTarget[playerid] = INVALID_PLAYER_ID;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    DI_Hide(playerid);
    return 1;
}

hook OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid, bodypart)
{
    if(issuerid == INVALID_PLAYER_ID || !IsPlayerConnected(issuerid))
        return 1;

    SetTimerEx("DI_UpdateIndicator", 100, false, "ii", issuerid, playerid);
    return 1;
}

forward DI_UpdateIndicator(attackerid, targetid);
public DI_UpdateIndicator(attackerid, targetid)
{
    if(!IsPlayerConnected(attackerid) || !IsPlayerConnected(targetid)) return 0;

    new Float:hp, Float:ar;
    GetPlayerHealth(targetid, hp);
    GetPlayerArmour(targetid, ar);

    if(hp < 0.0)   hp = 0.0;
    if(hp > 100.0) hp = 100.0;
    if(ar < 0.0)   ar = 0.0;
    if(ar > 100.0) ar = 100.0;

    DI_Show(attackerid, targetid, hp, ar);
    return 1;
}

stock DI_Show(attackerid, targetid, Float:hp, Float:ar)
{
    if(!IsPlayerConnected(attackerid)) return;

    new name[MAX_PLAYER_NAME + 1];
    GetPlayerName(targetid, name, sizeof(name));
    for(new i = 0; name[i] != EOS; i++)
        if(name[i] == '_') name[i] = ' ';

    TextDrawSetString(DamageIndicator_NamePlayer, name);

    new Float:hpWidth = (hp / 100.0) * DI_BAR_MAX_WIDTH;
    if(hpWidth < 1.0) hpWidth = 1.0;

    new Float:arWidth = (ar / 100.0) * DI_BAR_MAX_WIDTH;
    if(arWidth < 0.5) arWidth = 0.5;

    TextDrawTextSize(DamageIndicator_Health, hpWidth, 7.000);
    TextDrawTextSize(DamageIndicator_Armor,  arWidth, 7.000);

    if(!DI_IsShowing[attackerid])
    {
        TextDrawShowForPlayer(attackerid, DamageIndicator_Background);
        TextDrawShowForPlayer(attackerid, DamageIndicator_NamePlayer);
        TextDrawShowForPlayer(attackerid, DamageIndicator_BackgroundHP);
        TextDrawShowForPlayer(attackerid, DamageIndicator_BackgroundAR);
        DI_IsShowing[attackerid] = true;
    }

    TextDrawShowForPlayer(attackerid, DamageIndicator_Health);
    TextDrawShowForPlayer(attackerid, DamageIndicator_Armor);

    DI_CurrentTarget[attackerid] = targetid;

    if(DI_HideTimer[attackerid] != -1)
    {
        KillTimer(DI_HideTimer[attackerid]);
        DI_HideTimer[attackerid] = -1;
    }
    DI_HideTimer[attackerid] = SetTimerEx("DI_AutoHide", DI_HIDE_DELAY, false, "i", attackerid);
}

stock DI_Hide(playerid)
{
    if(!DI_IsShowing[playerid]) return;

    TextDrawHideForPlayer(playerid, DamageIndicator_Background);
    TextDrawHideForPlayer(playerid, DamageIndicator_NamePlayer);
    TextDrawHideForPlayer(playerid, DamageIndicator_BackgroundHP);
    TextDrawHideForPlayer(playerid, DamageIndicator_BackgroundAR);
    TextDrawHideForPlayer(playerid, DamageIndicator_Health);
    TextDrawHideForPlayer(playerid, DamageIndicator_Armor);

    DI_IsShowing[playerid]     = false;
    DI_CurrentTarget[playerid] = INVALID_PLAYER_ID;

    if(DI_HideTimer[playerid] != -1)
    {
        KillTimer(DI_HideTimer[playerid]);
        DI_HideTimer[playerid] = -1;
    }
}

forward DI_AutoHide(playerid);
public DI_AutoHide(playerid)
{
    DI_HideTimer[playerid] = -1;
    if(!IsPlayerConnected(playerid)) return 0;
    DI_Hide(playerid);
    return 1;
}
