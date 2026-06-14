forward AttachFarmTrailer(tractorid, trailerid);
forward TractorFarmProcess(playerid);

#include <YSI\y_hooks>

#define TRACTOR_FARM_MODE_NONE (0)
#define TRACTOR_FARM_MODE_HARVEST (2)

new TractorFarmMode[MAX_PLAYERS];
new TractorFarmTimer[MAX_PLAYERS];

static stock bool:TractorFarm_IsDrivingTractor(playerid)
{
    return IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER && GetVehicleModel(GetPlayerVehicleID(playerid)) == 531;
}

static stock bool:TractorFarm_IsOwnedTractor(playerid)
{
    if(!TractorFarm_IsDrivingTractor(playerid))
        return false;

    new carid = Vehicle_GetID(GetPlayerVehicleID(playerid));

    if(carid == -1)
        return false;

    return (Vehicle_IsOwner(playerid, carid) != 0);
}

static stock bool:TractorFarm_IsInFarmArea(playerid)
{
    foreach(new farmid : Farms) if ((Farm_IsOwner(playerid, farmid) || Farm_IsEmployee(playerid, farmid)) && pvFarmZone[farmid] != 0 && IsPlayerInDynamicArea(playerid, pvFarmZone[farmid]))
        return true;

    if (IsPlayerInDynamicArea(playerid, publicfarm[0]) || IsPlayerInDynamicArea(playerid, publicfarm[1]))
        return true;

    return false;
}

static stock TractorFarm_GetWorkPoint(playerid, &Float:x, &Float:y, &Float:z, &Float:angle)
{
    new vehicleid = GetPlayerVehicleID(playerid);

    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, angle);
    return 1;
}

static stock TractorFarm_GetFarmAtPoint(playerid)
{
    foreach(new farmid : Farms) if ((Farm_IsOwner(playerid, farmid) || Farm_IsEmployee(playerid, farmid)) && pvFarmZone[farmid] != 0 && IsPlayerInDynamicArea(playerid, pvFarmZone[farmid]))
        return farmid;

    return -1;
}

static stock bool:TractorFarm_IsPublicFarmPoint(playerid)
{
    return (IsPlayerInDynamicArea(playerid, publicfarm[0]) || IsPlayerInDynamicArea(playerid, publicfarm[1]));
}

static stock bool:TractorFarm_HasTrailer(playerid)
{
    if(!TractorFarm_IsDrivingTractor(playerid))
        return false;

    new trailerid = GetVehicleTrailer(GetPlayerVehicleID(playerid));

    return (trailerid != 0 && GetVehicleModel(trailerid) == 610);
}

static stock TractorFarm_StopMode(playerid, bool:sendmessage = true)
{
    if(TractorFarmTimer[playerid])
    {
        KillTimer(TractorFarmTimer[playerid]);
        TractorFarmTimer[playerid] = 0;
    }

    TractorFarmMode[playerid] = TRACTOR_FARM_MODE_NONE;

    if(sendmessage)
        SendCustomMessage(playerid, "TRACTOR", "Tractor auto farming has been stopped.");

    return 1;
}

static stock TractorFarm_StartMode(playerid, mode)
{
    if(!TractorFarm_HasTrailer(playerid))
        return SendErrorMessage(playerid, "Kamu harus memasang farm trailer terlebih dahulu.");

    TractorFarm_StopMode(playerid, false);

    TractorFarmMode[playerid] = mode;
    TractorFarmTimer[playerid] = SetTimerEx("TractorFarmProcess", 1500, true, "d", playerid);

    if(mode == TRACTOR_FARM_MODE_HARVEST)
        SendCustomMessage(playerid, "TRACTOR", "Auto harvesting started. Use /stopharvest to stop.");

    return 1;
}

static stock TractorFarm_ShowMenu(playerid)
{
    if(!TractorFarm_IsOwnedTractor(playerid))
        return SendErrorMessage(playerid, "Kamu harus mengendarai tractor milikmu sendiri.");

    Dialog_Show(playerid, TractorDriverMenu, DIALOG_STYLE_LIST, "Tractor Menu", "Spawn Farm Trailer\nHarvesting a Plant\nStop Harvesting", "Select", "Close");
    return 1;
}

CMD:tractormenu(playerid, params[])
{
    return TractorFarm_ShowMenu(playerid);
}

CMD:farmtrailer(playerid, params[])
{
    if(!IsPlayerInAnyVehicle(playerid))
        return SendErrorMessage(playerid, "Kamu harus berada di dalam tractor.");

    if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        return SendErrorMessage(playerid, "Kamu harus berada di kursi pengemudi.");

    new vehicleid = GetPlayerVehicleID(playerid);

    if(GetVehicleModel(vehicleid) != 531)
        return SendErrorMessage(playerid, "Perintah ini hanya bisa digunakan saat mengendarai tractor.");

    if(GetVehicleTrailer(vehicleid))
        return SendErrorMessage(playerid, "Tractor kamu sudah menarik trailer.");

    new Float:x, Float:y, Float:z, Float:angle;
    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, angle);

    x -= 6.0 * floatsin(-angle, degrees);
    y -= 6.0 * floatcos(-angle, degrees);

    new trailerid = CreateVehicle(610, x, y, z, angle, -1, -1, -1);
    SetVehicleVirtualWorld(trailerid, GetVehicleVirtualWorld(vehicleid));
    LinkVehicleToInterior(trailerid, GetVehicleInterior(vehicleid));
    SetTimerEx("AttachFarmTrailer", 350, false, "ii", vehicleid, trailerid);

    SendCustomMessage(playerid, "TRAILER", "Farm trailer has been spawned, attaching to your tractor.");
    return 1;
}

public AttachFarmTrailer(tractorid, trailerid)
{
    if(!IsValidVehicle(tractorid) || !IsValidVehicle(trailerid))
        return 0;

    if(GetVehicleModel(tractorid) != 531 || GetVehicleModel(trailerid) != 610)
        return 0;

    AttachTrailerToVehicle(trailerid, tractorid);
    return 1;
}

public TractorFarmProcess(playerid)
{
    if(!IsPlayerConnected(playerid))
        return 0;

    if(!TractorFarm_IsDrivingTractor(playerid))
        return TractorFarm_StopMode(playerid, false);

    if(TractorFarmMode[playerid] != TRACTOR_FARM_MODE_NONE && !TractorFarm_HasTrailer(playerid))
        return TractorFarm_StopMode(playerid, false);

    switch(TractorFarmMode[playerid])
    {
        case TRACTOR_FARM_MODE_HARVEST:
        {
            if(!TractorFarm_IsInFarmArea(playerid))
                return 1;

            if(PlayerData[playerid][pHarvesting])
                return 1;

            new Float:x, Float:y, Float:z, Float:angle;
            TractorFarm_GetWorkPoint(playerid, x, y, z, angle);

            new plantid = Plant_NearestPoint(x, y, z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid), 5.0);

            if(plantid == -1)
                return 1;

            if(!Plant_CanHarvest(playerid, plantid))
                return 1;

            Plant_Harvest(playerid, plantid, true);
        }
    }
    return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(oldstate == PLAYER_STATE_DRIVER && newstate != PLAYER_STATE_DRIVER && TractorFarmMode[playerid] != TRACTOR_FARM_MODE_NONE)
        TractorFarm_StopMode(playerid, false);

    return 1;
}

hook OnPlayerDisconnectEx(playerid)
{
    TractorFarm_StopMode(playerid, false);
    return 1;
}

CMD:stopharvest(playerid, params[])
{
    if(TractorFarmMode[playerid] != TRACTOR_FARM_MODE_HARVEST)
        return SendErrorMessage(playerid, "Kamu tidak sedang auto harvest.");

    TractorFarm_StopMode(playerid, false);
    SendCustomMessage(playerid, "TRACTOR", "Auto harvesting has been stopped.");
    return 1;
}

Dialog:TractorDriverMenu(playerid, response, listitem, inputtext[])
{
    if(!response)
        return 1;

    if(!TractorFarm_IsOwnedTractor(playerid))
        return SendErrorMessage(playerid, "Kamu harus mengendarai tractor milikmu sendiri.");

    switch(listitem)
    {
        case 0: cmd_farmtrailer(playerid, "\1");
        case 1: TractorFarm_StartMode(playerid, TRACTOR_FARM_MODE_HARVEST);
        case 2: cmd_stopharvest(playerid, "\1");
    }
    return 1;
}
