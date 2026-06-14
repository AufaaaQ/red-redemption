// Sidejob miner by AufaaaQ.

#include <YSI\y_hooks>

new Text3D:gMineLabel;
new Text3D:gMineOreLabel;
new gOreCount = 0;
new gOreTimer = -1;

#define MINE_POINT_X    2553.351074
#define MINE_POINT_Y    -956.666198
#define MINE_POINT_Z    82.658027

#define MINE_DELIVER_X  2505.156494
#define MINE_DELIVER_Y  -949.837097
#define MINE_DELIVER_Z  90.616920

static UpdateMineOreLabel()
{
    new str[128];
    if(gOreCount < 20)
        format(str, sizeof(str), "Ore Status : ~r~%d~w~/20", gOreCount);
    else
        format(str, sizeof(str), "Ore Status : ~g~%d~w~/20", gOreCount);

    UpdateDynamic3DTextLabelText(gMineOreLabel, COLOR_WHITE, str);
}

hook OnGameModeInitEx() {
    gOreCount = 0;

    CreateDynamic3DTextLabel("[Mining]\n"WHITE"Type "YELLOW"/startmine "WHITE"to begin working.", COLOR_CLIENT, MINE_POINT_X, MINE_POINT_Y, MINE_POINT_Z+0.5, 7.5, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);
    CreateDynamicPickup(1239, 23, MINE_POINT_X, MINE_POINT_Y, MINE_POINT_Z);

    new str[128];
    format(str, sizeof(str), "Ore Status : ~r~%d~w~/20", gOreCount);
    gMineOreLabel = CreateDynamic3DTextLabel(str, COLOR_WHITE, MINE_POINT_X, MINE_POINT_Y, MINE_POINT_Z-0.3, 7.5, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);

    CreateDynamic3DTextLabel("[Mining]\n"WHITE"Deliver your mining rocks at this spot.\n"YELLOW"/stopmine "WHITE"to stop working.", COLOR_CLIENT, MINE_DELIVER_X, MINE_DELIVER_Y, MINE_DELIVER_Z+0.5, 7.5, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);
    CreateDynamicPickup(1239, 23, MINE_DELIVER_X, MINE_DELIVER_Y, MINE_DELIVER_Z);

    gOreTimer = SetTimer("OreCountdown", 1000, true);
    return 1;
}

forward OreCountdown();
public OreCountdown()
{
    if(gOreCount < 20)
    {
        gOreCount++;
        UpdateMineOreLabel();
    }
    else
    {
        KillTimer(gOreTimer);
        gOreTimer = -1;
    }
    return 1;
}

CMD:startmine(playerid, params[])
{
    if(IsPlayerInAnyVehicle(playerid))
        return SendErrorMessage(playerid, "You can't use this in a vehicle.");

    if(!IsPlayerInRangeOfPoint(playerid, 3.0, MINE_POINT_X, MINE_POINT_Y, MINE_POINT_Z))
        return SendErrorMessage(playerid, "You must be near the mine.");

    if(GetMinerDelay(playerid) > 0)
        return SendErrorMessage(playerid, "You can work again in %d minutes.", GetMinerDelay(playerid)/5);

    if(PlayerData[playerid][pMining])
        return SendErrorMessage(playerid, "You are already mining.");

    if(ServerData[cargoStock][0] >= MAX_STOCK)
        return SendErrorMessage(playerid, "The cargo stock is full.");

    if(gOreCount < 20)
        return SendErrorMessage(playerid, "Ore is not ready yet. Status: %d/20.", gOreCount);

    PlayerData[playerid][pMining] = true;
    PlayerData[playerid][pMineCount] = 0;

    SetPlayerAttachedObject(playerid, JOB_SLOT, 18634, 6, 0.156547, 0.039423, 0.026570, 198.109115, 6.364907, 262.997558, 1.000000, 1.000000, 1.000000);

    SendCustomMessage(playerid, "MINER", "You have started your mining job. Use /mine to dig rocks.");
    return 1;
}

CMD:mine(playerid, params[])
{
    if(!PlayerData[playerid][pMining])
        return SendErrorMessage(playerid, "You must /startmine first before mining.");

    if(IsPlayerInAnyVehicle(playerid))
        return SendErrorMessage(playerid, "You can't use this in a vehicle.");

    if(!IsPlayerInRangeOfPoint(playerid, 3.0, MINE_POINT_X, MINE_POINT_Y, MINE_POINT_Z))
        return SendErrorMessage(playerid, "You must be near the mine.");

    if(ServerData[cargoStock][0] >= MAX_STOCK)
        return SendErrorMessage(playerid, "The cargo stock is full.");

    PlayerData[playerid][pMiner]++;
    PlayerData[playerid][pMineCount]++;

    SendCustomMessage(playerid, "MINER", "You dug a rock. Total rocks: %d.", PlayerData[playerid][pMineCount]);
    return 1;
}

CMD:stopmine(playerid, params[])
{
    if(!PlayerData[playerid][pMining])
        return SendErrorMessage(playerid, "You are not currently mining.");

    if(!IsPlayerInRangeOfPoint(playerid, 3.0, MINE_DELIVER_X, MINE_DELIVER_Y, MINE_DELIVER_Z))
        return SendErrorMessage(playerid, "You must be at the delivery point to stop mining.");

    PlayerData[playerid][pMining] = false;
    SetMinerDelay(playerid, 300);

    RemovePlayerAttachedObject(playerid, JOB_SLOT);

    gOreCount = 0;
    UpdateMineOreLabel();
    if(gOreTimer != -1) KillTimer(gOreTimer);
    gOreTimer = SetTimer("OreCountdown", 1000, true);

    if(PlayerData[playerid][pMiner] <= 0)
    {
        PlayerData[playerid][pMineCount] = 0;
        PlayerData[playerid][pMiner] = 0;
        return SendCustomMessage(playerid, "MINER", "You stopped mining without collecting any rocks.");
    }

    new bonus = RandomEx(130, 250);
    AddPlayerSalary(playerid, (PlayerData[playerid][pMiner] * 250) + bonus, "Miner Sidejob + Bonus");

    SendCustomMessage(playerid, "MINER", "You have finished mining. Salary has been added.");

    PlayerData[playerid][pMineCount] = 0;
    PlayerData[playerid][pMiner] = 0;
    return 1;
}