#include <YSI_Coding\y_hooks>

#define MAX_ROULETTE_TABLES 50

new PlayerText:SlotMachines[MAX_PLAYERS][26];

new RouletteBetAmount[MAX_PLAYERS];
new RouletteChosenNumber[MAX_PLAYERS];
new bool:IsPlayingRoulette[MAX_PLAYERS];

new RouletteBets[] = { 10, 50, 100, 500, 1000, 5000 };

enum E_ROULETTE_TABLE {
    bool:rtExists,
    Float:rtPos[3],
    rtInterior,
    rtWorld,
    rtPickup,
    Text3D:rtLabel
};
new RouletteTableData[MAX_ROULETTE_TABLES][E_ROULETTE_TABLE];
new RouletteTableCount;

hook OnPlayerConnect(playerid)
{
    RouletteBetAmount[playerid] = 50;
    RouletteChosenNumber[playerid] = 0;
    IsPlayingRoulette[playerid] = false;

    SlotMachines[playerid][0] = CreatePlayerTextDraw(playerid, 479.000, 189.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][0], 115.000, 124.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][0], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][0], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][0], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][0], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][0], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][0], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][0], 1);

    SlotMachines[playerid][1] = CreatePlayerTextDraw(playerid, 479.000, 316.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][1], 115.000, 24.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][1], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][1], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][1], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][1], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][1], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][1], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][1], 1);
    PlayerTextDrawSetSelectable(playerid, SlotMachines[playerid][1], 1);

    SlotMachines[playerid][2] = CreatePlayerTextDraw(playerid, 479.000, 346.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][2], 116.000, 24.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][2], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][2], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][2], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][2], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][2], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][2], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][2], 1);
    PlayerTextDrawSetSelectable(playerid, SlotMachines[playerid][2], 1);

    SlotMachines[playerid][3] = CreatePlayerTextDraw(playerid, 437.000, 254.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][3], 38.000, 58.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][3], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][3], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][3], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][3], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][3], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][3], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][3], 1);

    SlotMachines[playerid][4] = CreatePlayerTextDraw(playerid, 437.000, 314.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][4], 38.000, 58.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][4], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][4], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][4], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][4], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][4], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][4], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][4], 1);

    SlotMachines[playerid][5] = CreatePlayerTextDraw(playerid, 393.000, 314.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][5], 38.000, 58.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][5], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][5], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][5], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][5], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][5], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][5], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][5], 1);

    SlotMachines[playerid][6] = CreatePlayerTextDraw(playerid, 393.000, 253.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][6], 38.000, 58.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][6], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][6], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][6], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][6], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][6], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][6], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][6], 1);

    SlotMachines[playerid][7] = CreatePlayerTextDraw(playerid, 349.000, 253.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][7], 38.000, 58.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][7], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][7], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][7], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][7], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][7], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][7], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][7], 1);

    SlotMachines[playerid][8] = CreatePlayerTextDraw(playerid, 349.000, 314.000, "LD_SPAC:white");
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][8], 38.000, 58.000);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][8], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][8], 255);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][8], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][8], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][8], 255);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][8], 4);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][8], 1);

    SlotMachines[playerid][9] = CreatePlayerTextDraw(playerid, 504.000, 173.000, "Roulette Wheels");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][9], 0.300, 2.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][9], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][9], -1);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][9], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][9], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][9], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][9], 0);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][9], 1);

    SlotMachines[playerid][10] = CreatePlayerTextDraw(playerid, 504.000, 217.000, "chips:");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][10], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][10], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][10], -1);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][10], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][10], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][10], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][10], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][10], 1);

    SlotMachines[playerid][11] = CreatePlayerTextDraw(playerid, 537.000, 217.000, "$0");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][11], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][11], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][11], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][11], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][11], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][11], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][11], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][11], 1);

    SlotMachines[playerid][12] = CreatePlayerTextDraw(playerid, 511.000, 236.000, "bet:");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][12], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][12], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][12], -1);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][12], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][12], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][12], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][12], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][12], 1);

    SlotMachines[playerid][13] = CreatePlayerTextDraw(playerid, 537.000, 236.000, "$50");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][13], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][13], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][13], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][13], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][13], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][13], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][13], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][13], 1);

    SlotMachines[playerid][14] = CreatePlayerTextDraw(playerid, 490.000, 275.000, "winnner:");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][14], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][14], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][14], -1);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][14], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][14], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][14], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][14], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][14], 1);

    SlotMachines[playerid][15] = CreatePlayerTextDraw(playerid, 539.000, 275.000, "$00.00");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][15], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][15], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][15], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][15], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][15], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][15], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][15], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][15], 1);

    SlotMachines[playerid][16] = CreatePlayerTextDraw(playerid, 482.000, 296.000, "You've Selected number:");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][16], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][16], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][16], -1);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][16], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][16], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][16], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][16], 1);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][16], 1);

    SlotMachines[playerid][17] = CreatePlayerTextDraw(playerid, 584.000, 297.000, "0");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][17], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][17], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][17], -2686721);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][17], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][17], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][17], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][17], 1);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][17], 1);
    PlayerTextDrawTextSize(playerid, SlotMachines[playerid][17], 600.000, 15.000);
    PlayerTextDrawSetSelectable(playerid, SlotMachines[playerid][17], 1);

    SlotMachines[playerid][18] = CreatePlayerTextDraw(playerid, 492.000, 319.000, "Change the bet here!");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][18], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][18], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][18], -1);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][18], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][18], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][18], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][18], 1);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][18], 1);

    SlotMachines[playerid][19] = CreatePlayerTextDraw(playerid, 525.000, 350.000, "Start");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][19], 0.300, 1.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][19], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][19], -1);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][19], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][19], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][19], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][19], 1);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][19], 1);

    SlotMachines[playerid][20] = CreatePlayerTextDraw(playerid, 447.000, 330.000, "$12");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][20], 0.299, 2.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][20], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][20], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][20], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][20], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][20], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][20], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][20], 1);

    SlotMachines[playerid][21] = CreatePlayerTextDraw(playerid, 449.000, 269.000, "$6");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][21], 0.299, 2.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][21], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][21], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][21], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][21], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][21], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][21], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][21], 1);

    SlotMachines[playerid][22] = CreatePlayerTextDraw(playerid, 406.000, 269.000, "$4");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][22], 0.299, 2.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][22], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][22], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][22], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][22], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][22], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][22], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][22], 1);

    SlotMachines[playerid][23] = CreatePlayerTextDraw(playerid, 362.000, 269.000, "$2");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][23], 0.299, 2.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][23], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][23], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][23], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][23], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][23], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][23], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][23], 1);

    SlotMachines[playerid][24] = CreatePlayerTextDraw(playerid, 403.000, 331.000, "$10");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][24], 0.299, 2.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][24], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][24], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][24], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][24], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][24], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][24], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][24], 1);

    SlotMachines[playerid][25] = CreatePlayerTextDraw(playerid, 362.000, 331.000, "$8");
    PlayerTextDrawLetterSize(playerid, SlotMachines[playerid][25], 0.299, 2.500);
    PlayerTextDrawAlignment(playerid, SlotMachines[playerid][25], 1);
    PlayerTextDrawColor(playerid, SlotMachines[playerid][25], 6553855);
    PlayerTextDrawSetShadow(playerid, SlotMachines[playerid][25], 0);
    PlayerTextDrawSetOutline(playerid, SlotMachines[playerid][25], 0);
    PlayerTextDrawBackgroundColor(playerid, SlotMachines[playerid][25], 150);
    PlayerTextDrawFont(playerid, SlotMachines[playerid][25], 3);
    PlayerTextDrawSetProportional(playerid, SlotMachines[playerid][25], 1);

    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    IsPlayingRoulette[playerid] = false;
    for(new i = 0; i < 26; i++)
    {
        if(SlotMachines[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawDestroy(playerid, SlotMachines[playerid][i]);
            SlotMachines[playerid][i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_YES)
    {
        if(!IsPlayingRoulette[playerid])
        {
            for(new i = 0; i < MAX_ROULETTE_TABLES; i++)
            {
                if(!RouletteTableData[i][rtExists]) continue;
                if(GetPlayerInterior(playerid) != RouletteTableData[i][rtInterior]) continue;
                if(GetPlayerVirtualWorld(playerid) != RouletteTableData[i][rtWorld]) continue;
                if(IsPlayerInRangeOfPoint(playerid, 3.0, RouletteTableData[i][rtPos][0], RouletteTableData[i][rtPos][1], RouletteTableData[i][rtPos][2]))
                {
                    ShowRouletteSlot(playerid);
                    break;
                }
            }
        }
    }
    return 1;
}

CMD:createroulette(playerid, params[])
{
    if(CheckAdmin(playerid, 7))
        return PermissionError(playerid);

    new id = -1;
    for(new i = 0; i < MAX_ROULETTE_TABLES; i++)
    {
        if(!RouletteTableData[i][rtExists]) { id = i; break; }
    }
    if(id == -1)
        return SendErrorMessage(playerid, "Server telah mencapai batas maksimum roulette table.");

    GetPlayerPos(playerid, RouletteTableData[id][rtPos][0], RouletteTableData[id][rtPos][1], RouletteTableData[id][rtPos][2]);
    RouletteTableData[id][rtInterior] = GetPlayerInterior(playerid);
    RouletteTableData[id][rtWorld] = GetPlayerVirtualWorld(playerid);
    RouletteTableData[id][rtExists] = true;

    RouletteTableData[id][rtPickup] = CreateDynamicPickup(1936, 1, RouletteTableData[id][rtPos][0], RouletteTableData[id][rtPos][1], RouletteTableData[id][rtPos][2], RouletteTableData[id][rtWorld], RouletteTableData[id][rtInterior]);
    RouletteTableData[id][rtLabel] = CreateDynamic3DTextLabel("[Roulette Table]\nPress '{FFFF00}Y{FFFFFF}' to play", -1, RouletteTableData[id][rtPos][0], RouletteTableData[id][rtPos][1], RouletteTableData[id][rtPos][2] + 0.5, 5.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, RouletteTableData[id][rtWorld], RouletteTableData[id][rtInterior]);

    RouletteTableCount++;
    SendServerMessage(playerid, "Roulette table berhasil dibuat. ID: %d", id);
    return 1;
}

CMD:createroullete(playerid, params[]) { return cmd_createroulette(playerid, params); }
CMD:addroulette(playerid, params[]) { return cmd_createroulette(playerid, params); }

CMD:deleteroulette(playerid, params[])
{
    if(CheckAdmin(playerid, 7))
        return PermissionError(playerid);

    new id;
    if(sscanf(params, "d", id))
        return SendSyntaxMessage(playerid, "/deleteroulette [id]");

    if(id < 0 || id >= MAX_ROULETTE_TABLES || !RouletteTableData[id][rtExists])
        return SendErrorMessage(playerid, "ID roulette table tidak valid.");

    if(IsValidDynamicPickup(RouletteTableData[id][rtPickup]))
        DestroyDynamicPickup(RouletteTableData[id][rtPickup]);
    if(IsValidDynamic3DTextLabel(RouletteTableData[id][rtLabel]))
        DestroyDynamic3DTextLabel(RouletteTableData[id][rtLabel]);

    RouletteTableData[id][rtExists] = false;
    RouletteTableCount--;
    SendServerMessage(playerid, "Roulette table ID %d berhasil dihapus.", id);
    return 1;
}

CMD:deleteroullete(playerid, params[]) { return cmd_deleteroulette(playerid, params); }
CMD:removeroulette(playerid, params[]) { return cmd_deleteroulette(playerid, params); }

// Using shortened hook name to prevent truncation warning
hook OPClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(IsPlayingRoulette[playerid])
    {
        if(playertextid == SlotMachines[playerid][1]) // Change bet
        {
            new idx = 0;
            for(new i = 0; i < sizeof(RouletteBets); i++) {
                if(RouletteBetAmount[playerid] == RouletteBets[i]) {
                    idx = i + 1;
                    break;
                }
            }
            if(idx >= sizeof(RouletteBets)) idx = 0;
            RouletteBetAmount[playerid] = RouletteBets[idx];
            
            new str[32];
            format(str, sizeof(str), "$%d", RouletteBetAmount[playerid]);
            PlayerTextDrawSetString(playerid, SlotMachines[playerid][13], str);
            PlayerPlaySoundEx(playerid, 1083);
            return 1;
        }
        else if(playertextid == SlotMachines[playerid][17]) // Change number
        {
            Dialog_Show(playerid, RouletteNumber, DIALOG_STYLE_INPUT, "Roulette Number", "Please enter the number you want to bet on (0 - 36):", "Select", "Cancel");
            return 1;
        }
        else if(playertextid == SlotMachines[playerid][2]) // Start game
        {
            new bet = RouletteBetAmount[playerid];
            new playerMoney = GetPlayerMoney(playerid);
            if(playerMoney < bet)
            {
                SendClientMessage(playerid, -1, "{FF0000}[Roulette] {FFFFFF}You do not have enough money to make this bet!");
                return 1;
            }
            
            GivePlayerMoney(playerid, -bet);
            
            new resultNum = random(37); // 0 to 36
            new str[64];
            
            if(resultNum == RouletteChosenNumber[playerid])
            {
                new payout = bet * 35;
                GivePlayerMoney(playerid, payout);
                format(str, sizeof(str), "$%d", payout);
                PlayerTextDrawSetString(playerid, SlotMachines[playerid][15], str);
                
                format(str, sizeof(str), "{00FF00}[Roulette] {FFFFFF}Roulette rolled %d! You won $%d!", resultNum, payout);
                SendClientMessage(playerid, -1, str);
                PlayerPlaySoundEx(playerid, 1098);
            }
            else
            {
                PlayerTextDrawSetString(playerid, SlotMachines[playerid][15], "$0");
                
                format(str, sizeof(str), "{FF0000}[Roulette] {FFFFFF}Roulette rolled %d! You lost your bet.", resultNum);
                SendClientMessage(playerid, -1, str);
                PlayerPlaySoundEx(playerid, 1053);
            }
            
            // Update money display
            format(str, sizeof(str), "$%d", GetPlayerMoney(playerid));
            PlayerTextDrawSetString(playerid, SlotMachines[playerid][11], str);
            return 1;
        }
    }
    return 0; // Did not handle
}

hook OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if(IsPlayingRoulette[playerid] && clickedid == Text:INVALID_TEXT_DRAW)
    {
        HideRouletteSlot(playerid);
        return 1;
    }
    return 0;
}

Dialog:RouletteNumber(playerid, response, listitem, inputtext[])
{
    if(response)
    {
        new num = strval(inputtext);
        if(num < 0 || num > 36)
        {
            Dialog_Show(playerid, RouletteNumber, DIALOG_STYLE_INPUT, "Roulette Number", "Invalid number!\nPlease enter a number between 0 and 36:", "Select", "Cancel");
            return 1;
        }
        RouletteChosenNumber[playerid] = num;
        new str[16];
        format(str, sizeof(str), "%d", num);
        PlayerTextDrawSetString(playerid, SlotMachines[playerid][17], str);
        PlayerPlaySoundEx(playerid, 1083);
    }
    return 1;
}

stock ShowRouletteSlot(playerid)
{
    IsPlayingRoulette[playerid] = true;
    
    // Update displays before showing
    new str[32];
    format(str, sizeof(str), "$%d", GetPlayerMoney(playerid));
    PlayerTextDrawSetString(playerid, SlotMachines[playerid][11], str); // Chips/Money
    
    format(str, sizeof(str), "$%d", RouletteBetAmount[playerid]);
    PlayerTextDrawSetString(playerid, SlotMachines[playerid][13], str); // Bet
    
    format(str, sizeof(str), "%d", RouletteChosenNumber[playerid]);
    PlayerTextDrawSetString(playerid, SlotMachines[playerid][17], str); // Chosen number
    
    PlayerTextDrawSetString(playerid, SlotMachines[playerid][15], "$0"); // Winner payout
    
    for(new i = 0; i < 26; i++)
    {
        PlayerTextDrawShow(playerid, SlotMachines[playerid][i]);
    }
    SelectTextDraw(playerid, 0xFFFFFFFF);
    return 1;
}

stock HideRouletteSlot(playerid)
{
    IsPlayingRoulette[playerid] = false;
    for(new i = 0; i < 26; i++)
    {
        PlayerTextDrawHide(playerid, SlotMachines[playerid][i]);
    }
    CancelSelectTextDraw(playerid);
    return 1;
}
