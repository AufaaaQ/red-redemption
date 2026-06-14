/*  Tackle System - SAPD Feature
    Allows police officers to tackle suspects on foot.
    Usage: /tackle - activates tackle mode for 10 seconds.
    Press LMB (KEY_FIRE) near a player to tackle them down.
*/
#include <YSI\y_hooks>

#define TACKLE_TIME         10
#define TACKLE_DISTANCE     3.0
#define TACKLE_COOLDOWN     15
#define TACKLE_FALL_TIME    5000

static
    bool:TackleActive[MAX_PLAYERS],
    TackleTarget[MAX_PLAYERS],
    Timer:TackleTimer[MAX_PLAYERS],
    TackleCooldown[MAX_PLAYERS];

hook OnPlayerConnect(playerid)
{
    TackleActive[playerid] = false;
    TackleTarget[playerid] = INVALID_PLAYER_ID;
    TackleCooldown[playerid] = 0;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(TackleActive[playerid])
    {
        TackleActive[playerid] = false;
        stop TackleTimer[playerid];
    }
    return 1;
}

static GetClosestPlayerInFront(playerid, Float:radius)
{
    new
        Float:px, Float:py, Float:pz,
        Float:tx, Float:ty, Float:tz,
        Float:dist,
        closestid = INVALID_PLAYER_ID,
        Float:closestDist = 999.0;

    GetPlayerPos(playerid, px, py, pz);

    foreach(new i : Player)
    {
        if(i == playerid) continue;
        if(GetPlayerVirtualWorld(i) != GetPlayerVirtualWorld(playerid)) continue;
        if(GetPlayerInterior(i) != GetPlayerInterior(playerid)) continue;
        if(PlayerData[i][pInjured]) continue;
        if(!IsPlayerSpawned(i)) continue;

        GetPlayerPos(i, tx, ty, tz);
        dist = floatsqroot((px - tx) * (px - tx) + (py - ty) * (py - ty) + (pz - tz) * (pz - tz));

        if(dist < radius && dist < closestDist)
        {
            closestDist = dist;
            closestid = i;
        }
    }
    return closestid;
}

CMD:tackle(playerid, params[])
{
    if(GetFactionType(playerid) != FACTION_POLICE && GetFactionType(playerid) != FACTION_SHERIFF)
        return SendErrorMessage(playerid, "You must be a Police officer or Sheriff.");

    if(!PlayerData[playerid][pOnDuty])
        return SendErrorMessage(playerid, "You must be on duty first.");

    if(IsPlayerInAnyVehicle(playerid))
        return SendErrorMessage(playerid, "You can't tackle while in a vehicle.");

    if(PlayerData[playerid][pInjured])
        return SendErrorMessage(playerid, "You can't tackle while injured.");

    if(TackleActive[playerid])
        return SendErrorMessage(playerid, "You are already in tackle mode.");

    if(gettime() < TackleCooldown[playerid])
    {
        new remaining = TackleCooldown[playerid] - gettime();
        return SendErrorMessage(playerid, "You must wait %d seconds before using tackle again.", remaining);
    }

    TackleActive[playerid] = true;
    TackleTimer[playerid] = defer TackleExpire(playerid);

    SendCustomMessage(playerid, "TACKLE", "Tackle mode "YELLOW"ACTIVATED"WHITE"! You have "RED"10 seconds"WHITE" to tackle a suspect.");
    SendCustomMessage(playerid, "TACKLE", "Get close to the suspect and press "YELLOW"LMB"WHITE" to tackle them down.");

    return 1;
}

timer TackleExpire[TACKLE_TIME * 1000](playerid)
{
    if(!TackleActive[playerid])
        return;

    TackleActive[playerid] = false;
    SendCustomMessage(playerid, "TACKLE", "Tackle mode has "RED"expired"WHITE". You ran out of time.");
}

timer TackleAnimOfficer[0](playerid)
{
    if(!IsPlayerConnected(playerid))
        return;

    ClearAnimations(playerid);
    ApplyAnimation(playerid, "PED", "EV_dive", 4.1, 0, 1, 1, 1, 0, 1);
}

timer TackleAnimSuspect[0](targetid)
{
    if(!IsPlayerConnected(targetid))
        return;

    ClearAnimations(targetid);
    ApplyAnimation(targetid, "PED", "KO_skid_front", 4.1, 0, 1, 1, 1, 0, 1);
}

timer TackleVictimRecover[TACKLE_FALL_TIME](targetid, playerid)
{
    if(IsPlayerConnected(targetid))
    {
        ClearAnimations(targetid);
        TogglePlayerControllable(targetid, true);
        SendCustomMessage(targetid, "TACKLE", "You have recovered from the tackle.");
    }

    if(IsPlayerConnected(playerid))
    {
        ClearAnimations(playerid);
        TogglePlayerControllable(playerid, true);
    }
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(!TackleActive[playerid])
        return 1;

    if(!PRESSED(KEY_FIRE))
        return 1;

    if(IsPlayerInAnyVehicle(playerid))
        return 1;

    new targetid = GetClosestPlayerInFront(playerid, TACKLE_DISTANCE);

    if(targetid == INVALID_PLAYER_ID)
        return 1;

    if(IsPlayerInAnyVehicle(targetid))
    {
        SendErrorMessage(playerid, "You can't tackle a player inside a vehicle.");
        return 1;
    }

    TackleActive[playerid] = false;
    stop TackleTimer[playerid];
    TackleCooldown[playerid] = gettime() + TACKLE_COOLDOWN;

    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(targetid, tx, ty, tz);
    SetPlayerPos(playerid, tx, ty, tz);

    new Float:angle;
    GetPlayerFacingAngle(targetid, angle);
    SetPlayerFacingAngle(playerid, angle);

    defer TackleAnimOfficer(playerid);
    defer TackleAnimSuspect(targetid);
    defer TackleVictimRecover(targetid, playerid);

    SendNearbyMessage(playerid, 15.0, X11_PLUM, "* %s tackles %s to the ground.", ReturnName(playerid, 0, 1), ReturnName(targetid, 0, 1));

    SendCustomMessage(playerid, "TACKLE", "You have successfully tackled "YELLOW"%s"WHITE".", ReturnName(targetid, 0));
    SendCustomMessage(targetid, "TACKLE", "You have been tackled by "YELLOW"%s"WHITE"! You are unable to move for a few seconds.", ReturnName(playerid, 0));

    return 1;
}