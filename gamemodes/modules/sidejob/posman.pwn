// defined
#define MAX_POSMAN_VEHICLE      3
#define POSMAN_SALARY           15000
#define MAX_POSMAN_BOXES        50
#define MAX_POSMAN_NEWS         50

// global variables
static posmanVehicle[MAX_POSMAN_VEHICLE] = {INVALID_VEHICLE_ID, ...};
static posmanVehicleObjects[MAX_POSMAN_VEHICLE][4];
new bool:DialogPSidejob[MAX_POSMAN_VEHICLE];
new PlayerPSidejob[MAX_PLAYERS];

// player variables
static bool:hasPosman[MAX_PLAYERS] = {false, ...};
static bool:posmanAtTarget[MAX_PLAYERS] = {false, ...};
static bool:posmanCarryPaper[MAX_PLAYERS] = {false, ...};
static posmanProgress[MAX_PLAYERS];
static posmanTargetIndex[MAX_PLAYERS];
static bool:posmanVisited[MAX_PLAYERS][MAX_POSMAN_BOXES];
static posmanOut[MAX_PLAYERS];
static outCheckPosman[MAX_PLAYERS];
static Timer:outTimerPosman[MAX_PLAYERS];
static Timer:outTimePosman[MAX_PLAYERS];

// data arrays
enum E_POSMAN_BOX {
    pb_id,
    Float:pb_x,
    Float:pb_y,
    Float:pb_z,
    Float:pb_angle,
    pb_world,
    pb_interior,
    pb_object,
    Text3D:pb_label,
    Text3D:pb_info
};
new PosmanBoxes[MAX_POSMAN_BOXES][E_POSMAN_BOX];

enum E_POSMAN_NEWS {
    pn_id,
    pn_title[128],
    pn_story[1024],
    pn_date[32]
};
new PosmanNews[MAX_POSMAN_NEWS][E_POSMAN_NEWS];

stock Posman_RefreshNews()
{
    for (new i = 0; i < MAX_POSMAN_NEWS; i++)
    {
        PosmanNews[i][pn_id] = 0;
        PosmanNews[i][pn_title][0] = '\0';
        PosmanNews[i][pn_story][0] = '\0';
        PosmanNews[i][pn_date][0] = '\0';
    }
    mysql_tquery(g_iHandle, "SELECT * FROM `posman_news` ORDER BY `id` DESC LIMIT 50", "LoadPosmanNews");
    return 1;
}

stock Posman_GetBoxByID(boxdbid)
{
    for (new i = 0; i < MAX_POSMAN_BOXES; i++)
    {
        if (PosmanBoxes[i][pb_id] == boxdbid)
            return i;
    }
    return -1;
}

stock Posman_ResetBox(boxid)
{
    PosmanBoxes[boxid][pb_id] = 0;
    PosmanBoxes[boxid][pb_x] = 0.0;
    PosmanBoxes[boxid][pb_y] = 0.0;
    PosmanBoxes[boxid][pb_z] = 0.0;
    PosmanBoxes[boxid][pb_angle] = 0.0;
    PosmanBoxes[boxid][pb_world] = 0;
    PosmanBoxes[boxid][pb_interior] = 0;
    PosmanBoxes[boxid][pb_object] = 0;
    PosmanBoxes[boxid][pb_label] = Text3D:INVALID_STREAMER_ID;
    PosmanBoxes[boxid][pb_info] = Text3D:INVALID_STREAMER_ID;
    return 1;
}

stock Posman_DestroyBox(boxid)
{
    if (PosmanBoxes[boxid][pb_object] != 0)
    {
        DestroyDynamicObject(PosmanBoxes[boxid][pb_object]);
        PosmanBoxes[boxid][pb_object] = 0;
    }
    if (PosmanBoxes[boxid][pb_label] != Text3D:INVALID_STREAMER_ID)
    {
        DestroyDynamic3DTextLabel(PosmanBoxes[boxid][pb_label]);
        PosmanBoxes[boxid][pb_label] = Text3D:INVALID_STREAMER_ID;
    }
    if (PosmanBoxes[boxid][pb_info] != Text3D:INVALID_STREAMER_ID)
    {
        DestroyDynamic3DTextLabel(PosmanBoxes[boxid][pb_info]);
        PosmanBoxes[boxid][pb_info] = Text3D:INVALID_STREAMER_ID;
    }
    return 1;
}

stock Posman_CreateBox(boxid)
{
    new label[32];

    Posman_DestroyBox(boxid);

    PosmanBoxes[boxid][pb_object] = CreateDynamicObject(19867, PosmanBoxes[boxid][pb_x], PosmanBoxes[boxid][pb_y], PosmanBoxes[boxid][pb_z] - 0.5, 0.0, 0.0, PosmanBoxes[boxid][pb_angle], PosmanBoxes[boxid][pb_world], PosmanBoxes[boxid][pb_interior]);
    format(label, sizeof(label), "{ffcc00}POS [ID:%d]", PosmanBoxes[boxid][pb_id]);
    PosmanBoxes[boxid][pb_label] = CreateDynamic3DTextLabel(label, -1, PosmanBoxes[boxid][pb_x], PosmanBoxes[boxid][pb_y], PosmanBoxes[boxid][pb_z] + 0.6, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, PosmanBoxes[boxid][pb_world], PosmanBoxes[boxid][pb_interior]);
    PosmanBoxes[boxid][pb_info] = CreateDynamic3DTextLabel("{FFFFFF}Type '/read' to read the newspaper.", COLOR_CLIENT, PosmanBoxes[boxid][pb_x], PosmanBoxes[boxid][pb_y], PosmanBoxes[boxid][pb_z] + 0.3, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, PosmanBoxes[boxid][pb_world], PosmanBoxes[boxid][pb_interior]);
    return 1;
}

stock Posman_SaveBox(playerid, boxid)
{
    new query[512];
    mysql_format(g_iHandle, query, sizeof(query), "UPDATE `posman_map` SET `x` = %f, `y` = %f, `z` = %f, `angle` = %f, `world` = %d, `interior` = %d WHERE `id` = %d",
        PosmanBoxes[boxid][pb_x],
        PosmanBoxes[boxid][pb_y],
        PosmanBoxes[boxid][pb_z],
        PosmanBoxes[boxid][pb_angle],
        PosmanBoxes[boxid][pb_world],
        PosmanBoxes[boxid][pb_interior],
        PosmanBoxes[boxid][pb_id]
    );
    mysql_tquery(g_iHandle, query, "OnPosmanBoxSaved", "ii", playerid, boxid);
    return 1;
}

stock Posman_DestroyBikeObjects(slot)
{
    if (slot < 0 || slot >= MAX_POSMAN_VEHICLE)
        return 0;

    for (new i = 0; i < 4; i++)
    {
        if (posmanVehicleObjects[slot][i] != 0)
        {
            DestroyDynamicObject(posmanVehicleObjects[slot][i]);
            posmanVehicleObjects[slot][i] = 0;
        }
    }
    return 1;
}

stock Posman_DestroyBike(slot)
{
    if (slot < 0 || slot >= MAX_POSMAN_VEHICLE)
        return 0;

    Posman_DestroyBikeObjects(slot);

    if (posmanVehicle[slot] != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(posmanVehicle[slot]);
        posmanVehicle[slot] = INVALID_VEHICLE_ID;
    }
    return 1;
}

stock Posman_ResetVisited(playerid)
{
    for (new i = 0; i < MAX_POSMAN_BOXES; i++)
    {
        posmanVisited[playerid][i] = false;
    }
    posmanTargetIndex[playerid] = -1;
    return 1;
}

stock Posman_GetVehicleSlot(vehicleid)
{
    for (new i = 0; i < MAX_POSMAN_VEHICLE; i++)
    {
        if (posmanVehicle[i] == vehicleid && vehicleid != INVALID_VEHICLE_ID)
            return i;
    }
    return -1;
}

stock Posman_GetAssignedVehicle(playerid)
{
    if (PlayerPSidejob[playerid] == -1)
        return INVALID_VEHICLE_ID;

    return posmanVehicle[PlayerPSidejob[playerid]];
}

stock bool:Posman_IsNearAssignedBike(playerid, Float:range = 3.0)
{
    new vehicleid = Posman_GetAssignedVehicle(playerid);
    new Float:x, Float:y, Float:z;

    if (vehicleid == INVALID_VEHICLE_ID)
        return false;

    GetVehiclePos(vehicleid, x, y, z);
    if (IsPlayerInRangeOfPoint(playerid, range, x, y, z))
        return true;

    return false;
}

stock bool:Posman_IsNearTargetBox(playerid, Float:range = 3.0)
{
    new target = posmanTargetIndex[playerid];
    if (target == -1 || PosmanBoxes[target][pb_id] <= 0)
        return false;

    if (IsPlayerInRangeOfPoint(playerid, range, PosmanBoxes[target][pb_x], PosmanBoxes[target][pb_y], PosmanBoxes[target][pb_z]))
        return true;

    return false;
}

stock Posman_AttachPaper(playerid)
{
    if (IsPlayerAttachedObjectSlotUsed(playerid, JOB_SLOT))
        RemovePlayerAttachedObject(playerid, JOB_SLOT);

    SetPlayerAttachedObject(playerid, JOB_SLOT, 2855, 1, -0.015999, 0.460999, 0.000000, -0.700003, 95.999992, 71.699905, 1.000000, 1.000000, 1.000000, 0x0, 0x0); //2855
    return 1;
}

stock Posman_RemovePaper(playerid)
{
    if (IsPlayerAttachedObjectSlotUsed(playerid, JOB_SLOT))
        RemovePlayerAttachedObject(playerid, JOB_SLOT);

    return 1;
}

stock Posman_AttachBikeObjects(slot)
{
    if (slot < 0 || slot >= MAX_POSMAN_VEHICLE || posmanVehicle[slot] == INVALID_VEHICLE_ID)
        return 0;

    Posman_DestroyBikeObjects(slot);

    posmanVehicleObjects[slot][0] = CreateDynamicObject(917, 0.0, 0.0, -1000.0, 0.0, 0.0, 0.0, -1, -1, -1, 300.0, 300.0);
    SetDynamicObjectMaterial(posmanVehicleObjects[slot][0], 0, 18646, "matcolours", "grey-90-percent", 0);
    AttachDynamicObjectToVehicle(posmanVehicleObjects[slot][0], posmanVehicle[slot], -0.040, 0.521, 0.275, 21.200, 0.000, 0.000);

    posmanVehicleObjects[slot][1] = CreateDynamicObject(2813, 0.0, 0.0, -1000.0, 0.0, 0.0, 0.0, -1, -1, -1, 300.0, 300.0);
    AttachDynamicObjectToVehicle(posmanVehicleObjects[slot][1], posmanVehicle[slot], 0.050, 0.479, 0.380, -54.900, 0.000, 0.000);

    posmanVehicleObjects[slot][2] = CreateDynamicObject(916, 0.0, 0.0, -1000.0, 0.0, 0.0, 0.0, -1, -1, -1, 300.0, 300.0);
    SetDynamicObjectMaterial(posmanVehicleObjects[slot][2], 0, 18646, "matcolours", "grey-90-percent", 0);
    SetDynamicObjectMaterial(posmanVehicleObjects[slot][2], 1, 18646, "matcolours", "grey-90-percent", 0);
    AttachDynamicObjectToVehicle(posmanVehicleObjects[slot][2], posmanVehicle[slot], 0.005, -0.500, 0.240, 0.000, 0.000, 175.299);

    posmanVehicleObjects[slot][3] = CreateDynamicObject(2827, 0.0, 0.0, -1000.0, 0.0, 0.0, 0.0, -1, -1, -1, 300.0, 300.0);
    AttachDynamicObjectToVehicle(posmanVehicleObjects[slot][3], posmanVehicle[slot], -0.110, -0.579, 0.266, -20.700, 0.000, 0.000);
    return 1;
}

stock Posman_WrapText(dest[], dest_size, const source[], line_width = 48)
{
    new len = strlen(source), out = 0, last_space = -1, line_len = 0;

    if (dest_size <= 1)
        return 0;

    dest[0] = '\0';

    for (new i = 0; i < len && out < dest_size - 1; i++)
    {
        dest[out++] = source[i];
        dest[out] = '\0';

        if (source[i] == ' ')
            last_space = out - 1;

        if (source[i] == '\n')
        {
            line_len = 0;
            last_space = -1;
            continue;
        }

        line_len++;
        if (line_len >= line_width)
        {
            if (last_space != -1)
            {
                dest[last_space] = '\n';
                line_len = out - last_space - 1;
                last_space = -1;
            }
            else if (out < dest_size - 1)
            {
                dest[out++] = '\n';
                dest[out] = '\0';
                line_len = 0;
                last_space = -1;
            }
        }
    }
    return 1;
}

// SAMP callback
#include <YSI\y_hooks>

hook OnGameModeInitEx()
{
    // Load data
    mysql_tquery(g_iHandle, "SELECT * FROM `posman_map`", "LoadPosmanMap");
    mysql_tquery(g_iHandle, "SELECT * FROM `posman_news` ORDER BY `id` DESC LIMIT 50", "LoadPosmanNews");

    CreateDynamicMapIcon(1292.6053, -1862.7441, 13.5468, 56, -1, -1, 0); //Map Icon
    CreateDynamic3DTextLabel("{FFFF00}[Posman Sidejob]\n{FFFFFF}Use 'H' to start sidejob", -1, 1291.9812, -1878.4691, 13.5468, 10.0);
    return 1;
}

forward LoadPosmanMap();
public LoadPosmanMap()
{
    new rows = cache_num_rows();
    if (rows > MAX_POSMAN_BOXES) rows = MAX_POSMAN_BOXES;
    for (new i = 0; i < rows; i++)
    {
        cache_get_value_int(i, "id", PosmanBoxes[i][pb_id]);
        cache_get_value_float(i, "x", PosmanBoxes[i][pb_x]);
        cache_get_value_float(i, "y", PosmanBoxes[i][pb_y]);
        cache_get_value_float(i, "z", PosmanBoxes[i][pb_z]);
        cache_get_value_float(i, "angle", PosmanBoxes[i][pb_angle]);
        cache_get_value_int(i, "world", PosmanBoxes[i][pb_world]);
        cache_get_value_int(i, "interior", PosmanBoxes[i][pb_interior]);
        Posman_CreateBox(i);
    }
    printf("[POSMAN] Loaded %d posman map objects.", rows);
    return 1;
}

forward LoadPosmanNews();
public LoadPosmanNews()
{
    new rows = cache_num_rows();
    if (rows > MAX_POSMAN_NEWS) rows = MAX_POSMAN_NEWS;
    for (new i = 0; i < rows; i++)
    {
        cache_get_value_int(i, "id", PosmanNews[i][pn_id]);
        cache_get_value_name(i, "title", PosmanNews[i][pn_title]);
        cache_get_value_name(i, "story", PosmanNews[i][pn_story]);
        cache_get_value_name(i, "date", PosmanNews[i][pn_date]);
    }
    printf("[POSMAN] Loaded %d posman news.", rows);
    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerData[playerid][pPosmanSidejob] = 0;
    PlayerPSidejob[playerid] = -1;
    hasPosman[playerid] = false;
    posmanAtTarget[playerid] = false;
    posmanCarryPaper[playerid] = false;
    posmanProgress[playerid] = 0;
    Posman_ResetVisited(playerid);
    outCheckPosman[playerid] = 0;
    stop outTimerPosman[playerid];
    stop outTimePosman[playerid];
    return 1;
}

hook OnPlayerSpawn(playerid)
{
    hasPosman[playerid] = false;
    posmanAtTarget[playerid] = false;
    posmanCarryPaper[playerid] = false;
    posmanProgress[playerid] = 0;
    Posman_ResetVisited(playerid);
    outCheckPosman[playerid] = 0;
    stop outTimerPosman[playerid];
    stop outTimePosman[playerid];
    return 1;
}

hook OnPlayerDisconnectEx(playerid)
{
    if (PlayerData[playerid][pPosmanSidejob])
    {
        new slot = PlayerPSidejob[playerid];

        PlayerData[playerid][pPosmanSidejob] = 0;
        if (slot != -1)
            DialogPSidejob[slot] = false;

        if (slot != -1)
            Posman_DestroyBike(slot);
        PlayerPSidejob[playerid] = -1;
        DisablePlayerRaceCheckpoint(playerid);
        posmanAtTarget[playerid] = false;
        posmanCarryPaper[playerid] = false;
        Posman_RemovePaper(playerid);
        SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
        Posman_ResetVisited(playerid);
        stop outTimerPosman[playerid];
        stop outTimePosman[playerid];
        outCheckPosman[playerid] = 0;

        SetPosmanDelay(playerid, 600); // Penalty
    }
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_CTRL_BACK) //Key H
    {
        if(IsPlayerInRangeOfPoint(playerid, 3.0, 1291.9812, -1878.4691, 13.5468))
        {
            if(PlayerData[playerid][pPosmanSidejob] == 1)
                return SendErrorMessage(playerid, "Kamu sedang bekerja Posman, selesaikan dulu pekerjaanmu.");

            if(PlayerData[playerid][pMaskOn])
                return SendErrorMessage(playerid, "Disable your mask first."), RemovePlayerFromVehicle(playerid);

            if(GetPosmanDelay(playerid) > 0)
            {
                SendCustomMessage(playerid, "POSMAN", "Kamu tidak dapat bekerja sekarang, tunggu %d menit untuk memulainya kembali.", (GetPosmanDelay(playerid)/60));
                return 1;
            }
            new str[640];
            format(str, sizeof(str), "Posman Bike\tStatus\n");
            for (new i = 0; i < 3; i ++) {
                format(str, sizeof(str), "%sBike Type %d\t"GREEN"%s\n", str, i, (DialogPSidejob[i] == true) ? (RED"Taken") : (GREEN"Availeble"));
            }
            Dialog_Show(playerid, SidejobPosmanstatus, DIALOG_STYLE_TABLIST_HEADERS, "Posman Sidejob", str, "Start", "Close");
        }
    }
    return 1;
}

Dialog:SidejobPosmanstatus(playerid, response, listitem, inputtext[]) 
{
    if (response && listitem != -1) {
        if (DialogPSidejob[listitem] == true)
            return SendErrorMessage(playerid, "This Posman Bike has already taken by someone!");

        DialogPSidejob[listitem] = true;
        PlayerPSidejob[playerid] = listitem;
        PlayerData[playerid][pPosmanSidejob] = 1;

        posmanVehicle[listitem] = CreateVehicle(510, 1291.9812 + (listitem * 2.0), -1878.4691, 13.5468, 359.5106, 1, 1, 500);
        ResetVehicle(posmanVehicle[listitem]);
        CoreVehicles[posmanVehicle[listitem]][vehTemporary] = true;
        SetVehicleNumberPlate(posmanVehicle[listitem], "POSMAN");
        Posman_AttachBikeObjects(listitem);
        PutPlayerInVehicle(playerid, posmanVehicle[listitem], 0);
        SetCameraBehindPlayer(playerid);

        Dialog_Show(playerid, PosmanJob, DIALOG_STYLE_MSGBOX, "Posman Sidejob", ""WHITE"Kamu menaiki sepeda posman.\nKamu akan di tugaskan untuk mengirim paket surat koran di kota Los Santos.\n\nPilih opsi \"Mulai\" untuk melakukan pekerjaan.", "Mulai", "Turun");
    }
    return 1;
}

IsPosmanVehicle(vehicleid)
{
    for(new i = 0; i < MAX_POSMAN_VEHICLE; i++) if(vehicleid == posmanVehicle[i] && vehicleid != INVALID_VEHICLE_ID)
        return 1;
    return 0;
}

hook OnVehicleSpawn(vehicleid)
{
    new slot = Posman_GetVehicleSlot(vehicleid);
    if (slot != -1 && !DialogPSidejob[slot])
        Posman_DestroyBikeObjects(slot);
    return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
    new slot = Posman_GetVehicleSlot(vehicleid);
    if (slot != -1)
        Posman_DestroyBikeObjects(slot);
    return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(newstate == PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_ONFOOT)
    {
        if(outCheckPosman[playerid] == 1)
        {
            if(IsPosmanVehicle(GetPlayerLastVehicle(playerid)))
            {
                if(!GetPlayerLastVehicle(playerid))
                {
                    SendCustomMessage(playerid, "POSMAN", "Silahkan pilih sepeda yang terakhir kamu naiki.");
                    RemovePlayerFromVehicle(playerid);
                    return 1;
                }
                outCheckPosman[playerid] = 0;
                stop outTimerPosman[playerid];
                stop outTimePosman[playerid];
            }
            return 1;
        }
    }

    if(newstate == PLAYER_STATE_ONFOOT && oldstate == PLAYER_STATE_DRIVER)
    {
        if(hasPosman[playerid])
        {
            if (IsPosmanVehicle(GetPlayerLastVehicle(playerid)))
            {
                posmanOut[playerid] = 25;
                outCheckPosman[playerid] = 1;
                outTimerPosman[playerid] = repeat InsidePosmanOut(playerid);
                outTimePosman[playerid] = defer SetPlayerToCancelPosman[25000](playerid);
                GameTextForPlayer(playerid, sprintf("ENTER THE POSMAN BIKE~n~~y~%02d SECONDS", posmanOut[playerid]), 1000, 6);
                PlayerPlaySoundEx(playerid, 43000);
            }
        }
    }
    return 1;
}

timer SetPlayerToCancelPosman[1000](playerid)
{
    new slot = PlayerPSidejob[playerid];

    PlayerData[playerid][pPosmanSidejob] = 0;
    if (slot != -1) DialogPSidejob[slot] = false;
    PlayerPSidejob[playerid] = -1;
    hasPosman[playerid] = false;
    posmanAtTarget[playerid] = false;
    posmanCarryPaper[playerid] = false;
    Posman_RemovePaper(playerid);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
    posmanProgress[playerid] = 0;
    Posman_ResetVisited(playerid);
    outCheckPosman[playerid] = 0;
    
    stop outTimerPosman[playerid];
    stop outTimePosman[playerid];

    if (slot != -1)
        Posman_DestroyBikeObjects(slot);
    SetVehicleToRespawn(GetPlayerLastVehicle(playerid));
    DisablePlayerRaceCheckpoint(playerid);
    SetPosmanDelay(playerid, 600);
    SendCustomMessage(playerid, "POSMAN", "Kamu gagal dan tidak tuntas menyelesaikan pekerjaan posman.");
    return 1;
}

timer InsidePosmanOut[1000](playerid)
{
    posmanOut[playerid]--;
    GameTextForPlayer(playerid, sprintf("ENTER THE POSMAN BIKE~n~~y~%02d SECONDS", posmanOut[playerid]), 1000, 6);
    PlayerPlaySoundEx(playerid, 43000);
    return 1;
}

SetPosmanCheckpoint(playerid)
{
    new availableBoxes[MAX_POSMAN_BOXES];
    new availableCount = 0;

    if (posmanProgress[playerid] >= 10)
    {
        // Return to base
        SetPlayerRaceCheckpoint(playerid, 1, 1291.9812, -1878.4691, 13.5468, -1.0, -1.0, -1.0, 3.0);
        SendCustomMessage(playerid, "POSMAN", "Kamu telah mengantar semua surat. Kembalilah ke titik awal untuk menerima gaji!");
    }
    else
    {
        // Pick random unvisited box from cache
        for (new i = 0; i < MAX_POSMAN_BOXES; i++)
        {
            if (PosmanBoxes[i][pb_id] > 0 && !posmanVisited[playerid][i])
            {
                availableBoxes[availableCount++] = i;
            }
        }

        if (availableCount == 0) {
            SetPlayerRaceCheckpoint(playerid, 1, 1291.9812, -1878.4691, 13.5468, -1.0, -1.0, -1.0, 3.0);
            posmanProgress[playerid] = 10;
            return SendErrorMessage(playerid, "Tidak ada posman box lain yang tersedia.");
        }

        new target = availableBoxes[RandomEx(0, availableCount - 1)];
        posmanTargetIndex[playerid] = target;
        SetPlayerRaceCheckpoint(playerid, 0, PosmanBoxes[target][pb_x], PosmanBoxes[target][pb_y], PosmanBoxes[target][pb_z], -1.0, -1.0, -1.0, 3.0);
        SendServerMessage(playerid, "Kirimkan surat koran ke checkpoint merah di map!");
    }
    return 1;
}

hook OnPlayerEnterRaceCP(playerid)
{
    if(hasPosman[playerid])
    {
        if (posmanProgress[playerid] >= 10)
        {
            // Payment
            new index = PlayerPSidejob[playerid];
            PlayerData[playerid][pPosmanSidejob] = 0;
            DialogPSidejob[index] = false;
            hasPosman[playerid] = false;
            posmanAtTarget[playerid] = false;
            posmanCarryPaper[playerid] = false;
            Posman_RemovePaper(playerid);
            SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
            posmanProgress[playerid] = 0;
            Posman_ResetVisited(playerid);

            if (index != -1)
                Posman_DestroyBikeObjects(index);
            SetVehicleToRespawn(GetPlayerVehicleID(playerid));
            DisablePlayerRaceCheckpoint(playerid);

            SendCustomMessage(playerid, "POSMAN", "Kamu telah menyelesaikan pekerjaan, dan kamu mendapat upah "COL_GREEN"$%s "WHITE"dari pekerjaan ini.", FormatNumber(POSMAN_SALARY));
            AddPlayerSalary(playerid, POSMAN_SALARY, "Posman Sidejob");
            SetPosmanDelay(playerid, 900);
            PlayerPSidejob[playerid] = -1;
            RemovePlayerFromVehicle(playerid);
        }
        else
        {
            if (!IsPosmanVehicle(GetPlayerVehicleID(playerid)))
                return SendErrorMessage(playerid, "Kamu harus sampai ke checkpoint menggunakan sepeda posman.");

            posmanAtTarget[playerid] = true;
            posmanCarryPaper[playerid] = false;
            DisablePlayerRaceCheckpoint(playerid);
            SendCustomMessage(playerid, "POSMAN", "Anda harus /takepaper di dekat sepeda lalu /droppaper di dekat pos.");
        }
    }
    return 1;
}

Dialog:PosmanJob(playerid, response, listitem, inputtext[])
{
    if(response)
    {
        hasPosman[playerid] = true;
        posmanAtTarget[playerid] = false;
        posmanCarryPaper[playerid] = false;
        posmanProgress[playerid] = 0;
        SetEngineStatus(GetPlayerVehicleID(playerid), true);
        SetPosmanCheckpoint(playerid);
    }
    else
    {
        PlayerData[playerid][pPosmanSidejob] = 0;
        if (PlayerPSidejob[playerid] != -1) DialogPSidejob[PlayerPSidejob[playerid]] = false;
        if (PlayerPSidejob[playerid] != -1) Posman_DestroyBikeObjects(PlayerPSidejob[playerid]);
        PlayerPSidejob[playerid] = -1;
        posmanAtTarget[playerid] = false;
        posmanCarryPaper[playerid] = false;
        Posman_RemovePaper(playerid);
        SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
        Posman_ResetVisited(playerid);
        DestroyVehicle(GetPlayerVehicleID(playerid));
    }
    return 1;
}

CMD:createposman(playerid, params[])
{
    if (PlayerData[playerid][pAdmin] < 4) return PermissionError(playerid);

    new freeSlot = -1;
    for (new i = 0; i < MAX_POSMAN_BOXES; i++)
    {
        if (PosmanBoxes[i][pb_id] == 0)
        {
            freeSlot = i;
            break;
        }
    }
    if (freeSlot == -1)
        return SendErrorMessage(playerid, "Posman box slot is full.");
    
    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new query[256];
    mysql_format(g_iHandle, query, sizeof(query), "INSERT INTO `posman_map` (`x`, `y`, `z`, `angle`, `world`, `interior`) VALUES (%f, %f, %f, %f, %d, %d)", x, y, z, a, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
    mysql_tquery(g_iHandle, query, "OnPosmanMapCreated", "i", playerid);

    return 1;
}

forward OnPosmanMapCreated(playerid);
public OnPosmanMapCreated(playerid)
{
    new boxid = -1;
    for (new i = 0; i < MAX_POSMAN_BOXES; i++)
    {
        if (PosmanBoxes[i][pb_id] == 0)
        {
            boxid = i;
            break;
        }
    }

    if (boxid == -1)
        return SendErrorMessage(playerid, "Posman box slot is full.");

    PosmanBoxes[boxid][pb_id] = cache_insert_id();
    GetPlayerPos(playerid, PosmanBoxes[boxid][pb_x], PosmanBoxes[boxid][pb_y], PosmanBoxes[boxid][pb_z]);
    GetPlayerFacingAngle(playerid, PosmanBoxes[boxid][pb_angle]);
    PosmanBoxes[boxid][pb_world] = GetPlayerVirtualWorld(playerid);
    PosmanBoxes[boxid][pb_interior] = GetPlayerInterior(playerid);
    Posman_CreateBox(boxid);
    SendServerMessage(playerid, "You have successfully created a new Posman Box.");
    return 1;
}

forward OnPosmanBoxSaved(playerid, boxid);
public OnPosmanBoxSaved(playerid, boxid)
{
    if (PosmanBoxes[boxid][pb_id] > 0)
        SendCustomMessage(playerid, "POSMAN", "Posman Box ID %d position has been saved.", PosmanBoxes[boxid][pb_id]);
    return 1;
}

CMD:editposman(playerid, params[])
{
    if (PlayerData[playerid][pAdmin] < 4) return PermissionError(playerid);

    new boxdbid;
    if (sscanf(params, "d", boxdbid))
        return SendSyntaxMessage(playerid, "/editposman [id]");

    new boxid = Posman_GetBoxByID(boxdbid);
    if (boxid == -1)
        return SendErrorMessage(playerid, "Posman box ID tidak ditemukan.");

    PlayerData[playerid][pEditPosman] = boxid;
    PlayerData[playerid][pEditingMode] = POSMAN;
    EditDynamicObject(playerid, PosmanBoxes[boxid][pb_object]);
    SendServerMessage(playerid, "Edit the posman object position, then save it.");
    return 1;
}

CMD:deleteposman(playerid, params[])
{
    if (PlayerData[playerid][pAdmin] < 4) return PermissionError(playerid);

    new boxdbid;
    if (sscanf(params, "d", boxdbid))
        return SendSyntaxMessage(playerid, "/deleteposman [id]");

    new boxid = Posman_GetBoxByID(boxdbid);
    if (boxid == -1)
        return SendErrorMessage(playerid, "Posman box ID tidak ditemukan.");

    mysql_tquery(g_iHandle, sprintf("DELETE FROM `posman_map` WHERE `id` = %d", PosmanBoxes[boxid][pb_id]));
    Posman_DestroyBox(boxid);
    Posman_ResetBox(boxid);

    SendServerMessage(playerid, "You have deleted the selected Posman Box.");
    return 1;
}

CMD:gotoposman(playerid, params[])
{
    if (PlayerData[playerid][pAdmin] < 4) return PermissionError(playerid);

    new boxdbid;
    if (sscanf(params, "d", boxdbid))
        return SendSyntaxMessage(playerid, "/gotoposman [id]");

    new boxid = Posman_GetBoxByID(boxdbid);
    if (boxid == -1)
        return SendErrorMessage(playerid, "Posman box ID tidak ditemukan.");

    SetPlayerPos(playerid, PosmanBoxes[boxid][pb_x], PosmanBoxes[boxid][pb_y], PosmanBoxes[boxid][pb_z] + 1.0);
    SetPlayerFacingAngle(playerid, PosmanBoxes[boxid][pb_angle]);
    SetPlayerVirtualWorld(playerid, PosmanBoxes[boxid][pb_world]);
    SetPlayerInterior(playerid, PosmanBoxes[boxid][pb_interior]);
    SendCustomMessage(playerid, "POSMAN", "You have been teleported to Posman Box ID %d.", PosmanBoxes[boxid][pb_id]);
    return 1;
}

CMD:takepaper(playerid, params[])
{
    if (!hasPosman[playerid] || !PlayerData[playerid][pPosmanSidejob])
        return SendErrorMessage(playerid, "Kamu tidak sedang mengerjakan sidejob posman.");

    if (!posmanAtTarget[playerid])
        return SendErrorMessage(playerid, "Kamu belum berada di checkpoint pengantaran posman.");

    if (IsPlayerInAnyVehicle(playerid))
        return SendErrorMessage(playerid, "Turun dari sepeda terlebih dahulu.");

    if (posmanCarryPaper[playerid])
        return SendErrorMessage(playerid, "Kamu sudah mengambil koran.");

    if (!Posman_IsNearAssignedBike(playerid, 4.0))
        return SendErrorMessage(playerid, "Kamu harus berada di dekat sepeda posman untuk mengambil koran.");

    ApplyAnimation(playerid, "CARRY", "liftup", 4.1, 0, 0, 0, 0, 0, 1);
    Posman_AttachPaper(playerid);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY);
    posmanCarryPaper[playerid] = true;
    SendCustomMessage(playerid, "POSMAN", "Koran berhasil diambil. Sekarang antar ke kotak pos dan gunakan /droppaper.");
    return 1;
}

CMD:droppaper(playerid, params[])
{
    if (!hasPosman[playerid] || !PlayerData[playerid][pPosmanSidejob])
        return SendErrorMessage(playerid, "Kamu tidak sedang mengerjakan sidejob posman.");

    if (!posmanAtTarget[playerid])
        return SendErrorMessage(playerid, "Kamu belum berada di checkpoint pengantaran posman.");

    if (!posmanCarryPaper[playerid])
        return SendErrorMessage(playerid, "Kamu harus mengambil koran terlebih dahulu dengan /takepaper.");

    if (IsPlayerInAnyVehicle(playerid))
        return SendErrorMessage(playerid, "Turun dari sepeda terlebih dahulu.");

    if (!Posman_IsNearTargetBox(playerid, 3.0))
        return SendErrorMessage(playerid, "Kamu harus berada di dekat kotak pos untuk menaruh koran.");

    ApplyAnimation(playerid, "CARRY", "putdwn", 4.1, 0, 0, 0, 0, 0, 1);
    Posman_RemovePaper(playerid);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
    posmanCarryPaper[playerid] = false;
    posmanAtTarget[playerid] = false;

    if (posmanTargetIndex[playerid] != -1)
        posmanVisited[playerid][posmanTargetIndex[playerid]] = true;

    posmanProgress[playerid]++;
    PlayerPlaySoundEx(playerid, 1056);
    SendCustomMessage(playerid, "POSMAN", "Surat koran berhasil terkirim (%d/10).", posmanProgress[playerid]);
    SetPosmanCheckpoint(playerid);
    return 1;
}

CMD:createstory(playerid, params[])
{
    if (PlayerData[playerid][pAdmin] < 3) return PermissionError(playerid);

    new title[128], story[1024];
    if(sscanf(params, "p<|>s[128]s[1024]", title, story)) 
        return SendSyntaxMessage(playerid, "/createstory [title] | [story]");

    new date[32];
    format(date, sizeof(date), "%s", ReturnDate());

    new query[2048];
    mysql_format(g_iHandle, query, sizeof(query), "INSERT INTO `posman_news` (`title`, `story`, `date`) VALUES ('%e', '%e', '%e')", title, story, date);
    mysql_tquery(g_iHandle, query, "OnPosmanNewsCreated", "i", playerid);
    
    return 1;
}

forward OnPosmanNewsCreated(playerid);
public OnPosmanNewsCreated(playerid)
{
    Posman_RefreshNews();
    SendServerMessage(playerid, "You have successfully created a new Story/News.");
    return 1;
}

CMD:deletestory(playerid, params[])
{
    if (PlayerData[playerid][pAdmin] < 3) return PermissionError(playerid);

    new storyid;
    if (sscanf(params, "d", storyid))
        return SendSyntaxMessage(playerid, "/deletestory [id]");

    for (new i = 0; i < MAX_POSMAN_NEWS; i++)
    {
        if (PosmanNews[i][pn_id] == storyid)
        {
            mysql_tquery(g_iHandle, sprintf("DELETE FROM `posman_news` WHERE `id` = %d", storyid));
            Posman_RefreshNews();
            SendCustomMessage(playerid, "POSMAN", "Story ID %d has been deleted.", storyid);
            return 1;
        }
    }
    return SendErrorMessage(playerid, "Story ID tidak ditemukan.");
}

CMD:editstory(playerid, params[])
{
    if (PlayerData[playerid][pAdmin] < 3) return PermissionError(playerid);

    new storyid, title[128], story[1024], date[32], query[2300];
    if (sscanf(params, "dp<|>s[128]s[1024]", storyid, title, story))
        return SendSyntaxMessage(playerid, "/editstory [id] [title] | [story]");

    for (new i = 0; i < MAX_POSMAN_NEWS; i++)
    {
        if (PosmanNews[i][pn_id] == storyid)
        {
            format(date, sizeof(date), "%s", ReturnDate());
            mysql_format(g_iHandle, query, sizeof(query), "UPDATE `posman_news` SET `title` = '%e', `story` = '%e', `date` = '%e' WHERE `id` = %d", title, story, date, storyid);
            mysql_tquery(g_iHandle, query);
            Posman_RefreshNews();
            SendCustomMessage(playerid, "POSMAN", "Story ID %d has been updated.", storyid);
            return 1;
        }
    }
    return SendErrorMessage(playerid, "Story ID tidak ditemukan.");
}

CMD:liststory(playerid, params[])
{
    if (PlayerData[playerid][pAdmin] < 3) return PermissionError(playerid);

    new str[2048], count = 0;
    format(str, sizeof(str), "ID\tDate\tTitle\n");

    for (new i = 0; i < MAX_POSMAN_NEWS; i++)
    {
        if (PosmanNews[i][pn_id] > 0)
        {
            format(str, sizeof(str), "%s%d\t%s\t%s\n", str, PosmanNews[i][pn_id], PosmanNews[i][pn_date], PosmanNews[i][pn_title]);
            count++;
        }
    }

    if (!count)
        return SendErrorMessage(playerid, "Tidak ada story/news tersedia.");

    Dialog_Show(playerid, ShowOnly, DIALOG_STYLE_TABLIST_HEADERS, "Posman Story List", str, "Close", "");
    return 1;
}

CMD:read(playerid, params[])
{
    new withinBox = 0;
    for (new i = 0; i < MAX_POSMAN_BOXES; i++) {
        if (PosmanBoxes[i][pb_id] > 0 && IsPlayerInRangeOfPoint(playerid, 3.0, PosmanBoxes[i][pb_x], PosmanBoxes[i][pb_y], PosmanBoxes[i][pb_z])) {
            withinBox = 1;
            break;
        }
    }
    
    if (!withinBox) return SendErrorMessage(playerid, "Kamu harus berada di dekat Posman Box untuk membaca berita!");

    new str[2048];
    format(str, sizeof(str), "Date\tTitle\n");
    new count = 0;
    for (new i = 0; i < MAX_POSMAN_NEWS; i++) {
        if (PosmanNews[i][pn_id] > 0) {
            format(str, sizeof(str), "%s%s\t%s\n", str, PosmanNews[i][pn_date], PosmanNews[i][pn_title]);
            count++;
        }
    }
    
    if(count == 0) return SendErrorMessage(playerid, "Tidak ada berita saat ini.");
    Dialog_Show(playerid, ReadNews, DIALOG_STYLE_TABLIST_HEADERS, "Daily News", str, "Baca", "Close");
    return 1;
}

Dialog:ReadNews(playerid, response, listitem, inputtext[])
{
    if (response)
    {
        new count = 0;
        new newsIndex = -1;
        for (new i = 0; i < MAX_POSMAN_NEWS; i++) {
            if (PosmanNews[i][pn_id] > 0) {
                if (count == listitem) {
                    newsIndex = i;
                    break;
                }
                count++;
            }
        }
        
        if (newsIndex != -1) {
            new info[2048], wrappedStory[1536];
            Posman_WrapText(wrappedStory, sizeof(wrappedStory), PosmanNews[newsIndex][pn_story], 46);
            format(info, sizeof(info), "Title: {FFFFFF}%s\n{AFAFAF}Date: {FFFFFF}%s\n\n%s", PosmanNews[newsIndex][pn_title], PosmanNews[newsIndex][pn_date], wrappedStory);
            Dialog_Show(playerid, ShowNewsText, DIALOG_STYLE_MSGBOX, "News Story", info, "Tutup", "");
        }
    }
    return 1;
}
