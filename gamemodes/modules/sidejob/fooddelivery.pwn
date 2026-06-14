// defined
#define MAX_FOOD_DELIVERY_VEHICLE     3
#define FOOD_DELIVERY_WAIT_MIN        5000
#define FOOD_DELIVERY_WAIT_MAX        10000
#define FOOD_DELIVERY_MAX_ORDER       5
#define FOOD_DELIVERY_DELAY_TIME      600

#define FOOD_DELIVERY_STATE_NONE      0
#define FOOD_DELIVERY_STATE_WAITING   1
#define FOOD_DELIVERY_STATE_TO_PICKUP 2
#define FOOD_DELIVERY_STATE_STORE     3
#define FOOD_DELIVERY_STATE_TO_DROP   4
#define FOOD_DELIVERY_STATE_TAKE      5
#define FOOD_DELIVERY_STATE_DROP      6

// global variables
static foodDeliveryVehicle[MAX_FOOD_DELIVERY_VEHICLE] = {INVALID_VEHICLE_ID, ...};
new bool:DialogFDSidejob[MAX_FOOD_DELIVERY_VEHICLE];
new PlayerFDSidejob[MAX_PLAYERS];

// player variables
static bool:foodDeliveryActive[MAX_PLAYERS] = {false, ...};
static foodDeliveryState[MAX_PLAYERS];
static foodDeliveryOrderFood[MAX_PLAYERS];
static foodDeliveryOrderDrink[MAX_PLAYERS];
static foodDeliveryOrderHouse[MAX_PLAYERS];
static foodDeliveryOrderSalary[MAX_PLAYERS];
static foodDeliveryOrderCount[MAX_PLAYERS];
static Timer:foodDeliveryOrderTimer[MAX_PLAYERS];

static fdOut[MAX_PLAYERS];
static outCheckFD[MAX_PLAYERS];
static Timer:outTimerFD[MAX_PLAYERS];
static Timer:outTimeFD[MAX_PLAYERS];

static const Float:FOOD_DELIVERY_START_POS[4] = {2105.4453, -1806.5045, 13.5547, 0.0};
static const Float:FOOD_DELIVERY_PICKUP_POS[4] = {2114.5866, -1790.6954, 13.5546, 270.0};

static const FoodDeliveryFoods[][32] = {
    "Pizza Pepperoni",
    "Pizza Meat Lovers",
    "Pizza Cheese",
    "Pizza Chicken"
};

static const FoodDeliveryDrinks[][32] = {
    "Cola",
    "Sprite",
    "Ice Tea",
    "Mineral Water"
};

stock Float:FoodDelivery_GetDistance(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    return floatsqroot(floatpower(x1 - x2, 2.0) + floatpower(y1 - y2, 2.0) + floatpower(z1 - z2, 2.0));
}

stock bool:FoodDelivery_HasOtherSidejob(playerid)
{
    if (PlayerData[playerid][pBussidejob] || PlayerData[playerid][pSweepersidejob] || PlayerData[playerid][pPosmanSidejob] || PlayerData[playerid][pTrashjob])
        return true;

    return false;
}

stock FoodDelivery_StopTimers(playerid)
{
    stop foodDeliveryOrderTimer[playerid];
    return 1;
}

stock FoodDelivery_DisableCheckpoint(playerid)
{
    DisablePlayerRaceCheckpoint(playerid);
    return 1;
}

stock FoodDelivery_CleanVehicle(playerid)
{
    new slot = PlayerFDSidejob[playerid];
    if (slot != -1)
    {
        DialogFDSidejob[slot] = false;
        if (foodDeliveryVehicle[slot] != INVALID_VEHICLE_ID)
        {
            DestroyVehicle(foodDeliveryVehicle[slot]);
            foodDeliveryVehicle[slot] = INVALID_VEHICLE_ID;
        }
        PlayerFDSidejob[playerid] = -1;
    }
    return 1;
}

stock FoodDelivery_RemoveAttachments(playerid)
{
    if (IsPlayerAttachedObjectSlotUsed(playerid, 0)) RemovePlayerAttachedObject(playerid, 0);
    if (IsPlayerAttachedObjectSlotUsed(playerid, 1)) RemovePlayerAttachedObject(playerid, 1);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
    return 1;
}

stock FoodDelivery_Reset(playerid)
{
    FoodDelivery_RemoveAttachments(playerid);
    foodDeliveryActive[playerid] = false;
    foodDeliveryState[playerid] = FOOD_DELIVERY_STATE_NONE;
    foodDeliveryOrderFood[playerid] = -1;
    foodDeliveryOrderDrink[playerid] = -1;
    foodDeliveryOrderHouse[playerid] = -1;
    foodDeliveryOrderSalary[playerid] = 0;
    foodDeliveryOrderCount[playerid] = 0;
    
    outCheckFD[playerid] = 0;
    stop outTimerFD[playerid];
    stop outTimeFD[playerid];

    FoodDelivery_StopTimers(playerid);
    FoodDelivery_DisableCheckpoint(playerid);
    return 1;
}

stock FoodDelivery_Cancel(playerid, const reason[], penalty = 0)
{
    FoodDelivery_CleanVehicle(playerid);
    FoodDelivery_Reset(playerid);

    if (penalty > 0)
        SetFoodDeliveryDelay(playerid, penalty);

    if (strlen(reason))
        SendCustomMessage(playerid, "FOOD DELIVERY", "%s", reason);
    return 1;
}

stock FoodDelivery_StartWaiting(playerid)
{
    if (!foodDeliveryActive[playerid])
        return 0;

    FoodDelivery_StopTimers(playerid);
    FoodDelivery_DisableCheckpoint(playerid);
    foodDeliveryState[playerid] = FOOD_DELIVERY_STATE_WAITING;
    foodDeliveryOrderTimer[playerid] = defer FoodDelivery_RequestOrder[RandomEx(FOOD_DELIVERY_WAIT_MIN, FOOD_DELIVERY_WAIT_MAX)](playerid);
    SendCustomMessage(playerid, "FOOD DELIVERY", "Tunggu sebentar, restoran sedang menyiapkan orderan baru.");
    return 1;
}

stock FoodDelivery_GetRandomHouse()
{
    new houses[MAX_HOUSES], count = 0;

    foreach (new houseid : Houses)
    {
        houses[count++] = houseid;
    }

    if (!count)
        return -1;

    return houses[RandomEx(0, count - 1)];
}

stock FoodDelivery_ShowOrder(playerid)
{
    new info[512];
    new houseid = foodDeliveryOrderHouse[playerid];
    if (!Iter_Contains(Houses, houseid))
        return 0;

    format(info, sizeof(info), ""WHITE"Orderan baru sudah masuk.\n\n"\
        ""YELLOW"House ID: "WHITE"%d\n"\
        ""YELLOW"Alamat: "WHITE"%s\n"\
        ""YELLOW"Jarak: "WHITE"%.2f km\n"\
        ""YELLOW"Makanan: "WHITE"%s\n"\
        ""YELLOW"Minuman: "WHITE"%s\n"\
        ""YELLOW"Gaji: "GREEN"$%s\n\n"\
        ""WHITE"Terima orderan ini atau lewati ke orderan berikutnya?",
        houseid,
        HouseData[houseid][houseAddress],
        FoodDelivery_GetDistance(
            FOOD_DELIVERY_PICKUP_POS[0], FOOD_DELIVERY_PICKUP_POS[1], FOOD_DELIVERY_PICKUP_POS[2],
            HouseData[houseid][housePos][0], HouseData[houseid][housePos][1], HouseData[houseid][housePos][2]
        ) / 1000.0,
        FoodDeliveryFoods[foodDeliveryOrderFood[playerid]],
        FoodDeliveryDrinks[foodDeliveryOrderDrink[playerid]],
        FormatNumber(foodDeliveryOrderSalary[playerid])
    );

    Dialog_Show(playerid, FoodDeliveryOrder, DIALOG_STYLE_MSGBOX, "Jefferson Pizza Order", info, "Terima", "Skip");
    return 1;
}

stock FoodDelivery_GenerateOrder(playerid)
{
    new houseid = FoodDelivery_GetRandomHouse();
    if (houseid == -1)
        return 0;

    new food = RandomEx(0, sizeof(FoodDeliveryFoods) - 1);
    new drink = RandomEx(0, sizeof(FoodDeliveryDrinks) - 1);
    new Float:distance = FoodDelivery_GetDistance(
        FOOD_DELIVERY_PICKUP_POS[0], FOOD_DELIVERY_PICKUP_POS[1], FOOD_DELIVERY_PICKUP_POS[2],
        HouseData[houseid][housePos][0], HouseData[houseid][housePos][1], HouseData[houseid][housePos][2]
    );
    new salary = floatround((distance / 1000.0) * 65.0, floatround_ceil);

    if (salary < 1)
        salary = 1;

    foodDeliveryOrderHouse[playerid] = houseid;
    foodDeliveryOrderFood[playerid] = food;
    foodDeliveryOrderDrink[playerid] = drink;
    foodDeliveryOrderSalary[playerid] = salary;
    return 1;
}

timer FoodDelivery_RequestOrder[1000](playerid)
{
    if (!foodDeliveryActive[playerid] || foodDeliveryState[playerid] != FOOD_DELIVERY_STATE_WAITING)
        return 1;

    if (!FoodDelivery_GenerateOrder(playerid))
        return SendErrorMessage(playerid, "Tidak ada house yang tersedia untuk dijadikan tujuan delivery.");

    PlayerPlaySoundEx(playerid, 1056);
    FoodDelivery_ShowOrder(playerid);
    return 1;
}

IsFDVehicle(vehicleid)
{
    for(new i = 0; i < MAX_FOOD_DELIVERY_VEHICLE; i++) if(vehicleid == foodDeliveryVehicle[i] && vehicleid != INVALID_VEHICLE_ID)
        return 1;
    return 0;
}

stock FD_GetVehicleSlot(vehicleid)
{
    for (new i = 0; i < MAX_FOOD_DELIVERY_VEHICLE; i++)
    {
        if (foodDeliveryVehicle[i] == vehicleid && vehicleid != INVALID_VEHICLE_ID)
            return i;
    }
    return -1;
}

stock bool:FD_IsNearAssignedVehicle(playerid, Float:range = 3.0)
{
    new slot = PlayerFDSidejob[playerid];
    if (slot == -1) return false;
    new vehicleid = foodDeliveryVehicle[slot];
    if (vehicleid == INVALID_VEHICLE_ID) return false;

    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);
    if (IsPlayerInRangeOfPoint(playerid, range, x, y, z)) return true;
    return false;
}

// SAMP callback
#include <YSI\y_hooks>

hook OnGameModeInitEx()
{
    CreateDynamicMapIcon(FOOD_DELIVERY_START_POS[0], FOOD_DELIVERY_START_POS[1], FOOD_DELIVERY_START_POS[2], 56, -1, -1, 0);
    CreateDynamic3DTextLabel("[FOOD DELIVERY]\n"WHITE"Press "YELLOW"'H' "WHITE"to start Food Delivery", COLOR_CLIENT, FOOD_DELIVERY_START_POS[0], FOOD_DELIVERY_START_POS[1], FOOD_DELIVERY_START_POS[2] + 0.4, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1);
    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerFDSidejob[playerid] = -1;
    FoodDelivery_Reset(playerid);
    return 1;
}

hook OnPlayerSpawn(playerid)
{
    if (foodDeliveryActive[playerid])
        FoodDelivery_Cancel(playerid, "", 0);
    else
        FoodDelivery_Reset(playerid);
    return 1;
}

hook OnPlayerDisconnectEx(playerid)
{
    if (foodDeliveryActive[playerid])
        FoodDelivery_Cancel(playerid, "", 600);
    return 1;
}

hook OnVehicleSpawn(vehicleid)
{
    return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
    return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(newstate == PLAYER_STATE_DRIVER && oldstate == PLAYER_STATE_ONFOOT)
    {
        if(outCheckFD[playerid] == 1)
        {
            if(IsFDVehicle(GetPlayerLastVehicle(playerid)))
            {
                if(!GetPlayerLastVehicle(playerid))
                {
                    SendCustomMessage(playerid, "FOOD DELIVERY", "Silahkan pilih motor yang terakhir kamu naiki.");
                    RemovePlayerFromVehicle(playerid);
                    return 1;
                }
                outCheckFD[playerid] = 0;
                stop outTimerFD[playerid];
                stop outTimeFD[playerid];
            }
            return 1;
        }
    }

    if(newstate == PLAYER_STATE_ONFOOT && oldstate == PLAYER_STATE_DRIVER)
    {
        if(foodDeliveryActive[playerid])
        {
            if (IsFDVehicle(GetPlayerLastVehicle(playerid)))
            {
                if (foodDeliveryState[playerid] != FOOD_DELIVERY_STATE_TAKE && foodDeliveryState[playerid] != FOOD_DELIVERY_STATE_DROP)
                {
                    fdOut[playerid] = 25;
                    outCheckFD[playerid] = 1;
                    outTimerFD[playerid] = repeat InsideFDOut(playerid);
                    outTimeFD[playerid] = defer SetPlayerToCancelFD[25000](playerid);
                    GameTextForPlayer(playerid, sprintf("ENTER THE JOB VEHICLE~n~~y~%02d SECONDS", fdOut[playerid]), 1000, 6);
                    PlayerPlaySoundEx(playerid, 43000);
                }
            }
        }
    }
    return 1;
}

timer SetPlayerToCancelFD[1000](playerid)
{
    SetVehicleToRespawn(GetPlayerLastVehicle(playerid));
    FoodDelivery_Cancel(playerid, "Kamu gagal dan tidak tuntas menyelesaikan pekerjaan food delivery.", 600);
    return 1;
}

timer InsideFDOut[1000](playerid)
{
    fdOut[playerid]--;
    GameTextForPlayer(playerid, sprintf("ENTER THE JOB VEHICLE~n~~y~%02d SECONDS", fdOut[playerid]), 1000, 6);
    PlayerPlaySoundEx(playerid, 43000);
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if (newkeys & KEY_CTRL_BACK)
    {
        if (IsPlayerInRangeOfPoint(playerid, 2.5, FOOD_DELIVERY_START_POS[0], FOOD_DELIVERY_START_POS[1], FOOD_DELIVERY_START_POS[2]))
        {
            if (foodDeliveryActive[playerid])
                return SendErrorMessage(playerid, "Kamu sedang mengerjakan food delivery.");

            if (FoodDelivery_HasOtherSidejob(playerid))
                return SendErrorMessage(playerid, "Selesaikan sidejob kamu yang lain terlebih dahulu.");

            if (PlayerData[playerid][pMaskOn])
                return SendErrorMessage(playerid, "Disable your mask first.");

            if (GetFoodDeliveryDelay(playerid) > 0)
                return SendCustomMessage(playerid, "FOOD DELIVERY", "Kamu tidak dapat bekerja sekarang, tunggu %d menit untuk memulainya kembali.", (GetFoodDeliveryDelay(playerid) / 60));

            new str[512];
            format(str, sizeof(str), "Job Vehicle\tStatus\n");
            for (new i = 0; i < MAX_FOOD_DELIVERY_VEHICLE; i++) {
                format(str, sizeof(str), "%sJob Vehicle %d\t"GREEN"%s\n", str, i, (DialogFDSidejob[i] == true) ? (RED"Taken") : (GREEN"Available"));
            }
            Dialog_Show(playerid, SidejobFDstatus, DIALOG_STYLE_TABLIST_HEADERS, "Food Delivery Sidejob", str, "Start", "Close");
        }
    }
    return 1;
}

hook OnPlayerEnterRaceCP(playerid)
{
    if (!foodDeliveryActive[playerid])
        return 1;

    switch (foodDeliveryState[playerid])
    {
        case FOOD_DELIVERY_STATE_TO_PICKUP:
        {
            if (IsPlayerInAnyVehicle(playerid))
                return SendErrorMessage(playerid, "Turun dari kendaraan dan ketik /takeorder untuk mengambil pesanan.");

            SendCustomMessage(playerid, "FOOD DELIVERY", "Ketik /takeorder untuk mengambil pesanan.");
            return 1;
        }
        case FOOD_DELIVERY_STATE_TAKE:
        {
            SendCustomMessage(playerid, "FOOD DELIVERY", "Parkir kendaraanmu di dekat sini dan ketik /takepizza di dekat Job Vehicle.");
            return 1;
        }
        case FOOD_DELIVERY_STATE_DROP:
        {
            if (IsPlayerInAnyVehicle(playerid))
                return SendErrorMessage(playerid, "Turun dari kendaraan untuk mengantarkan pesanan.");

            SendCustomMessage(playerid, "FOOD DELIVERY", "Ketik /droppizza untuk mengantarkan pesanan ke pelanggan.");
            return 1;
        }
    }
    return 1;
}

Dialog:SidejobFDstatus(playerid, response, listitem, inputtext[]) 
{
    if (response && listitem != -1) {
        if (DialogFDSidejob[listitem] == true)
            return SendErrorMessage(playerid, "This Pizzaboy Bike has already taken by someone!");

        DialogFDSidejob[listitem] = true;
        PlayerFDSidejob[playerid] = listitem;

        // Base spawn values: 2095.7375, -1817.0128, 13.3828
        foodDeliveryVehicle[listitem] = CreateVehicle(448, 2095.7375 + (listitem * 1.5), -1817.0128, 13.3828, 87.2111, 1, 1, 500);
        ResetVehicle(foodDeliveryVehicle[listitem]);
        CoreVehicles[foodDeliveryVehicle[listitem]][vehTemporary] = true;
        SetVehicleNumberPlate(foodDeliveryVehicle[listitem], "PIZZA");
        CoreVehicles[foodDeliveryVehicle[listitem]][vehFuel] = 100.0;
        
        PutPlayerInVehicle(playerid, foodDeliveryVehicle[listitem], 0);
        SetEngineStatus(foodDeliveryVehicle[listitem], true);
        SetCameraBehindPlayer(playerid);

        Dialog_Show(playerid, FoodDeliveryJob, DIALOG_STYLE_MSGBOX, "Food Delivery Sidejob", ""WHITE"Kamu menaiki Job Vehicle.\nKamu bertugas untuk mengantar makanan ke lokasi client.\nMaksimal 5 order tiap sesi, setelah itu cooldown 10 menit.\n\nJika kamu turun dari motor terlalu lama, pekerjaan akan batal otomatis.\nPilih opsi \"Mulai\" untuk melakukan pekerjaan.", "Mulai", "Turun");
    }
    return 1;
}

Dialog:FoodDeliveryJob(playerid, response, listitem, inputtext[])
{
    if(response)
    {
        foodDeliveryActive[playerid] = true;
        foodDeliveryOrderCount[playerid] = 0;
        foodDeliveryState[playerid] = FOOD_DELIVERY_STATE_WAITING;
        SetEngineStatus(GetPlayerVehicleID(playerid), true);
        FoodDelivery_StartWaiting(playerid);
    }
    else
    {
        FoodDelivery_Cancel(playerid, "");
        RemovePlayerFromVehicle(playerid);
    }
    return 1;
}

Dialog:FoodDeliveryOrder(playerid, response, listitem, inputtext[])
{
    if (!foodDeliveryActive[playerid] || foodDeliveryState[playerid] != FOOD_DELIVERY_STATE_WAITING)
        return 1;

    if (response)
    {
        foodDeliveryState[playerid] = FOOD_DELIVERY_STATE_TO_PICKUP;
        SetPlayerRaceCheckpoint(playerid, 1, FOOD_DELIVERY_PICKUP_POS[0], FOOD_DELIVERY_PICKUP_POS[1], FOOD_DELIVERY_PICKUP_POS[2], -1.0, -1.0, -1.0, 4.0);
        SendCustomMessage(playerid, "FOOD DELIVERY", "Orderan diterima. Pergi ke samping Idlewood Restaurant untuk mengambil pesanan.");
    }
    else
    {
        SendCustomMessage(playerid, "FOOD DELIVERY", "Orderan dilewati. Tunggu orderan berikutnya.");
        FoodDelivery_StartWaiting(playerid);
    }
    return 1;
}

CMD:takeorder(playerid, params[])
{
    if (!foodDeliveryActive[playerid] || foodDeliveryState[playerid] != FOOD_DELIVERY_STATE_TO_PICKUP)
        return SendErrorMessage(playerid, "Kamu belum siap untuk mengambil pesanan.");

    if (IsPlayerInAnyVehicle(playerid))
        return SendErrorMessage(playerid, "Turun dari kendaraan untuk mengambil pesanan.");

    if (!IsPlayerInRangeOfPoint(playerid, 4.0, FOOD_DELIVERY_PICKUP_POS[0], FOOD_DELIVERY_PICKUP_POS[1], FOOD_DELIVERY_PICKUP_POS[2]))
        return SendErrorMessage(playerid, "Kamu harus berada di lokasi pengambilan pesanan (samping Idlewood Restaurant).");

    new houseid = foodDeliveryOrderHouse[playerid];
    if (!Iter_Contains(Houses, houseid))
        return SendErrorMessage(playerid, "House tujuan order ini sudah tidak valid.");

    foodDeliveryState[playerid] = FOOD_DELIVERY_STATE_STORE;
    
    SetPlayerAttachedObject(playerid, 0, 19571, 1, 0.045999, 0.233000, 0.000000, 87.699851, -176.700256, 94.999961, 1.000000, 1.000000, 1.000000, 0x0, 0x0); //19571
    SetPlayerAttachedObject(playerid, 1, 2218, 1, 0.111999, 0.495999, 0.162999, 123.799659, 52.099929, 121.499687, 0.654001, 0.672001, 0.832000, 0x0, 0x0); //2218
    ApplyAnimation(playerid, "CARRY", "null", 0.0, 0, 0, 0, 0, 0, 0);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY);
    ApplyAnimation(playerid, "CARRY", "liftup", 4.1, 0, 0, 0, 0, 0, 1);

    FoodDelivery_DisableCheckpoint(playerid);
    SendNearbyMessage(playerid, 15.0, X11_PLUM, "* %s mengambil pesanan pizza dari restoran.", ReturnName(playerid, 0, 1));
    SendCustomMessage(playerid, "FOOD DELIVERY", "Pesanan diambil, dekati Job Vehicle dan ketik /storepizza.");
    return 1;
}

CMD:storepizza(playerid, params[])
{
    if (!foodDeliveryActive[playerid] || foodDeliveryState[playerid] != FOOD_DELIVERY_STATE_STORE)
        return SendErrorMessage(playerid, "Kamu belum siap untuk menyimpan pesanan pizza.");

    if (!FD_IsNearAssignedVehicle(playerid, 3.0))
        return SendErrorMessage(playerid, "Kamu harus berada di dekat Job Vehicle-mu.");

    foodDeliveryState[playerid] = FOOD_DELIVERY_STATE_TAKE;
    FoodDelivery_RemoveAttachments(playerid);
    SendNearbyMessage(playerid, 15.0, X11_PLUM, "* %s memasukkan pesanan pizza ke dalam Job Vehicle.", ReturnName(playerid, 0, 1));
    
    new houseid = foodDeliveryOrderHouse[playerid];
    SetPlayerRaceCheckpoint(playerid, 1,
        HouseData[houseid][housePos][0],
        HouseData[houseid][housePos][1],
        HouseData[houseid][housePos][2],
        -1.0, -1.0, -1.0, 4.0
    );
    SendCustomMessage(playerid, "FOOD DELIVERY", "Pesanan disimpan. Antar ke house ID %d, parkir kendaraan di dekat lokasi lalu ketik /takepizza.", houseid);
    return 1;
}

CMD:takepizza(playerid, params[])
{
    if (!foodDeliveryActive[playerid] || foodDeliveryState[playerid] != FOOD_DELIVERY_STATE_TAKE)
        return SendErrorMessage(playerid, "Kamu belum siap untuk mengambil pizza dari kendaraan.");

    if (IsPlayerInAnyVehicle(playerid))
        return SendErrorMessage(playerid, "Turun dari kendaraan terlebih dahulu.");

    if (!FD_IsNearAssignedVehicle(playerid, 3.0))
        return SendErrorMessage(playerid, "Kamu harus berada di dekat Job Vehicle-mu.");

    foodDeliveryState[playerid] = FOOD_DELIVERY_STATE_DROP;
    
    SetPlayerAttachedObject(playerid, 0, 19571, 1, 0.045999, 0.233000, 0.000000, 87.699851, -176.700256, 94.999961, 1.000000, 1.000000, 1.000000, 0x0, 0x0); //19571
    SetPlayerAttachedObject(playerid, 1, 2218, 1, 0.111999, 0.495999, 0.162999, 123.799659, 52.099929, 121.499687, 0.654001, 0.672001, 0.832000, 0x0, 0x0); //2218
    ApplyAnimation(playerid, "CARRY", "null", 0.0, 0, 0, 0, 0, 0, 0);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY);
    ApplyAnimation(playerid, "CARRY", "liftup", 4.1, 0, 0, 0, 0, 0, 1);
    
    new houseid = foodDeliveryOrderHouse[playerid];
    FoodDelivery_DisableCheckpoint(playerid);
    SetPlayerRaceCheckpoint(playerid, 1,
        HouseData[houseid][housePos][0],
        HouseData[houseid][housePos][1],
        HouseData[houseid][housePos][2],
        -1.0, -1.0, -1.0, 4.0
    );

    SendNearbyMessage(playerid, 15.0, X11_PLUM, "* %s mengambil pesanan pizza dari dalam Job Vehicle.", ReturnName(playerid, 0, 1));
    SendCustomMessage(playerid, "FOOD DELIVERY", "Pizza diambil. Pergi ke pintu rumah tujuan dan ketik /droppizza.");
    return 1;
}

CMD:droppizza(playerid, params[])
{
    if (!foodDeliveryActive[playerid] || foodDeliveryState[playerid] != FOOD_DELIVERY_STATE_DROP)
        return SendErrorMessage(playerid, "Kamu belum mengambil pizza dari kendaraan.");

    new houseid = foodDeliveryOrderHouse[playerid];
    if (!Iter_Contains(Houses, houseid))
        return SendErrorMessage(playerid, "House tujuan order ini sudah tidak valid.");

    if (!IsPlayerInRangeOfPoint(playerid, 3.0, HouseData[houseid][housePos][0], HouseData[houseid][housePos][1], HouseData[houseid][housePos][2]))
        return SendErrorMessage(playerid, "Kamu harus berada di dekat pintu rumah tujuan.");

    FoodDelivery_RemoveAttachments(playerid);
    SendNearbyMessage(playerid, 15.0, X11_PLUM, "* %s memberikan kotak pesanan pizza kepada pelanggan.", ReturnName(playerid, 0, 1));

    new salary = foodDeliveryOrderSalary[playerid];
    foodDeliveryOrderCount[playerid]++;
    AddPlayerSalary(playerid, salary, "Food Delivery Sidejob");
    SendCustomMessage(playerid, "FOOD DELIVERY", "Pesanan berhasil diantar. Kamu menerima upah "COL_GREEN"$%s "WHITE"(%d/%d order).", FormatNumber(salary), foodDeliveryOrderCount[playerid], FOOD_DELIVERY_MAX_ORDER);
    PlayerPlaySoundEx(playerid, 1056);

    if (foodDeliveryOrderCount[playerid] >= FOOD_DELIVERY_MAX_ORDER)
    {
        FoodDelivery_Cancel(playerid, "Kamu telah menyelesaikan 5 order. Food delivery selesai, tunggu 10 menit untuk memulai lagi.", FOOD_DELIVERY_DELAY_TIME);
    }
    else
    {
        FoodDelivery_StartWaiting(playerid);
    }
    return 1;
}
