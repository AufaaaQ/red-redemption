#include <YSI\y_hooks>

// ============================================================
//  CONSTANTS & DEFINES
// ============================================================

#define MAX_FLOWERS             (200)
#define FLOWER_OBJ_STAGE1       (859)   
#define FLOWER_OBJ_STAGE2       (860)   
#define FLOWER_OBJ_STAGE3       (870)   
#define FLOWER_STAGE1_DURATION  (150) 
#define FLOWER_STAGE2_DURATION  (150)  
#define FLOWER_WEAPON_ID        (14)
#define FLOWER_WEAPON_AMMO      (1)
#define FLOWER_HARVEST_RANGE    (3.0)

// ============================================================
//  ENUMS & DATA
// ============================================================

enum E_FLOWER_DATA
{
    flID,
    flOwnerID,
    flStage,
    flPlantedTime,
    Float:flPos[3],
    Float:flRot[3],
    flObject
};

new gFlowerData[MAX_FLOWERS][E_FLOWER_DATA];
new Iterator:gFlowers<MAX_FLOWERS>;

new gPlayerPlantingFlower[MAX_PLAYERS] = { -1, ... };

// ============================================================
//  UTILITY FUNCTIONS
// ============================================================

stock bool:Flower_IsValid(id)
    return (id >= 0 && id < MAX_FLOWERS && Iter_Contains(gFlowers, id));

stock Flower_GetStageObject(stage)
{
    switch(stage)
    {
        case 1: return FLOWER_OBJ_STAGE1;
        case 2: return FLOWER_OBJ_STAGE2;
        case 3: return FLOWER_OBJ_STAGE3;
    }
    return FLOWER_OBJ_STAGE1;
}

stock Flower_UpdateStage(id)
{
    if(!Flower_IsValid(id)) return 0;

    new elapsed = gettime() - gFlowerData[id][flPlantedTime];

    if(elapsed >= (FLOWER_STAGE1_DURATION + FLOWER_STAGE2_DURATION))
        gFlowerData[id][flStage] = 3;
    else if(elapsed >= FLOWER_STAGE1_DURATION)
        gFlowerData[id][flStage] = 2;
    else
        gFlowerData[id][flStage] = 1;

    return gFlowerData[id][flStage];
}

stock Flower_Refresh(id)
{
    if(!Flower_IsValid(id)) return 0;

    if(IsValidDynamicObject(gFlowerData[id][flObject]))
        DestroyDynamicObject(gFlowerData[id][flObject]);

    Flower_UpdateStage(id);

    gFlowerData[id][flObject] = CreateDynamicObject(
        Flower_GetStageObject(gFlowerData[id][flStage]),
        gFlowerData[id][flPos][0],
        gFlowerData[id][flPos][1],
        gFlowerData[id][flPos][2],
        gFlowerData[id][flRot][0],
        gFlowerData[id][flRot][1],
        gFlowerData[id][flRot][2],
        0, 0, -1, 200.0
    );
    return 1;
}

stock Flower_GetNearestFullBloom(playerid)
{
    foreach(new id : gFlowers)
    {
        if(gFlowerData[id][flStage] != 3) continue;
        if(IsPlayerInRangeOfPoint(playerid, FLOWER_HARVEST_RANGE,
            gFlowerData[id][flPos][0],
            gFlowerData[id][flPos][1],
            gFlowerData[id][flPos][2]))
            return id;
    }
    return -1;
}

stock Flower_GetNearest(playerid)
{
    foreach(new id : gFlowers)
    {
        if(IsPlayerInRangeOfPoint(playerid, FLOWER_HARVEST_RANGE,
            gFlowerData[id][flPos][0],
            gFlowerData[id][flPos][1],
            gFlowerData[id][flPos][2]))
            return id;
    }
    return -1;
}

// ============================================================
//  DATABASE
// ============================================================

stock Flower_Save(id)
{
    if(!Flower_IsValid(id)) return 0;

    new query[512];
    mysql_format(g_iHandle, query, sizeof(query),
        "UPDATE `flowers` SET \
        `ownerid`='%d', `stage`='%d', `planted`='%d', \
        `posX`='%.4f', `posY`='%.4f', `posZ`='%.4f', \
        `rotX`='%.4f', `rotY`='%.4f', `rotZ`='%.4f' \
        WHERE `id`='%d'",
        gFlowerData[id][flOwnerID],
        gFlowerData[id][flStage],
        gFlowerData[id][flPlantedTime],
        gFlowerData[id][flPos][0], gFlowerData[id][flPos][1], gFlowerData[id][flPos][2],
        gFlowerData[id][flRot][0], gFlowerData[id][flRot][1], gFlowerData[id][flRot][2],
        gFlowerData[id][flID]
    );
    return mysql_tquery(g_iHandle, query);
}

stock Flower_Delete(id)
{
    if(!Flower_IsValid(id)) return 0;

    if(IsValidDynamicObject(gFlowerData[id][flObject]))
        DestroyDynamicObject(gFlowerData[id][flObject]);

    new qDel[128];
    mysql_format(g_iHandle, qDel, sizeof(qDel), "DELETE FROM `flowers` WHERE `id`='%d'", gFlowerData[id][flID]);
    mysql_tquery(g_iHandle, qDel);

    gFlowerData[id][flObject]       = INVALID_STREAMER_ID;
    gFlowerData[id][flOwnerID]      = 0;
    gFlowerData[id][flStage]        = 0;
    gFlowerData[id][flPlantedTime]  = 0;

    Iter_Remove(gFlowers, id);
    return 1;
}

stock Flower_Create(playerid, Float:x, Float:y, Float:z, Float:rx = 0.0, Float:ry = 0.0, Float:rz = 0.0)
{
    new id = Iter_Free(gFlowers);
    if(id == cellmin) return -1;

    Iter_Add(gFlowers, id);

    gFlowerData[id][flOwnerID]      = GetPlayerSQLID(playerid);
    gFlowerData[id][flStage]        = 1;
    gFlowerData[id][flPlantedTime]  = gettime();
    gFlowerData[id][flPos][0]       = x;
    gFlowerData[id][flPos][1]       = y;
    gFlowerData[id][flPos][2]       = z;
    gFlowerData[id][flRot][0]       = rx;
    gFlowerData[id][flRot][1]       = ry;
    gFlowerData[id][flRot][2]       = rz;
    gFlowerData[id][flObject]       = INVALID_STREAMER_ID;

    Flower_Refresh(id);

    new query[512];
    mysql_format(g_iHandle, query, sizeof(query),
        "INSERT INTO `flowers` (`ownerid`, `stage`, `planted`, `posX`, `posY`, `posZ`, `rotX`, `rotY`, `rotZ`) VALUES ('%d', '1', '%d', '%.4f', '%.4f', '%.4f', '%.4f', '%.4f', '%.4f')",
        gFlowerData[id][flOwnerID],
        gFlowerData[id][flPlantedTime],
        x, y, z, rx, ry, rz
    );
    mysql_tquery(g_iHandle, query, "OnFlowerCreated", "d", id);
    return id;
}

Function:OnFlowerCreated(id)
{
    if(!Flower_IsValid(id)) return 0;
    gFlowerData[id][flID] = cache_insert_id();
    return 1;
}

Function:Flower_Load()
{
    new rows = cache_num_rows();

    for(new i = 0; i < rows && i < MAX_FLOWERS; i++)
    {
        Iter_Add(gFlowers, i);

        cache_get_value_int(i,   "id",      gFlowerData[i][flID]);
        cache_get_value_int(i,   "ownerid", gFlowerData[i][flOwnerID]);
        cache_get_value_int(i,   "stage",   gFlowerData[i][flStage]);
        cache_get_value_int(i,   "planted", gFlowerData[i][flPlantedTime]);
        cache_get_value_float(i, "posX",    gFlowerData[i][flPos][0]);
        cache_get_value_float(i, "posY",    gFlowerData[i][flPos][1]);
        cache_get_value_float(i, "posZ",    gFlowerData[i][flPos][2]);
        cache_get_value_float(i, "rotX",    gFlowerData[i][flRot][0]);
        cache_get_value_float(i, "rotY",    gFlowerData[i][flRot][1]);
        cache_get_value_float(i, "rotZ",    gFlowerData[i][flRot][2]);
        gFlowerData[i][flObject] = INVALID_STREAMER_ID;

        Flower_UpdateStage(i);
        Flower_Refresh(i);
    }

    printf("*** [East Side Roleplay Database: Loaded] flower data (%d count).", rows);
    return 1;
}

// ============================================================
//  HOOKS
// ============================================================

hook OnGameModeInitEx()
{
    mysql_tquery(g_iHandle, "SELECT * FROM `flowers`", "Flower_Load", "");
    return 1;
}

hook OnPlayerConnect(playerid)
{
    gPlayerPlantingFlower[playerid] = -1;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(gPlayerPlantingFlower[playerid] != -1)
    {
        new id = gPlayerPlantingFlower[playerid];
        if(Flower_IsValid(id))
            Flower_Delete(id);
        gPlayerPlantingFlower[playerid] = -1;
    }
    return 1;
}

hook OnPlayerEditDynObj(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
    if(gPlayerPlantingFlower[playerid] != -1)
    {
        new id = gPlayerPlantingFlower[playerid];

        if(!Flower_IsValid(id))
        {
            gPlayerPlantingFlower[playerid] = -1;
            return 1;
        }

        switch(response)
        {
            case EDIT_RESPONSE_CANCEL:
            {
                Flower_Delete(id);
                gPlayerPlantingFlower[playerid] = -1;
                SendCustomMessage(playerid, "FLOWER", "Flower planting cancelled.");
            }
            case EDIT_RESPONSE_FINAL:
            {
                gFlowerData[id][flPos][0]  = x;
                gFlowerData[id][flPos][1]  = y;
                gFlowerData[id][flPos][2]  = z;
                gFlowerData[id][flRot][0]  = rx;
                gFlowerData[id][flRot][1]  = ry;
                gFlowerData[id][flRot][2]  = rz;
                gFlowerData[id][flPlantedTime] = gettime();
                gFlowerData[id][flStage]   = 1;

                SetDynamicObjectPos(objectid, x, y, z);
                SetDynamicObjectRot(objectid, rx, ry, rz);

                Flower_Save(id);

                gPlayerPlantingFlower[playerid] = -1;

                SendCustomMessage(playerid, "FLOWER", "Flower successfully planted! It will fully bloom in "YELLOW"5 minutes.");
            }
        }
    }
    return 1;
}

// ============================================================
//  PERIODIC TASK
// ============================================================

task FlowerGrowTask[10000]()
{
    foreach(new id : gFlowers)
    {
        new oldStage = gFlowerData[id][flStage];
        Flower_UpdateStage(id);

        if(gFlowerData[id][flStage] != oldStage)
        {
            Flower_Refresh(id);
            Flower_Save(id);
        }
    }
    return 1;
}

// ============================================================
//  COMMANDS
// ============================================================

CMD:flower(playerid, params[])
{
    if(!SQL_IsCharacterLogged(playerid))
        return SendErrorMessage(playerid, "You must be logged in first.");

    new action[16];

    if(sscanf(params, "s[16]", action))
    {
        SendSyntaxMessage(playerid, "/flower [plant/harvest/info/destroy]");
        SendCustomMessage(playerid, "FLOWER", "plant = plant new flower | harvest = take bloomed flower | info = view nearest flower");
        return 1;
    }

    // ------------------------------------------------------------------
    //  /flower plant
    // ------------------------------------------------------------------
    if(!strcmp(action, "plant", true))
    {
        if(gPlayerPlantingFlower[playerid] != -1)
            return SendErrorMessage(playerid, "You are currently in the process of planting a flower.");

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(playerid, px, py, pz);
        GetXYInFrontOfPlayer(playerid, px, py, 1.5);

        new id = Flower_Create(playerid, px, py, pz);

        if(id == -1)
            return SendErrorMessage(playerid, "The server has reached the maximum flower limit.");

        gPlayerPlantingFlower[playerid] = id;

        Streamer_Update(playerid);
        EditDynamicObject(playerid, gFlowerData[id][flObject]);

        SendCustomMessage(playerid, "FLOWER", "Adjust the planting position, then press "YELLOW"Enter/Save "WHITE"to confirm.");
        SendCustomMessage(playerid, "FLOWER", "Press "RED"ESC "WHITE"to cancel planting.");
        return 1;
    }

    // ------------------------------------------------------------------
    //  /flower harvest
    // ------------------------------------------------------------------
    if(!strcmp(action, "harvest", true))
    {
        new id = Flower_GetNearestFullBloom(playerid);

        if(id == -1)
        {
            new nearId = Flower_GetNearest(playerid);
            if(nearId != -1)
            {
                Flower_UpdateStage(nearId);
                new elapsed    = gettime() - gFlowerData[nearId][flPlantedTime];
                new totalNeeded = FLOWER_STAGE1_DURATION + FLOWER_STAGE2_DURATION;
                new remaining  = totalNeeded - elapsed;
                if(remaining < 0) remaining = 0;
                new minsLeft   = remaining / 60;

                SendErrorMessage(playerid, "This flower has not bloomed yet. Time remaining: ~%d minutes. (Stage %d/3)", minsLeft, gFlowerData[nearId][flStage]);
            }
            else
            {
                SendErrorMessage(playerid, "There are no bloomed flowers near you.");
            }
            return 1;
        }

        GivePlayerWeaponEx(playerid, FLOWER_WEAPON_ID, FLOWER_WEAPON_AMMO);

        SendCustomMessage(playerid, "FLOWER", "You harvested the flower and received a "YELLOW"Flower (Weapon)!");

        Flower_Delete(id);
        return 1;
    }

    // ------------------------------------------------------------------
    //  /flower info
    // ------------------------------------------------------------------
    if(!strcmp(action, "info", true))
    {
        new id = Flower_GetNearest(playerid);

        if(id == -1)
            return SendErrorMessage(playerid, "There are no flowers near you.");

        Flower_UpdateStage(id);
        new elapsed   = gettime() - gFlowerData[id][flPlantedTime];
        new remaining = (FLOWER_STAGE1_DURATION + FLOWER_STAGE2_DURATION) - elapsed;
        if(remaining < 0) remaining = 0;

        new stageName[32];
        switch(gFlowerData[id][flStage])
        {
            case 1: format(stageName, sizeof(stageName), "Just Planted");
            case 2: format(stageName, sizeof(stageName), "Growing");
            case 3: format(stageName, sizeof(stageName), "Bloomed (Ready to Harvest)");
        }

        SendCustomMessage(playerid, "FLOWER", "ID: "WHITE"%d | "YELLOW"Stage: "WHITE"%s (%d/3)", id, stageName, gFlowerData[id][flStage]);

        if(gFlowerData[id][flStage] < 3)
            SendCustomMessage(playerid, "FLOWER", "Time remaining to bloom: "WHITE"~%d minutes", remaining / 60);
        else
            SendCustomMessage(playerid, "FLOWER", "Flower has bloomed! Use "YELLOW"/flower harvest "WHITE"to harvest.");

        return 1;
    }

    // ------------------------------------------------------------------
    //  /flower destroy (admin only)
    // ------------------------------------------------------------------
    if(!strcmp(action, "destroy", true))
    {
        if(CheckAdmin(playerid, 5))
            return PermissionError(playerid);

        new id = Flower_GetNearest(playerid);

        if(id == -1)
            return SendErrorMessage(playerid, "There are no flowers near you.");

        Flower_Delete(id);
        SendCustomMessage(playerid, "FLOWER", "Flower ID %d successfully deleted.", id);
        return 1;
    }

    SendSyntaxMessage(playerid, "/flower [plant/harvest/info/destroy]");
    return 1;
}

// ============================================================
//  ADMIN COMMAND: /aflower (management)
// ============================================================

CMD:aflower(playerid, params[])
{
    if(CheckAdmin(playerid, 7))
        return PermissionError(playerid);

    new option[16], extra[32];
    extra[0] = EOS;

    if(sscanf(params, "s[16]S()[32]", option, extra))
    {
        SendSyntaxMessage(playerid, "/aflower [option]");
        SendCustomMessage(playerid, "AFLOWER", "Options: list, goto [id], delete [id], deleteall");
        return 1;
    }

    if(!strcmp(option, "list", true))
    {
        new count = 0;
        SendCustomMessage(playerid, "AFLOWER", "Flower list:");

        foreach(new id : gFlowers)
        {
            Flower_UpdateStage(id);
            SendCustomMessage(playerid, "AFLOWER", "ID %d | Stage: %d/3 | Pos: %.1f, %.1f, %.1f", id, gFlowerData[id][flStage], gFlowerData[id][flPos][0], gFlowerData[id][flPos][1], gFlowerData[id][flPos][2]);
            count++;
        }

        if(!count) SendCustomMessage(playerid, "AFLOWER", "No flowers planted.");
        return 1;
    }

    new id;

    if(!strcmp(option, "goto", true))
    {
        if(sscanf(extra, "d", id))
            return SendSyntaxMessage(playerid, "/aflower goto [id]");

        if(!Flower_IsValid(id))
            return SendErrorMessage(playerid, "Invalid flower ID.");

        SetPlayerPos(playerid,
            gFlowerData[id][flPos][0],
            gFlowerData[id][flPos][1],
            gFlowerData[id][flPos][2] + 1.0);
        SendCustomMessage(playerid, "AFLOWER", "Teleported to flower ID %d.", id);
        return 1;
    }

    if(!strcmp(option, "delete", true))
    {
        if(sscanf(extra, "d", id))
            return SendSyntaxMessage(playerid, "/aflower delete [id]");

        if(!Flower_IsValid(id))
            return SendErrorMessage(playerid, "Invalid flower ID.");

        Flower_Delete(id);
        SendCustomMessage(playerid, "AFLOWER", "Flower ID %d successfully deleted.", id);
        return 1;
    }

    if(!strcmp(option, "deleteall", true))
    {
        new count = 0;
        foreach(new delid : gFlowers)
        {
            Flower_Delete(delid);
            count++;
        }
        SendCustomMessage(playerid, "AFLOWER", "All flowers (%d) successfully deleted.", count);
        return 1;
    }

    SendSyntaxMessage(playerid, "/aflower [option]");
    SendCustomMessage(playerid, "AFLOWER", "Options: list, goto [id], delete [id], deleteall");
    return 1;
}
