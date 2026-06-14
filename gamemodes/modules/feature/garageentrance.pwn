#include <YSI\y_hooks>

// ============================================================
//  GARAGE ENTRANCE SYSTEM
// ============================================================

#define MAX_GARAGE_ENTRANCES        (250)
#define GE_INTERIOR_X               (-1118.8625)
#define GE_INTERIOR_Y               (-970.3419)
#define GE_INTERIOR_Z               (120.7953)
#define GE_INTERIOR_A               (269.8350)

enum E_GARAGE_ENTRANCE
{
    geID,
    geExists,
    geName[128],
    geOwner,            
    geLocked,
    Float:gePos[4],     // Posisi exterior (x, y, z, angle)
    Float:geIntPos[4],  // Posisi interior (x, y, z, angle) — default fixed
    geExterior,         // Interior value exterior
    geExteriorVW,       // Virtual world exterior
    geVW,               
    Text3D:geLabel,
    Text3D:geLabelInt,
    gePickup,
    gePickupInt
};

new gGarageEntrance[MAX_GARAGE_ENTRANCES][E_GARAGE_ENTRANCE];
new Iterator:gGarageEnts<MAX_GARAGE_ENTRANCES>;
new gPlayerGarageEntrance[MAX_PLAYERS] = { -1, ... };
new gPlayerGarageEntranceTick[MAX_PLAYERS];

// ============================================================
//  UTILITY
// ============================================================

stock bool:GarageEntrance_IsValid(id)
    return (id >= 0 && id < MAX_GARAGE_ENTRANCES && Iter_Contains(gGarageEnts, id));

stock bool:GarageEntrance_IsOwner(playerid, id)
{
    if(!GarageEntrance_IsValid(id)) return false;
    if(PlayerData[playerid][pAdmin] >= 7) return true;
    if(!gGarageEntrance[id][geOwner]) return false;
    return (gGarageEntrance[id][geOwner] == GetPlayerSQLID(playerid));
}

stock bool:GarageEntrance_HasRecentUse(playerid, cooldown = 3)
    return ((gettime() - gPlayerGarageEntranceTick[playerid]) < cooldown);

stock GarageEntrance_SetRecentUse(playerid)
{
    gPlayerGarageEntranceTick[playerid] = gettime();
    return 1;
}

stock GarageEntrance_GenerateVW()
{
    new vw;
    new bool:taken;

    do
    {
        vw = 20000 + random(900000);
        taken = false;

        foreach (new i : gGarageEnts)
        {
            if(gGarageEntrance[i][geVW] == vw)
            {
                taken = true;
                break;
            }
        }
    }
    while(taken);

    return vw;
}

stock GarageEntrance_NearestExterior(playerid)
{
    foreach (new i : gGarageEnts)
    {
        if(!gGarageEntrance[i][geExists])
            continue;

        if(GetPlayerVirtualWorld(playerid) == gGarageEntrance[i][geExteriorVW] && GetPlayerInterior(playerid) == gGarageEntrance[i][geExterior])
        {
            if(IsPlayerInRangeOfPoint(playerid, 3.5, gGarageEntrance[i][gePos][0], gGarageEntrance[i][gePos][1], gGarageEntrance[i][gePos][2]))
                return i;
        }
    }
    return -1;
}

stock GarageEntrance_Inside(playerid)
{
    new id = gPlayerGarageEntrance[playerid];

    if(id == -1 || !GarageEntrance_IsValid(id))
        return -1;

    if(GetPlayerVirtualWorld(playerid) != gGarageEntrance[id][geVW] || GetPlayerInterior(playerid) != 0)
        return -1;

    if(IsPlayerInRangeOfPoint(playerid, 3.5, gGarageEntrance[id][geIntPos][0], gGarageEntrance[id][geIntPos][1], gGarageEntrance[id][geIntPos][2]))
        return id;

    return -1;
}

stock GarageEntrance_Refresh(id)
{
    new label[196];

    if(!GarageEntrance_IsValid(id))
        return 0;

    // Hapus yang lama
    if(IsValidDynamic3DTextLabel(gGarageEntrance[id][geLabel]))
        DestroyDynamic3DTextLabel(gGarageEntrance[id][geLabel]);
    if(IsValidDynamic3DTextLabel(gGarageEntrance[id][geLabelInt]))
        DestroyDynamic3DTextLabel(gGarageEntrance[id][geLabelInt]);
    if(IsValidDynamicPickup(gGarageEntrance[id][gePickup]))
        DestroyDynamicPickup(gGarageEntrance[id][gePickup]);
    if(IsValidDynamicPickup(gGarageEntrance[id][gePickupInt]))
        DestroyDynamicPickup(gGarageEntrance[id][gePickupInt]);

    // ---- EXTERIOR ----
    format(label, sizeof(label), "[GE:%d]\n"YELLOW"%s\n"WHITE"Press '"RED"H"WHITE"' (vehicle) or '"RED"F"WHITE"' (on foot)", id, gGarageEntrance[id][geName]);

    gGarageEntrance[id][geLabel] = CreateDynamic3DTextLabel(
        label, COLOR_CLIENT,
        gGarageEntrance[id][gePos][0],
        gGarageEntrance[id][gePos][1],
        gGarageEntrance[id][gePos][2] + 0.7,
        15.0,
        INVALID_PLAYER_ID, INVALID_VEHICLE_ID,
        1, gGarageEntrance[id][geExteriorVW], gGarageEntrance[id][geExterior]
    );

    gGarageEntrance[id][gePickup] = CreateDynamicPickup(
        1239, 23,
        gGarageEntrance[id][gePos][0],
        gGarageEntrance[id][gePos][1],
        gGarageEntrance[id][gePos][2],
        gGarageEntrance[id][geExteriorVW],
        gGarageEntrance[id][geExterior],
        -1, 15.0
    );

    // ---- INTERIOR ----
    format(label, sizeof(label), "[GE:%d]\n"YELLOW"%s\n"WHITE"Press '"RED"H"WHITE"' (vehicle) or '"RED"F"WHITE"' (on foot) to exit", id, gGarageEntrance[id][geName]);

    gGarageEntrance[id][geLabelInt] = CreateDynamic3DTextLabel(
        label, COLOR_CLIENT,
        gGarageEntrance[id][geIntPos][0],
        gGarageEntrance[id][geIntPos][1],
        gGarageEntrance[id][geIntPos][2] + 0.7,
        15.0,
        INVALID_PLAYER_ID, INVALID_VEHICLE_ID,
        1, gGarageEntrance[id][geVW], 0
    );

    gGarageEntrance[id][gePickupInt] = CreateDynamicPickup(
        1239, 23,
        gGarageEntrance[id][geIntPos][0],
        gGarageEntrance[id][geIntPos][1],
        gGarageEntrance[id][geIntPos][2],
        gGarageEntrance[id][geVW],
        0, -1, 15.0
    );

    return 1;
}

stock GarageEntrance_Enter(playerid, id)
{
    new vehicleid = GetPlayerVehicleID(playerid);

    if(!GarageEntrance_IsValid(id)) return 0;
    if(!IsPlayerInAnyVehicle(playerid) || GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return 0;
    if(!GarageEntrance_IsOwner(playerid, id)) return SendErrorMessage(playerid, "Anda bukan owner garage entrance ini.");

    SetVehiclePos(vehicleid, gGarageEntrance[id][geIntPos][0], gGarageEntrance[id][geIntPos][1], gGarageEntrance[id][geIntPos][2]);
    SetVehicleZAngle(vehicleid, gGarageEntrance[id][geIntPos][3]);
    LinkVehicleToInterior(vehicleid, 0);
    SetVehicleVirtualWorld(vehicleid, gGarageEntrance[id][geVW]);

    foreach (new pid : Player)
    {
        if(!SQL_IsCharacterLogged(pid) || !IsPlayerInVehicle(pid, vehicleid))
            continue;

        gPlayerGarageEntrance[pid] = id;
        SetPlayerInterior(pid, 0);
        SetPlayerVirtualWorld(pid, gGarageEntrance[id][geVW]);
        SetCameraBehindPlayer(pid);

        if(GetPlayerState(pid) != PLAYER_STATE_DRIVER)
            SetPlayerFacingAngle(pid, gGarageEntrance[id][geIntPos][3]);
    }
    return 1;
}

stock GarageEntrance_EnterOnFoot(playerid, id)
{
    if(!GarageEntrance_IsValid(id)) return 0;
    if(IsPlayerInAnyVehicle(playerid)) return 0;
    if(!GarageEntrance_IsOwner(playerid, id)) return SendErrorMessage(playerid, "Anda bukan owner garage entrance ini.");

    gPlayerGarageEntrance[playerid] = id;
    SetPlayerPosEx(playerid, gGarageEntrance[id][geIntPos][0], gGarageEntrance[id][geIntPos][1], gGarageEntrance[id][geIntPos][2], 1500);
    SetPlayerFacingAngle(playerid, gGarageEntrance[id][geIntPos][3]);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, gGarageEntrance[id][geVW]);
    SetCameraBehindPlayer(playerid);
    return 1;
}

stock GarageEntrance_Exit(playerid, id)
{
    new vehicleid = GetPlayerVehicleID(playerid);

    if(!GarageEntrance_IsValid(id)) return 0;
    if(!IsPlayerInAnyVehicle(playerid) || GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return 0;

    SetVehiclePos(vehicleid, gGarageEntrance[id][gePos][0], gGarageEntrance[id][gePos][1], gGarageEntrance[id][gePos][2]);
    SetVehicleZAngle(vehicleid, gGarageEntrance[id][gePos][3]);
    LinkVehicleToInterior(vehicleid, gGarageEntrance[id][geExterior]);
    SetVehicleVirtualWorld(vehicleid, gGarageEntrance[id][geExteriorVW]);

    foreach (new pid : Player)
    {
        if(!SQL_IsCharacterLogged(pid) || !IsPlayerInVehicle(pid, vehicleid))
            continue;

        gPlayerGarageEntrance[pid] = -1;
        SetPlayerInterior(pid, gGarageEntrance[id][geExterior]);
        SetPlayerVirtualWorld(pid, gGarageEntrance[id][geExteriorVW]);
        SetCameraBehindPlayer(pid);

        if(GetPlayerState(pid) != PLAYER_STATE_DRIVER)
            SetPlayerFacingAngle(pid, gGarageEntrance[id][gePos][3]);
    }
    return 1;
}

stock GarageEntrance_ExitOnFoot(playerid, id)
{
    if(!GarageEntrance_IsValid(id)) return 0;
    if(IsPlayerInAnyVehicle(playerid)) return 0;

    gPlayerGarageEntrance[playerid] = -1;
    SetPlayerPos(playerid, gGarageEntrance[id][gePos][0], gGarageEntrance[id][gePos][1], gGarageEntrance[id][gePos][2]);
    SetPlayerFacingAngle(playerid, gGarageEntrance[id][gePos][3] - 180.0);
    SetPlayerInterior(playerid, gGarageEntrance[id][geExterior]);
    SetPlayerVirtualWorld(playerid, gGarageEntrance[id][geExteriorVW]);
    SetCameraBehindPlayer(playerid);
    return 1;
}

// ============================================================
//  DATABASE
// ============================================================

stock GarageEntrance_Save(id)
{
    new query[1024];
    if(!GarageEntrance_IsValid(id)) return 0;

    mysql_format(g_iHandle, query, sizeof(query),
        "UPDATE `genterances` SET \
        `genteranceName`='%e', `genteranceOwner`='%d', `genteranceLocked`='%d', \
        `genteranceExteriorX`='%.4f', `genteranceExteriorY`='%.4f', `genteranceExteriorZ`='%.4f', `genteranceExteriorA`='%.4f', \
        `genteranceInteriorX`='%.4f', `genteranceInteriorY`='%.4f', `genteranceInteriorZ`='%.4f', `genteranceInteriorA`='%.4f', \
        `genteranceExterior`='%d', `genteranceExteriorVW`='%d', `genteranceVW`='%d' \
        WHERE `genteranceID`='%d'",
        gGarageEntrance[id][geName],
        gGarageEntrance[id][geOwner],
        gGarageEntrance[id][geLocked],
        gGarageEntrance[id][gePos][0], gGarageEntrance[id][gePos][1], gGarageEntrance[id][gePos][2], gGarageEntrance[id][gePos][3],
        gGarageEntrance[id][geIntPos][0], gGarageEntrance[id][geIntPos][1], gGarageEntrance[id][geIntPos][2], gGarageEntrance[id][geIntPos][3],
        gGarageEntrance[id][geExterior],
        gGarageEntrance[id][geExteriorVW],
        gGarageEntrance[id][geVW],
        gGarageEntrance[id][geID]
    );
    return mysql_tquery(g_iHandle, query);
}

stock GarageEntrance_Delete(id)
{
    new query[128];
    if(!GarageEntrance_IsValid(id)) return 0;

    mysql_format(g_iHandle, query, sizeof(query), "DELETE FROM `genterances` WHERE `genteranceID`='%d'", gGarageEntrance[id][geID]);
    mysql_tquery(g_iHandle, query);

    if(IsValidDynamic3DTextLabel(gGarageEntrance[id][geLabel]))   DestroyDynamic3DTextLabel(gGarageEntrance[id][geLabel]);
    if(IsValidDynamic3DTextLabel(gGarageEntrance[id][geLabelInt])) DestroyDynamic3DTextLabel(gGarageEntrance[id][geLabelInt]);
    if(IsValidDynamicPickup(gGarageEntrance[id][gePickup]))        DestroyDynamicPickup(gGarageEntrance[id][gePickup]);
    if(IsValidDynamicPickup(gGarageEntrance[id][gePickupInt]))     DestroyDynamicPickup(gGarageEntrance[id][gePickupInt]);

    foreach (new i : Player)
        if(gPlayerGarageEntrance[i] == id)
            gPlayerGarageEntrance[i] = -1;

    Iter_Remove(gGarageEnts, id);
    gGarageEntrance[id][geExists]        = 0;
    gGarageEntrance[id][geOwner]         = 0;
    gGarageEntrance[id][geLocked]        = 0;
    gGarageEntrance[id][geLabel]         = Text3D:INVALID_STREAMER_ID;
    gGarageEntrance[id][geLabelInt]      = Text3D:INVALID_STREAMER_ID;
    gGarageEntrance[id][gePickup]        = INVALID_STREAMER_ID;
    gGarageEntrance[id][gePickupInt]     = INVALID_STREAMER_ID;
    return 1;
}

stock GarageEntrance_Create(playerid, name[])
{
    new id = Iter_Free(gGarageEnts);
    new query[256];

    if(id == cellmin) return -1;

    Iter_Add(gGarageEnts, id);

    gGarageEntrance[id][geExists]  = 1;
    format(gGarageEntrance[id][geName], 128, name);
    gGarageEntrance[id][geOwner]   = 0;
    gGarageEntrance[id][geLocked]  = 0;

    GetPlayerPos(playerid,
        gGarageEntrance[id][gePos][0],
        gGarageEntrance[id][gePos][1],
        gGarageEntrance[id][gePos][2]);
    GetPlayerFacingAngle(playerid, gGarageEntrance[id][gePos][3]);

    gGarageEntrance[id][geIntPos][0] = GE_INTERIOR_X;
    gGarageEntrance[id][geIntPos][1] = GE_INTERIOR_Y;
    gGarageEntrance[id][geIntPos][2] = GE_INTERIOR_Z;
    gGarageEntrance[id][geIntPos][3] = GE_INTERIOR_A;

    gGarageEntrance[id][geExterior]   = GetPlayerInterior(playerid);
    gGarageEntrance[id][geExteriorVW] = GetPlayerVirtualWorld(playerid);
    gGarageEntrance[id][geVW]         = GarageEntrance_GenerateVW();

    gGarageEntrance[id][geLabel]         = Text3D:INVALID_STREAMER_ID;
    gGarageEntrance[id][geLabelInt]      = Text3D:INVALID_STREAMER_ID;
    gGarageEntrance[id][gePickup]        = INVALID_STREAMER_ID;
    gGarageEntrance[id][gePickupInt]     = INVALID_STREAMER_ID;

    GarageEntrance_Refresh(id);

    mysql_format(g_iHandle, query, sizeof(query), "INSERT INTO `genterances` (`genteranceName`) VALUES ('%e')", name);
    mysql_tquery(g_iHandle, query, "OnGarageEntranceCreated", "d", id);
    return id;
}

Function:GarageEntrance_Load()
{
    new rows = cache_num_rows();

    for (new i; i < rows && i < MAX_GARAGE_ENTRANCES; i++)
    {
        Iter_Add(gGarageEnts, i);

        gGarageEntrance[i][geExists] = 1;
        cache_get_value_int(i,   "genteranceID",          gGarageEntrance[i][geID]);
        cache_get_value(i,       "genteranceName",        gGarageEntrance[i][geName], 128);
        cache_get_value_int(i,   "genteranceOwner",       gGarageEntrance[i][geOwner]);
        cache_get_value_int(i,   "genteranceLocked",      gGarageEntrance[i][geLocked]);
        cache_get_value_float(i, "genteranceExteriorX",   gGarageEntrance[i][gePos][0]);
        cache_get_value_float(i, "genteranceExteriorY",   gGarageEntrance[i][gePos][1]);
        cache_get_value_float(i, "genteranceExteriorZ",   gGarageEntrance[i][gePos][2]);
        cache_get_value_float(i, "genteranceExteriorA",   gGarageEntrance[i][gePos][3]);
        cache_get_value_float(i, "genteranceInteriorX",   gGarageEntrance[i][geIntPos][0]);
        cache_get_value_float(i, "genteranceInteriorY",   gGarageEntrance[i][geIntPos][1]);
        cache_get_value_float(i, "genteranceInteriorZ",   gGarageEntrance[i][geIntPos][2]);
        cache_get_value_float(i, "genteranceInteriorA",   gGarageEntrance[i][geIntPos][3]);
        cache_get_value_int(i,   "genteranceExterior",    gGarageEntrance[i][geExterior]);
        cache_get_value_int(i,   "genteranceExteriorVW",  gGarageEntrance[i][geExteriorVW]);
        cache_get_value_int(i,   "genteranceVW",          gGarageEntrance[i][geVW]);

        // Jika interior belum di-set (0,0,0), gunakan default
        if(gGarageEntrance[i][geIntPos][0] == 0.0 && gGarageEntrance[i][geIntPos][1] == 0.0 && gGarageEntrance[i][geIntPos][2] == 0.0)
        {
            gGarageEntrance[i][geIntPos][0] = GE_INTERIOR_X;
            gGarageEntrance[i][geIntPos][1] = GE_INTERIOR_Y;
            gGarageEntrance[i][geIntPos][2] = GE_INTERIOR_Z;
            gGarageEntrance[i][geIntPos][3] = GE_INTERIOR_A;
        }

        gGarageEntrance[i][geLabel]         = Text3D:INVALID_STREAMER_ID;
        gGarageEntrance[i][geLabelInt]      = Text3D:INVALID_STREAMER_ID;
        gGarageEntrance[i][gePickup]        = INVALID_STREAMER_ID;
        gGarageEntrance[i][gePickupInt]     = INVALID_STREAMER_ID;

        GarageEntrance_Refresh(i);
    }

    printf("*** [East Side Roleplay Database: Loaded] garage entrance data (%d count).", rows);
    return 1;
}

Function:OnGarageEntranceCreated(id)
{
    if(!GarageEntrance_IsValid(id)) return 0;
    gGarageEntrance[id][geID] = cache_insert_id();
    GarageEntrance_Save(id);
    return 1;
}

// ============================================================
//  HOOKS
// ============================================================

hook OnGameModeInitEx()
{
    mysql_tquery(g_iHandle, "SELECT * FROM `genterances`", "GarageEntrance_Load", "");
    return 1;
}

hook OnPlayerConnect(playerid)
{
    gPlayerGarageEntrance[playerid] = -1;
    gPlayerGarageEntranceTick[playerid] = 0;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    gPlayerGarageEntrance[playerid] = -1;
    gPlayerGarageEntranceTick[playerid] = 0;
    return 1;
}

// ============================================================
//  COMMANDS
// ============================================================

CMD:creategentrance(playerid, params[])
{
    if(CheckAdmin(playerid, 7))
        return PermissionError(playerid);

    if(isnull(params) || strlen(params) > 64)
        return SendSyntaxMessage(playerid, "/creategentrance [name]");

    new id = GarageEntrance_Create(playerid, ColouredText(params));

    if(id == -1)
        return SendErrorMessage(playerid, "Server telah mencapai batas maksimum garage entrance.");

    SendServerMessage(playerid, "Garage entrance '"WHITE"%s"GREEN"' berhasil dibuat. ID: %d | VW: %d", gGarageEntrance[id][geName], id, gGarageEntrance[id][geVW]);
    SendServerMessage(playerid, "Gunakan "WHITE"/editgentrance %d owner [nama]"GREEN" untuk mengatur owner.", id);
    return 1;
}

CMD:editgentrance(playerid, params[])
{
    new
        id,
        type[24],
        extra[128];

    extra[0] = EOS;

    if(CheckAdmin(playerid, 7))
        return PermissionError(playerid);

    if(sscanf(params, "ds[24]S()[128]", id, type, extra))
    {
        SendSyntaxMessage(playerid, "/editgentrance [id] [type]");
        SendClientMessage(playerid, X11_YELLOW_2, "[TYPES]: "WHITE"location, interior, owner, locked, name, destroy");
        return 1;
    }

    if(!GarageEntrance_IsValid(id))
        return SendErrorMessage(playerid, "ID garage entrance tidak valid.");

    if(!strcmp(type, "location", true))
    {
        GetPlayerPos(playerid,
            gGarageEntrance[id][gePos][0],
            gGarageEntrance[id][gePos][1],
            gGarageEntrance[id][gePos][2]);
        GetPlayerFacingAngle(playerid, gGarageEntrance[id][gePos][3]);
        gGarageEntrance[id][geExterior]   = GetPlayerInterior(playerid);
        gGarageEntrance[id][geExteriorVW] = GetPlayerVirtualWorld(playerid);

        GarageEntrance_Refresh(id);
        GarageEntrance_Save(id);
        SendAdminMessage(X11_TOMATO_1, "AdmCmd: %s set lokasi exterior garage entrance ID %d.", ReturnName(playerid, 0), id);
    }
    else if(!strcmp(type, "interior", true))
    {
        GetPlayerPos(playerid,
            gGarageEntrance[id][geIntPos][0],
            gGarageEntrance[id][geIntPos][1],
            gGarageEntrance[id][geIntPos][2]);
        GetPlayerFacingAngle(playerid, gGarageEntrance[id][geIntPos][3]);

        foreach (new pid : Player)
        {
            if(gPlayerGarageEntrance[pid] != id) continue;
            if(!IsPlayerInAnyVehicle(pid) || GetPlayerState(pid) != PLAYER_STATE_DRIVER) continue;

            SetVehiclePos(GetPlayerVehicleID(pid),
                gGarageEntrance[id][geIntPos][0],
                gGarageEntrance[id][geIntPos][1],
                gGarageEntrance[id][geIntPos][2]);
            SetVehicleZAngle(GetPlayerVehicleID(pid), gGarageEntrance[id][geIntPos][3]);
            SetPlayerFacingAngle(pid, gGarageEntrance[id][geIntPos][3]);
            SetCameraBehindPlayer(pid);
        }

        GarageEntrance_Refresh(id);
        GarageEntrance_Save(id);
        SendAdminMessage(X11_TOMATO_1, "AdmCmd: %s set lokasi interior garage entrance ID %d.", ReturnName(playerid, 0), id);
    }
    // ---- owner: Set/clear owner ----
    else if(!strcmp(type, "owner", true))
    {
        new userid;

        if(isnull(extra))
            return SendSyntaxMessage(playerid, "/editgentrance [id] owner [playerid/nama] (gunakan 'none' untuk hapus)");

        if(!strcmp(extra, "none", true))
        {
            gGarageEntrance[id][geOwner] = 0;
            GarageEntrance_Save(id);
            SendAdminMessage(X11_TOMATO_1, "AdmCmd: %s menghapus owner garage entrance ID %d.", ReturnName(playerid, 0), id);
            return 1;
        }

        if(sscanf(extra, "u", userid))
            return SendSyntaxMessage(playerid, "/editgentrance [id] owner [playerid/nama] (gunakan 'none' untuk hapus)");

        gGarageEntrance[id][geOwner] = GetPlayerSQLID(userid);
        GarageEntrance_Save(id);
        SendAdminMessage(X11_TOMATO_1, "AdmCmd: %s set owner garage entrance ID %d ke %s.", ReturnName(playerid, 0), id, ReturnName(userid, 0));
    }
    // ---- locked: Kunci/buka garage ----
    else if(!strcmp(type, "locked", true))
    {
        new val;

        if(sscanf(extra, "d", val) || val < 0 || val > 1)
            return SendSyntaxMessage(playerid, "/editgentrance [id] locked [0/1]");

        gGarageEntrance[id][geLocked] = val;
        GarageEntrance_Save(id);
        SendAdminMessage(X11_TOMATO_1, "AdmCmd: %s %s garage entrance ID %d.", ReturnName(playerid, 0), val ? "mengunci" : "membuka", id);
    }
    // ---- name: Ganti nama ----
    else if(!strcmp(type, "name", true))
    {
        new newname[128];

        if(sscanf(extra, "s[128]", newname))
            return SendSyntaxMessage(playerid, "/editgentrance [id] name [nama baru]");

        format(gGarageEntrance[id][geName], 128, ColouredText(newname));
        GarageEntrance_Refresh(id);
        GarageEntrance_Save(id);
        SendAdminMessage(X11_TOMATO_1, "AdmCmd: %s mengganti nama garage entrance ID %d menjadi \"%s\".", ReturnName(playerid, 0), id, ColouredText(newname));
    }
    // ---- destroy: Hapus ----
    else if(!strcmp(type, "destroy", true))
    {
        SendAdminMessage(X11_TOMATO_1, "AdmCmd: %s menghapus garage entrance ID %d (\"%s\").", ReturnName(playerid, 0), id, gGarageEntrance[id][geName]);
        GarageEntrance_Delete(id);
    }
    else
    {
        SendSyntaxMessage(playerid, "/editgentrance [id] [type]");
        SendClientMessage(playerid, X11_YELLOW_2, "[TYPES]: "WHITE"location, interior, owner, locked, name, destroy");
    }
    return 1;
}
