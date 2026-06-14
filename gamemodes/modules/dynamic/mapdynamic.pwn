// Dynamic Map Marker Module
// Object model: 1444

#define MAX_DYNAMIC_MAP (100)
#define COLOR_MAP_TEXT (0xFFFFFFAA)

enum MapDynamic {
    dynamicMapID,
    dynamicMapObject,
    Text3D:dynamicMapText3D,
    Float:dynamicMapPos[3],
    Float:dynamicMapRot,
    dynamicMapWorld,
    dynamicMapInterior
};

new MapDynamicData[MAX_DYNAMIC_MAP][MapDynamic],
    Iterator:DynamicMapMarkers<MAX_DYNAMIC_MAP>;

new g_EditingMap[MAX_PLAYERS] = {-1, ...};

#include <YSI\y_hooks>

hook OnPlayerDisconnect(playerid, reason) {
    g_EditingMap[playerid] = -1;
    return 1;
}

hook OnPlayerEditDynObj(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz) {
    new id = g_EditingMap[playerid];

    if (id == -1 || !Iter_Contains(DynamicMapMarkers, id))
        return 1;

    if (objectid != MapDynamicData[id][dynamicMapObject])
        return 1;

    if (response == EDIT_RESPONSE_FINAL) {
        MapDynamicData[id][dynamicMapPos][0] = x;
        MapDynamicData[id][dynamicMapPos][1] = y;
        MapDynamicData[id][dynamicMapPos][2] = z;
        MapDynamicData[id][dynamicMapRot]    = rz;

        DynamicMap_Save(id);
        DynamicMap_Refresh(id);

        g_EditingMap[playerid] = -1;
        SendServerMessage(playerid, "Map marker %d berhasil disimpan ke posisi baru.", id);
    }
    else if (response == EDIT_RESPONSE_CANCEL) {
        DynamicMap_Refresh(id);

        g_EditingMap[playerid] = -1;
        SendClientMessage(playerid, COLOR_WHITE, "Edit map marker dibatalkan.");
    }

    return 1;
}


Function:DynamicMap_Load() {
    if (!cache_num_rows()) return printf("[Dynamic Map] No map markers loaded.");

    for (new id = 0; id != cache_num_rows(); id++) if (id < MAX_DYNAMIC_MAP) {
        cache_get_value_int(id,   "id",       MapDynamicData[id][dynamicMapID]);
        cache_get_value_float(id, "x",        MapDynamicData[id][dynamicMapPos][0]);
        cache_get_value_float(id, "y",        MapDynamicData[id][dynamicMapPos][1]);
        cache_get_value_float(id, "z",        MapDynamicData[id][dynamicMapPos][2]);
        cache_get_value_float(id, "angle",    MapDynamicData[id][dynamicMapRot]);
        cache_get_value_int(id,   "world",    MapDynamicData[id][dynamicMapWorld]);
        cache_get_value_int(id,   "interior", MapDynamicData[id][dynamicMapInterior]);

        Iter_Add(DynamicMapMarkers, id);
        DynamicMap_Refresh(id);
    }

    printf("[Dynamic Map] Loaded %d map markers.", cache_num_rows());
    return 1;
}

Function:OnDynamicMapCreated(id) {
    if (!Iter_Contains(DynamicMapMarkers, id))
        return 0;

    MapDynamicData[id][dynamicMapID] = cache_insert_id();
    DynamicMap_Save(id);
    return 1;
}

DynamicMap_Save(id) {
    if (!Iter_Contains(DynamicMapMarkers, id))
        return 0;

    static query[512];
    format(query, sizeof(query),
        "UPDATE `dynamic_map` SET `x`='%f', `y`='%f', `z`='%f', `angle`='%f', `world`='%d', `interior`='%d' WHERE `id` = '%d'",
        MapDynamicData[id][dynamicMapPos][0],
        MapDynamicData[id][dynamicMapPos][1],
        MapDynamicData[id][dynamicMapPos][2],
        MapDynamicData[id][dynamicMapRot],
        MapDynamicData[id][dynamicMapWorld],
        MapDynamicData[id][dynamicMapInterior],
        MapDynamicData[id][dynamicMapID]
    );

    return mysql_tquery(g_iHandle, query);
}

DynamicMap_Refresh(id) {
    if (!Iter_Contains(DynamicMapMarkers, id))
        return 0;

    if (IsValidDynamicObject(MapDynamicData[id][dynamicMapObject]))
        DestroyDynamicObject(MapDynamicData[id][dynamicMapObject]);

    if (IsValidDynamic3DTextLabel(MapDynamicData[id][dynamicMapText3D]))
        DestroyDynamic3DTextLabel(MapDynamicData[id][dynamicMapText3D]);

    MapDynamicData[id][dynamicMapObject] = CreateDynamicObject(1444,
        MapDynamicData[id][dynamicMapPos][0],
        MapDynamicData[id][dynamicMapPos][1],
        MapDynamicData[id][dynamicMapPos][2],
        0.0, 0.0, MapDynamicData[id][dynamicMapRot],
        MapDynamicData[id][dynamicMapWorld],
        MapDynamicData[id][dynamicMapInterior]
    );

    new text[128];
    format(text, sizeof(text), "[MAP %d]\n"WHITE"Type "YELLOW"/map"WHITE" to access the map", id);

    MapDynamicData[id][dynamicMapText3D] = CreateDynamic3DTextLabel(text,
        COLOR_MAP_TEXT,
        MapDynamicData[id][dynamicMapPos][0],
        MapDynamicData[id][dynamicMapPos][1],
        MapDynamicData[id][dynamicMapPos][2] + 1.0,
        12.0,
        INVALID_PLAYER_ID,
        INVALID_VEHICLE_ID,
        1,
        MapDynamicData[id][dynamicMapWorld],
        MapDynamicData[id][dynamicMapInterior]
    );

    return 1;
}

DynamicMap_Create(Float:x, Float:y, Float:z, Float:angle, world, interior) {
    new id = Iter_Free(DynamicMapMarkers);
    if (id == INVALID_ITERATOR_SLOT)
        return INVALID_ITERATOR_SLOT;

    MapDynamicData[id][dynamicMapPos][0]   = x;
    MapDynamicData[id][dynamicMapPos][1]   = y;
    MapDynamicData[id][dynamicMapPos][2]   = z;
    MapDynamicData[id][dynamicMapRot]      = angle;
    MapDynamicData[id][dynamicMapWorld]    = world;
    MapDynamicData[id][dynamicMapInterior] = interior;

    Iter_Add(DynamicMapMarkers, id);
    DynamicMap_Refresh(id);

    static query[512];
    format(query, sizeof(query),
        "INSERT INTO `dynamic_map` (`x`,`y`,`z`,`angle`,`world`,`interior`) VALUES ('%f','%f','%f','%f','%d','%d')",
        x, y, z, angle, world, interior
    );

    mysql_tquery(g_iHandle, query, "OnDynamicMapCreated", "d", id);
    return id;
}

DynamicMap_Delete(id) {
    if (!Iter_Contains(DynamicMapMarkers, id))
        return 0;

    static query[128];
    format(query, sizeof(query), "DELETE FROM `dynamic_map` WHERE `id` = '%d'", MapDynamicData[id][dynamicMapID]);
    mysql_tquery(g_iHandle, query);

    if (IsValidDynamicObject(MapDynamicData[id][dynamicMapObject]))
        DestroyDynamicObject(MapDynamicData[id][dynamicMapObject]);

    if (IsValidDynamic3DTextLabel(MapDynamicData[id][dynamicMapText3D]))
        DestroyDynamic3DTextLabel(MapDynamicData[id][dynamicMapText3D]);

    MapDynamicData[id][dynamicMapID]     = INVALID_ITERATOR_SLOT;
    MapDynamicData[id][dynamicMapText3D] = INVALID_3DTEXT_ID;
    MapDynamicData[id][dynamicMapObject] = INVALID_STREAMER_ID;
    Iter_Remove(DynamicMapMarkers, id);
    return 1;
}

DynamicMap_Nearest(playerid, Float:range = 4.0) {
    new id = -1;
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    foreach (new i : DynamicMapMarkers) {
        if (!Iter_Contains(DynamicMapMarkers, i)) continue;
        if (IsPlayerInRangeOfPoint(playerid, range,
            MapDynamicData[i][dynamicMapPos][0],
            MapDynamicData[i][dynamicMapPos][1],
            MapDynamicData[i][dynamicMapPos][2]))
        {
            id = i;
            break;
        }
    }

    return id;
}

CMD:dynmap(playerid, params[]) {
    if (CheckAdmin(playerid, 5))
        return PermissionError(playerid);

    new action[16], input[64];
    if (sscanf(params, "s[16]", action))
        return SendSyntaxMessage(playerid, "/dynmap create | delete [id] | edit [id] | list");

    input[0] = '\0';
    sscanf(params, "s[16]s[64]", action, input);

    if (!strcmp(action, "create", true)) {
        new Float:x, Float:y, Float:z, Float:angle;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, angle);

        new id = DynamicMap_Create(x, y, z, angle,
            GetPlayerVirtualWorld(playerid),
            GetPlayerInterior(playerid)
        );

        if (id == INVALID_ITERATOR_SLOT)
            return SendErrorMessage(playerid, "Batas dynamic map tercapai (%d).", MAX_DYNAMIC_MAP);

        SendServerMessage(playerid, "Map marker dibuat (slot %d, DB id %d).", id, MapDynamicData[id][dynamicMapID]);
        return 1;
    }

    if (!strcmp(action, "edit", true)) {
        new id;
        if (sscanf(input, "d", id))
            return SendSyntaxMessage(playerid, "/dynmap edit [id]");

        if (!Iter_Contains(DynamicMapMarkers, id))
            return SendErrorMessage(playerid, "Dynamic map id %d tidak ditemukan.", id);

        if (!IsValidDynamicObject(MapDynamicData[id][dynamicMapObject]))
            return SendErrorMessage(playerid, "Objek map marker %d tidak valid.", id);

        g_EditingMap[playerid] = id;
        EditDynamicObject(playerid, MapDynamicData[id][dynamicMapObject]);
        return 1;
    }

    if (!strcmp(action, "delete", true)) {
        new id;
        if (sscanf(input, "d", id))
            return SendSyntaxMessage(playerid, "/dynmap delete [id]");

        if (!Iter_Contains(DynamicMapMarkers, id))
            return SendErrorMessage(playerid, "Dynamic map id %d tidak ditemukan.", id);

        DynamicMap_Delete(id);
        SendServerMessage(playerid, "Map marker %d dihapus.", id);
        return 1;
    }

    if (!strcmp(action, "list", true)) {
        new str[2048], strLen;
        format(str, sizeof(str), "Dynamic map markers (%d):\n", Iter_Count(DynamicMapMarkers));
        strLen = strlen(str);

        foreach (new i : DynamicMapMarkers) {
            format(str[strLen], sizeof(str) - strLen,
                "ID:%d DB:%d Pos:%.1f,%.1f,%.1f\n",
                i,
                MapDynamicData[i][dynamicMapID],
                MapDynamicData[i][dynamicMapPos][0],
                MapDynamicData[i][dynamicMapPos][1],
                MapDynamicData[i][dynamicMapPos][2]
            );
            strLen += strlen(str[strLen]);
        }

        SendClientMessage(playerid, COLOR_WHITE, str);
        return 1;
    }

    return SendSyntaxMessage(playerid, "/dynmap create | delete [id] | edit [id] | list");
}
