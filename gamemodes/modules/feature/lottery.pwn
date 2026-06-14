#include <YSI_Coding\y_hooks>

#define MIN_BET         100
#define MAX_BET         50000
#define TIME_BETWEEN_NUMBERS 2000
#define DEFAULT_JACKPOT 1000000
#define JACKPOT_MULTIPLIER 3
#define FILE_PATH       "LotteryJackpot.ini"
#define HELP_DIALOG     28503

new Float:RM[11] =
{
    0.0,
    0.5,
    1.0,
    2.0,
    4.0,
    8.0,
    16.0,
    32.0,
    64.0,
    128.0,
};

new PlayerText:TD[MAX_PLAYERS][100];
new PlayerText:TDHeader[MAX_PLAYERS];
new PlayerText:TDPrize[MAX_PLAYERS][2];
new PrizeString[MAX_PLAYERS][2][128];
new PlayerText:TDBet[MAX_PLAYERS];
new PlayerText:TDNumber[MAX_PLAYERS];
new PlayerText:TDDots[MAX_PLAYERS][10];
new PlayerText:TDError[MAX_PLAYERS];
new Text:gTD[34];
new Text:TDLowerBet;
new Text:TDRaiseBet;
new Text:TDStart;
new Text:TDClose;
new bool:TDSelected[MAX_PLAYERS][100];
new bool:AreTDCreated[MAX_PLAYERS];
new bool:AreDotsCreated[MAX_PLAYERS];
new Jackpot;
new RandomNumbersTimer[MAX_PLAYERS];
new LotteryTimer[MAX_PLAYERS];
new LotteryBet[MAX_PLAYERS];
new LotteryStage[MAX_PLAYERS];
new SelectedNumbers[MAX_PLAYERS];
new RandomNumbersCount[MAX_PLAYERS];
new LotteryNumbers[MAX_PLAYERS][10];
new LotteryNumbersPicked[MAX_PLAYERS];
new Lot[MAX_PLAYERS][10];
new Matches[MAX_PLAYERS];

stock Lottery_GetFreeSlot(playerid)
{
    for(new i; i < 10; i++)
        if(Lot[playerid][i] == -1) return i;
    return -1;
}

stock Lottery_FindSlot(playerid, number)
{
    for(new i; i < 10; i++)
        if(Lot[playerid][i] == number) return i;
    return -1;
}

stock Lottery_HideTD(playerid)
{
    for(new i; i < sizeof(gTD); i++)
        TextDrawHideForPlayer(playerid, gTD[i]);

    for(new i; i < 100; i++)
        PlayerTextDrawHide(playerid, TD[playerid][i]);

    if(AreDotsCreated[playerid])
    {
        for(new i; i < 10; i++)
            PlayerTextDrawDestroy(playerid, TDDots[playerid][i]);
        AreDotsCreated[playerid] = false;
    }

    new b = LotteryBet[playerid];
    PlayerTextDrawHide(playerid, TDPrize[playerid][0]);
    PlayerTextDrawHide(playerid, TDPrize[playerid][1]);
    format(PrizeString[playerid][0], 128, "01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
    format(PrizeString[playerid][1], 128, "$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
    PlayerTextDrawSetString(playerid, TDPrize[playerid][0], PrizeString[playerid][0]);
    PlayerTextDrawSetString(playerid, TDPrize[playerid][1], PrizeString[playerid][1]);
    PlayerTextDrawHide(playerid, TDNumber[playerid]);
    PlayerTextDrawSetString(playerid, TDNumber[playerid], "  ");
    PlayerTextDrawHide(playerid, TDBet[playerid]);
    PlayerTextDrawHide(playerid, TDHeader[playerid]);
    TextDrawHideForPlayer(playerid, TDLowerBet);
    TextDrawHideForPlayer(playerid, TDRaiseBet);
    TextDrawHideForPlayer(playerid, TDStart);
    TextDrawHideForPlayer(playerid, TDClose);
    LotteryStage[playerid] = -1;
    PlayerPlaySound(playerid, 1184, 0.0, 0.0, 0.0);
}

stock Lottery_CreatePlayerTD(playerid)
{
    new str[5], Float:X = 267.0, Float:Y = 200.0, count;
    for(new i; i < 10; i++)
    {
        X = 267.0;
        for(new j; j < 10; j++)
        {
            format(str, sizeof(str), "%02d", count);
            TD[playerid][count] = CreatePlayerTextDraw(playerid, X, Y, str);
            PlayerTextDrawAlignment(playerid, TD[playerid][count], 2);
            PlayerTextDrawBackgroundColor(playerid, TD[playerid][count], 255);
            PlayerTextDrawFont(playerid, TD[playerid][count], 1);
            PlayerTextDrawLetterSize(playerid, TD[playerid][count], 0.220000, 1.200000);
            PlayerTextDrawColor(playerid, TD[playerid][count], 0xD1D1D1FF);
            PlayerTextDrawSetOutline(playerid, TD[playerid][count], 1);
            PlayerTextDrawSetProportional(playerid, TD[playerid][count], 1);
            PlayerTextDrawSetShadow(playerid, TD[playerid][count], 1);
            PlayerTextDrawUseBox(playerid, TD[playerid][count], 1);
            PlayerTextDrawBoxColor(playerid, TD[playerid][count], 0);
            PlayerTextDrawTextSize(playerid, TD[playerid][count], 8.000000, 10.000000);
            PlayerTextDrawSetSelectable(playerid, TD[playerid][count], 1);
            X = floatadd(X, 16.0);
            count++;
        }
        Y = floatadd(Y, 16.0);
    }

    TDPrize[playerid][0] = CreatePlayerTextDraw(playerid, 259.000000, 150.000000, "01: $000~n~02: $000~n~03: $000~n~04: $000~n~05: $000");
    PlayerTextDrawBackgroundColor(playerid, TDPrize[playerid][0], 255);
    PlayerTextDrawFont(playerid, TDPrize[playerid][0], 1);
    PlayerTextDrawLetterSize(playerid, TDPrize[playerid][0], 0.230000, 0.95);
    PlayerTextDrawColor(playerid, TDPrize[playerid][0], 0xF2E4CEFF);
    PlayerTextDrawSetOutline(playerid, TDPrize[playerid][0], 0);
    PlayerTextDrawSetProportional(playerid, TDPrize[playerid][0], 0);
    PlayerTextDrawSetShadow(playerid, TDPrize[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, TDPrize[playerid][0], 0);

    TDPrize[playerid][1] = CreatePlayerTextDraw(playerid, 418.000000, 150.000000, "$000 :06 ~n~$000 :07 ~n~$000 :08 ~n~$000 :09 ~n~$000 :10");
    PlayerTextDrawAlignment(playerid, TDPrize[playerid][1], 3);
    PlayerTextDrawBackgroundColor(playerid, TDPrize[playerid][1], 255);
    PlayerTextDrawFont(playerid, TDPrize[playerid][1], 1);
    PlayerTextDrawLetterSize(playerid, TDPrize[playerid][1], 0.230000, 0.95);
    PlayerTextDrawColor(playerid, TDPrize[playerid][1], 0xF2E4CEFF);
    PlayerTextDrawSetOutline(playerid, TDPrize[playerid][1], 0);
    PlayerTextDrawSetProportional(playerid, TDPrize[playerid][1], 0);
    PlayerTextDrawSetShadow(playerid, TDPrize[playerid][1], 1);
    PlayerTextDrawSetSelectable(playerid, TDPrize[playerid][1], 0);

    TDBet[playerid] = CreatePlayerTextDraw(playerid, 340.000000, 150.000000, "$0000");
    PlayerTextDrawAlignment(playerid, TDBet[playerid], 2);
    PlayerTextDrawBackgroundColor(playerid, TDBet[playerid], 255);
    PlayerTextDrawFont(playerid, TDBet[playerid], 1);
    PlayerTextDrawLetterSize(playerid, TDBet[playerid], 0.230000, 1.000000);
    PlayerTextDrawColor(playerid, TDBet[playerid], -173980929);
    PlayerTextDrawSetOutline(playerid, TDBet[playerid], 0);
    PlayerTextDrawSetProportional(playerid, TDBet[playerid], 1);
    PlayerTextDrawSetShadow(playerid, TDBet[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, TDBet[playerid], 0);

    TDNumber[playerid] = CreatePlayerTextDraw(playerid, 340.000000, 167.000000, "  ");
    PlayerTextDrawAlignment(playerid, TDNumber[playerid], 2);
    PlayerTextDrawBackgroundColor(playerid, TDNumber[playerid], 255);
    PlayerTextDrawFont(playerid, TDNumber[playerid], 1);
    PlayerTextDrawLetterSize(playerid, TDNumber[playerid], 0.549999, 2.199999);
    PlayerTextDrawColor(playerid, TDNumber[playerid], -1);
    PlayerTextDrawSetOutline(playerid, TDNumber[playerid], 1);
    PlayerTextDrawSetProportional(playerid, TDNumber[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, TDNumber[playerid], 0);

    TDHeader[playerid] = CreatePlayerTextDraw(playerid, 340.000000, 104.000000, "Lottery");
    PlayerTextDrawAlignment(playerid, TDHeader[playerid], 2);
    PlayerTextDrawBackgroundColor(playerid, TDHeader[playerid], 255);
    PlayerTextDrawFont(playerid, TDHeader[playerid], 0);
    PlayerTextDrawLetterSize(playerid, TDHeader[playerid], 0.910000, 3.000000);
    PlayerTextDrawColor(playerid, TDHeader[playerid], 0xF2E4CEFF);
    PlayerTextDrawSetOutline(playerid, TDHeader[playerid], 1);
    PlayerTextDrawSetProportional(playerid, TDHeader[playerid], 1);
    PlayerTextDrawSetShadow(playerid, TDHeader[playerid], 1);

    TDError[playerid] = CreatePlayerTextDraw(playerid, 340.000000, 107.000000, "~r~[Error] ~n~~w~You have already selected ~r~10 ~w~numbers!~n~Press ~g~PLAY ~w~to start!");
    PlayerTextDrawAlignment(playerid, TDError[playerid], 2);
    PlayerTextDrawBackgroundColor(playerid, TDError[playerid], 255);
    PlayerTextDrawFont(playerid, TDError[playerid], 1);
    PlayerTextDrawLetterSize(playerid, TDError[playerid], 0.200000, 1.100000);
    PlayerTextDrawColor(playerid, TDError[playerid], -1);
    PlayerTextDrawSetOutline(playerid, TDError[playerid], 1);
    PlayerTextDrawSetProportional(playerid, TDError[playerid], 1);
    PlayerTextDrawSetSelectable(playerid, TDError[playerid], 0);

    AreTDCreated[playerid] = true;
}

stock Lottery_CreateGlobalTD()
{
    new count, Float:X = 259.0, Float:Y = 199.0;

    gTD[count] = TextDrawCreate(339.000000, 107.000000, "~n~");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.759999, 27.700000);
    TextDrawColor(gTD[count], -1);
    TextDrawSetOutline(gTD[count], 0);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawSetShadow(gTD[count], 1);
    TextDrawUseBox(gTD[count], 1);
    TextDrawBoxColor(gTD[count], 120);
    TextDrawTextSize(gTD[count], 124.000000, 159.000000);
    TextDrawSetSelectable(gTD[count], 0);
    count++;

    gTD[count] = TextDrawCreate(339.000000, 108.000000, "~n~");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.500000, 3.099999);
    TextDrawColor(gTD[count], 0xB5FFF6FF);
    TextDrawSetOutline(gTD[count], 0);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawSetShadow(gTD[count], 1);
    TextDrawUseBox(gTD[count], 1);
    TextDrawBoxColor(gTD[count], 0xB5FFF655);
    TextDrawTextSize(gTD[count], 40.000000, -170.000000);
    TextDrawSetSelectable(gTD[count], 0);
    count++;

    gTD[count] = TextDrawCreate(257.000000, 107.000000, "~n~");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.500000, 27.799999);
    TextDrawColor(gTD[count], -1);
    TextDrawSetOutline(gTD[count], 0);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawSetShadow(gTD[count], 1);
    TextDrawUseBox(gTD[count], 1);
    TextDrawBoxColor(gTD[count], 255);
    TextDrawTextSize(gTD[count], 30.000000, -1.000000);
    TextDrawSetSelectable(gTD[count], 0);
    count++;

    gTD[count] = TextDrawCreate(421.000000, 107.000000, "~n~");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.500000, 27.799999);
    TextDrawColor(gTD[count], -1);
    TextDrawSetOutline(gTD[count], 0);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawSetShadow(gTD[count], 1);
    TextDrawUseBox(gTD[count], 1);
    TextDrawBoxColor(gTD[count], 255);
    TextDrawTextSize(gTD[count], 30.000000, -1.000000);
    TextDrawSetSelectable(gTD[count], 0);
    count++;

    gTD[count] = TextDrawCreate(339.000000, 104.000000, "~n~");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.500000, -0.000000);
    TextDrawColor(gTD[count], -1);
    TextDrawSetOutline(gTD[count], 0);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawSetShadow(gTD[count], 1);
    TextDrawUseBox(gTD[count], 1);
    TextDrawBoxColor(gTD[count], 255);
    TextDrawTextSize(gTD[count], 40.000000, -170.000000);
    TextDrawSetSelectable(gTD[count], 0);
    count++;

    gTD[count] = TextDrawCreate(339.000000, 359.000000, "~n~");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.500000, -0.000000);
    TextDrawColor(gTD[count], -1);
    TextDrawSetOutline(gTD[count], 0);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawSetShadow(gTD[count], 1);
    TextDrawUseBox(gTD[count], 1);
    TextDrawBoxColor(gTD[count], 255);
    TextDrawTextSize(gTD[count], 40.000000, -170.000000);
    TextDrawSetSelectable(gTD[count], 0);
    count++;

    gTD[count] = TextDrawCreate(313.500000, 150.000000, "ld_beat:chit");
    TextDrawLetterSize(gTD[count], 0.000000, 0.000000);
    TextDrawTextSize(gTD[count], 53.0, 58.0);
    TextDrawAlignment(gTD[count], 2);
    TextDrawColor(gTD[count], 255);
    TextDrawSetShadow(gTD[count], 2);
    TextDrawSetOutline(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 0x00000000);
    TextDrawFont(gTD[count], 4);
    count++;

    gTD[count] = TextDrawCreate(317.500000, 154.000000, "ld_beat:chit");
    TextDrawLetterSize(gTD[count], 0.000000, 0.000000);
    TextDrawTextSize(gTD[count], 45.0, 50.0);
    TextDrawAlignment(gTD[count], 2);
    TextDrawColor(gTD[count], 0xB1FAC0FF);
    TextDrawSetShadow(gTD[count], 2);
    TextDrawSetOutline(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 0x00000000);
    TextDrawFont(gTD[count], 4);
    count++;

    gTD[count] = TextDrawCreate(259.000000, 143.000000, "Matches / Prize:");
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.139999, 0.699999);
    TextDrawColor(gTD[count], 0xB1FAC0FF);
    TextDrawSetOutline(gTD[count], 0);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawSetShadow(gTD[count], 1);
    TextDrawSetSelectable(gTD[count], 0);
    count++;

    gTD[count] = TextDrawCreate(340.000000, 139.000000, "BET");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.290000, 1.000000);
    TextDrawColor(gTD[count], 0xB1FAC0FF);
    TextDrawSetOutline(gTD[count], 0);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawSetShadow(gTD[count], 1);
    TextDrawSetSelectable(gTD[count], 0);
    count++;

    gTD[count] = TextDrawCreate(268.000000, 129.000000, "Reset");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.170000, 0.899999);
    TextDrawColor(gTD[count], -16776961);
    TextDrawSetOutline(gTD[count], 1);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawUseBox(gTD[count], 1);
    TextDrawBoxColor(gTD[count], 0);
    TextDrawTextSize(gTD[count], 10.000000, 30.000000);
    TextDrawSetSelectable(gTD[count], 1);
    count++;

    gTD[count] = TextDrawCreate(411.000000, 129.000000, "Help");
    TextDrawAlignment(gTD[count], 2);
    TextDrawBackgroundColor(gTD[count], 255);
    TextDrawFont(gTD[count], 1);
    TextDrawLetterSize(gTD[count], 0.170000, 0.899999);
    TextDrawColor(gTD[count], 16777215);
    TextDrawSetOutline(gTD[count], 1);
    TextDrawSetProportional(gTD[count], 1);
    TextDrawUseBox(gTD[count], 1);
    TextDrawBoxColor(gTD[count], 0);
    TextDrawTextSize(gTD[count], 10.000000, 30.000000);
    TextDrawSetSelectable(gTD[count], 1);
    count++;

    for(new i = 0; i < 11; i++)
    {
        if(i == 10) gTD[count] = TextDrawCreate((X+1), 199.000000, "~n~");
        else gTD[count] = TextDrawCreate(X, 199.000000, "~n~");
        TextDrawAlignment(gTD[count], 2);
        TextDrawBackgroundColor(gTD[count], 255);
        TextDrawFont(gTD[count], 1);
        TextDrawLetterSize(gTD[count], 0.500000, 17.399993);
        TextDrawColor(gTD[count], -1);
        TextDrawSetOutline(gTD[count], 0);
        TextDrawSetProportional(gTD[count], 1);
        TextDrawSetShadow(gTD[count], 1);
        TextDrawUseBox(gTD[count], 1);
        TextDrawBoxColor(gTD[count], 255);
        TextDrawTextSize(gTD[count], 1.000000, -2.000000);
        X = floatadd(X, 16.0);
        count++;
    }

    for(new i = 0; i < 11; i++)
    {
        gTD[count] = TextDrawCreate(340.000000, Y, "~n~");
        TextDrawAlignment(gTD[count], 2);
        TextDrawBackgroundColor(gTD[count], 255);
        TextDrawFont(gTD[count], 1);
        TextDrawLetterSize(gTD[count], 0.500000, -0.300006);
        TextDrawColor(gTD[count], -1);
        TextDrawSetOutline(gTD[count], 0);
        TextDrawSetProportional(gTD[count], 1);
        TextDrawSetShadow(gTD[count], 1);
        TextDrawUseBox(gTD[count], 1);
        TextDrawBoxColor(gTD[count], 255);
        TextDrawTextSize(gTD[count], 61.000000, 158.000000);
        TextDrawSetSelectable(gTD[count], 0);
        Y = floatadd(Y, 16.0);
        count++;
    }

    TDLowerBet = TextDrawCreate(326.000000, 136.000000, "<");
    TextDrawAlignment(TDLowerBet, 2);
    TextDrawBackgroundColor(TDLowerBet, 255);
    TextDrawFont(TDLowerBet, 1);
    TextDrawLetterSize(TDLowerBet, 0.329999, 1.600000);
    TextDrawColor(TDLowerBet, -1);
    TextDrawSetOutline(TDLowerBet, 1);
    TextDrawSetProportional(TDLowerBet, 1);
    TextDrawUseBox(TDLowerBet, 1);
    TextDrawBoxColor(TDLowerBet, 0);
    TextDrawTextSize(TDLowerBet, 15.000000, 20.000000);
    TextDrawSetSelectable(TDLowerBet, 1);

    TDRaiseBet = TextDrawCreate(354.000000, 136.000000, ">");
    TextDrawAlignment(TDRaiseBet, 2);
    TextDrawBackgroundColor(TDRaiseBet, 255);
    TextDrawFont(TDRaiseBet, 1);
    TextDrawLetterSize(TDRaiseBet, 0.329999, 1.600000);
    TextDrawColor(TDRaiseBet, -1);
    TextDrawSetOutline(TDRaiseBet, 1);
    TextDrawSetProportional(TDRaiseBet, 1);
    TextDrawUseBox(TDRaiseBet, 1);
    TextDrawBoxColor(TDRaiseBet, 0);
    TextDrawTextSize(TDRaiseBet, 15.000000, 20.000000);
    TextDrawSetSelectable(TDRaiseBet, 1);

    TDStart = TextDrawCreate(292.000000, 365.000000, "PLAY");
    TextDrawAlignment(TDStart, 2);
    TextDrawBackgroundColor(TDStart, 255);
    TextDrawFont(TDStart, 1);
    TextDrawLetterSize(TDStart, 0.509999, 2.100000);
    TextDrawColor(TDStart, 0xB1FAC0FF);
    TextDrawSetOutline(TDStart, 1);
    TextDrawSetProportional(TDStart, 1);
    TextDrawUseBox(TDStart, 1);
    TextDrawBoxColor(TDStart, 0);
    TextDrawTextSize(TDStart, 53.000000, 50.000000);
    TextDrawSetSelectable(TDStart, 1);

    TDClose = TextDrawCreate(381.000000, 365.000000, "CLOSE");
    TextDrawAlignment(TDClose, 2);
    TextDrawBackgroundColor(TDClose, 255);
    TextDrawFont(TDClose, 1);
    TextDrawLetterSize(TDClose, 0.509999, 2.100000);
    TextDrawColor(TDClose, 0xFF9696FF);
    TextDrawSetOutline(TDClose, 1);
    TextDrawSetProportional(TDClose, 1);
    TextDrawUseBox(TDClose, 1);
    TextDrawBoxColor(TDClose, 0);
    TextDrawTextSize(TDClose, 53.000000, 50.000000);
    TextDrawSetSelectable(TDClose, 1);
}

hook OnGameModeInitEx()
{
    Lottery_CreateGlobalTD();
    for(new i; i < MAX_PLAYERS; i++)
    {
        LotteryStage[i] = -1;
        if(IsPlayerConnected(i))
        {
            for(new j; j < 10; j++)
            {
                LotteryNumbers[i][j] = -1;
                Lot[i][j] = -1;
            }
            LotteryBet[i] = MIN_BET;
            Lottery_CreatePlayerTD(i);
            LotteryNumbersPicked[i] = 0;
        }
    }

    new File:file;
    if(!fexist(FILE_PATH))
    {
        file = fopen(FILE_PATH, io_write);
        new str[12];
        format(str, 12, "%d", DEFAULT_JACKPOT);
        fwrite(file, str);
        fclose(file);
        Jackpot = DEFAULT_JACKPOT;
    }
    else
    {
        file = fopen(FILE_PATH, io_read);
        new str[12];
        while(fread(file, str))
            Jackpot = strval(str);
        fclose(file);
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    LotteryStage[playerid] = -1;
    LotteryBet[playerid] = MIN_BET;
    SelectedNumbers[playerid] = 0;
    RandomNumbersCount[playerid] = 0;
    LotteryNumbersPicked[playerid] = 0;
    for(new j; j < 10; j++)
    {
        LotteryNumbers[playerid][j] = -1;
        Lot[playerid][j] = -1;
    }
    Lottery_CreatePlayerTD(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if(AreTDCreated[playerid])
    {
        for(new i; i < 100; i++)
            PlayerTextDrawDestroy(playerid, TD[playerid][i]);
        for(new j; j < 10; j++)
            PlayerTextDrawDestroy(playerid, TDDots[playerid][j]);
        PlayerTextDrawDestroy(playerid, TDPrize[playerid][0]);
        PlayerTextDrawDestroy(playerid, TDPrize[playerid][1]);
        PlayerTextDrawDestroy(playerid, TDBet[playerid]);
        PlayerTextDrawDestroy(playerid, TDNumber[playerid]);
        PlayerTextDrawDestroy(playerid, TDHeader[playerid]);
        PlayerTextDrawDestroy(playerid, TDError[playerid]);
        AreTDCreated[playerid] = false;
    }
    return 1;
}

stock Lottery_ClickPlayerTD(playerid, PlayerText:playertextid)
{
    if(LotteryStage[playerid] == 0)
    {
        if(AreDotsCreated[playerid])
        {
            for(new i; i < 10; i++)
                PlayerTextDrawDestroy(playerid, TDDots[playerid][i]);
            AreDotsCreated[playerid] = false;
            PlayerTextDrawHide(playerid, TDHeader[playerid]);
            PlayerTextDrawSetString(playerid, TDHeader[playerid], "~w~Lottery");
            PlayerTextDrawShow(playerid, TDHeader[playerid]);
            PlayerTextDrawHide(playerid, TDPrize[playerid][0]);
            PlayerTextDrawHide(playerid, TDPrize[playerid][1]);
            new b = LotteryBet[playerid];
            format(PrizeString[playerid][0], 128, "01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
            format(PrizeString[playerid][1], 128, "$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
            PlayerTextDrawSetString(playerid, TDPrize[playerid][0], PrizeString[playerid][0]);
            PlayerTextDrawSetString(playerid, TDPrize[playerid][1], PrizeString[playerid][1]);
            PlayerTextDrawShow(playerid, TDPrize[playerid][0]);
            PlayerTextDrawShow(playerid, TDPrize[playerid][1]);
            PlayerTextDrawHide(playerid, TDNumber[playerid]);
            PlayerTextDrawSetString(playerid, TDNumber[playerid], "  ");
            PlayerTextDrawShow(playerid, TDNumber[playerid]);
            PlayerPlaySound(playerid, 1184, 0.0, 0.0, 0.0);
        }

        new td;
        for(new j; j < 100; j++)
        {
            if(playertextid == TD[playerid][j])
            {
                td = j;
                break;
            }
        }

        PlayerTextDrawHide(playerid, TD[playerid][td]);
        if(!TDSelected[playerid][td])
        {
            if(SelectedNumbers[playerid] == 10)
            {
                PlayerTextDrawHide(playerid, TDHeader[playerid]);
                PlayerTextDrawHide(playerid, TDError[playerid]);
                PlayerTextDrawSetString(playerid, TDError[playerid], "~r~[Error] ~n~~w~You have already selected ~r~10 ~w~numbers!~n~Press ~g~PLAY ~w~to start!");
                PlayerTextDrawShow(playerid, TDError[playerid]);
                SetTimerEx("Lottery_HideError", 3500, 0, "i", playerid);
            }
            else
            {
                PlayerTextDrawColor(playerid, TD[playerid][td], 0x46F255FF);
                TDSelected[playerid][td] = true;
                new slot = Lottery_GetFreeSlot(playerid);
                if(slot != -1) Lot[playerid][slot] = td;
                SelectedNumbers[playerid]++;
            }
        }
        else
        {
            PlayerTextDrawColor(playerid, TD[playerid][td], 0xD1D1D1FF);
            TDSelected[playerid][td] = false;
            new slot = Lottery_FindSlot(playerid, td);
            if(slot != -1) Lot[playerid][slot] = -1;
            SelectedNumbers[playerid]--;
        }
        PlayerTextDrawShow(playerid, TD[playerid][td]);
    }
    return 1;
}

stock Lottery_OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    if((clickedid != Text:INVALID_TEXT_DRAW) && (LotteryStage[playerid] == 0))
    {
        if(AreDotsCreated[playerid])
        {
            for(new i; i < 10; i++)
                PlayerTextDrawDestroy(playerid, TDDots[playerid][i]);
            AreDotsCreated[playerid] = false;
            PlayerTextDrawHide(playerid, TDHeader[playerid]);
            PlayerTextDrawSetString(playerid, TDHeader[playerid], "~w~Lottery");
            PlayerTextDrawShow(playerid, TDHeader[playerid]);
            PlayerTextDrawHide(playerid, TDPrize[playerid][0]);
            PlayerTextDrawHide(playerid, TDPrize[playerid][1]);
            new b = LotteryBet[playerid];
            format(PrizeString[playerid][0], 128, "01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
            format(PrizeString[playerid][1], 128, "$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
            PlayerTextDrawSetString(playerid, TDPrize[playerid][0], PrizeString[playerid][0]);
            PlayerTextDrawSetString(playerid, TDPrize[playerid][1], PrizeString[playerid][1]);
            PlayerTextDrawShow(playerid, TDPrize[playerid][0]);
            PlayerTextDrawShow(playerid, TDPrize[playerid][1]);
            PlayerTextDrawHide(playerid, TDNumber[playerid]);
            PlayerTextDrawSetString(playerid, TDNumber[playerid], "  ");
            PlayerTextDrawShow(playerid, TDNumber[playerid]);
            PlayerPlaySound(playerid, 1184, 0.0, 0.0, 0.0);
        }

        if(clickedid == TDLowerBet)
        {
            if(LotteryBet[playerid] > MIN_BET)
            {
                new str[8];
                LotteryBet[playerid] -= 100;
                format(str, sizeof(str), "$%d", LotteryBet[playerid]);
                PlayerTextDrawHide(playerid, TDBet[playerid]);
                PlayerTextDrawSetString(playerid, TDBet[playerid], str);
                PlayerTextDrawShow(playerid, TDBet[playerid]);
                new b = LotteryBet[playerid];
                format(PrizeString[playerid][0], 128, "01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
                format(PrizeString[playerid][1], 128, "$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
                PlayerTextDrawSetString(playerid, TDPrize[playerid][0], PrizeString[playerid][0]);
                PlayerTextDrawSetString(playerid, TDPrize[playerid][1], PrizeString[playerid][1]);
                PlayerTextDrawShow(playerid, TDPrize[playerid][0]);
                PlayerTextDrawShow(playerid, TDPrize[playerid][1]);
            }
        }

        if(clickedid == TDRaiseBet)
        {
            if(LotteryBet[playerid] < MAX_BET)
            {
                new str[8];
                LotteryBet[playerid] += 100;
                format(str, sizeof(str), "$%d", LotteryBet[playerid]);
                PlayerTextDrawHide(playerid, TDBet[playerid]);
                PlayerTextDrawSetString(playerid, TDBet[playerid], str);
                PlayerTextDrawShow(playerid, TDBet[playerid]);
                new b = LotteryBet[playerid];
                format(PrizeString[playerid][0], 128, "01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
                format(PrizeString[playerid][1], 128, "$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
                PlayerTextDrawSetString(playerid, TDPrize[playerid][0], PrizeString[playerid][0]);
                PlayerTextDrawSetString(playerid, TDPrize[playerid][1], PrizeString[playerid][1]);
                PlayerTextDrawShow(playerid, TDPrize[playerid][0]);
                PlayerTextDrawShow(playerid, TDPrize[playerid][1]);
            }
        }

        if(clickedid == TDStart)
        {
            if(SelectedNumbers[playerid] != 10)
            {
                PlayerTextDrawHide(playerid, TDHeader[playerid]);
                PlayerTextDrawHide(playerid, TDError[playerid]);
                PlayerTextDrawSetString(playerid, TDError[playerid], "~r~[Error] ~n~~w~You first have to select ~r~10 ~w~numbers!");
                PlayerTextDrawShow(playerid, TDError[playerid]);
                SetTimerEx("Lottery_HideError", 3500, 0, "i", playerid);
            }
            else if(PlayerData[playerid][pMoney] < LotteryBet[playerid])
            {
                PlayerTextDrawHide(playerid, TDHeader[playerid]);
                PlayerTextDrawHide(playerid, TDError[playerid]);
                PlayerTextDrawSetString(playerid, TDError[playerid], "~r~[Error] ~n~~w~You do not have enough money.");
                PlayerTextDrawShow(playerid, TDError[playerid]);
                SetTimerEx("Lottery_HideError", 3500, 0, "i", playerid);
            }
            else
            {
                PlayerData[playerid][pMoney] -= LotteryBet[playerid];
                Jackpot += (LotteryBet[playerid] * JACKPOT_MULTIPLIER);
                new File:file;
                if(fexist(FILE_PATH))
                {
                    file = fopen(FILE_PATH, io_write);
                    new str[12];
                    format(str, 12, "%d", Jackpot);
                    fwrite(file, str);
                    fclose(file);
                }
                LotteryStage[playerid] = 1;
                LotteryTimer[playerid] = SetTimerEx("Lottery_Main", 50, 0, "i", playerid);
                CancelSelectTextDraw(playerid);
                TogglePlayerControllable(playerid, 0);
                RandomNumbersCount[playerid] = 0;
            }
        }

        if(clickedid == TDClose)
        {
            Lottery_HideTD(playerid);
            TogglePlayerControllable(playerid, 1);
            CancelSelectTextDraw(playerid);
        }

        if(clickedid == gTD[10])
        {
            LotteryBet[playerid] = MIN_BET;
            new b = LotteryBet[playerid];
            format(PrizeString[playerid][0], 128, "01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
            format(PrizeString[playerid][1], 128, "$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
            PlayerTextDrawSetString(playerid, TDPrize[playerid][0], PrizeString[playerid][0]);
            PlayerTextDrawSetString(playerid, TDPrize[playerid][1], PrizeString[playerid][1]);
            PlayerTextDrawShow(playerid, TDPrize[playerid][0]);
            PlayerTextDrawShow(playerid, TDPrize[playerid][1]);
            new str[8];
            format(str, sizeof(str), "$%d", LotteryBet[playerid]);
            PlayerTextDrawHide(playerid, TDBet[playerid]);
            PlayerTextDrawSetString(playerid, TDBet[playerid], str);
            PlayerTextDrawShow(playerid, TDBet[playerid]);
            SelectedNumbers[playerid] = 0;
            for(new i; i < 10; i++) Lot[playerid][i] = -1;
            for(new i; i < 100; i++)
            {
                PlayerTextDrawHide(playerid, TD[playerid][i]);
                PlayerTextDrawColor(playerid, TD[playerid][i], 0xD1D1D1FF);
                PlayerTextDrawShow(playerid, TD[playerid][i]);
                TDSelected[playerid][i] = false;
            }
        }

        if(clickedid == gTD[11])
        {
            new string[800], string2[300];
            format(string2, sizeof(string2), "\n\nYour selected numbers and bet will be remembered and you can\npress the {FF0000}reset{FFFFFF}-button to restore your game to default settings.\n\nMatch all 10 numbers to win the {FFE882}JACKPOT {FFFFFF}of {FFE882}$%d!\n\n\n\t\t{FFE882}GOOD LUCK!", Jackpot);
            format(string, sizeof(string), "{FFFFFF}Welcome to the {9BDB76}Lottery Game! \n\n{FFFFFF}To play this game you have to \nselect {E36B73}10 numbers {FFFFFF}of your choise and {E36B73}set your bet.\n{FFFFFF}You can lower/raise your bet by clicking the arrows({E36B73} <  > {FFFFFF})\n\nWhen you are ready, press the {B1FAC0}'PLAY' {FFFFFF}button to start. \n10 random numbers will be drawn and you will\nreceive a prize depending on the amount of matches and your bet.%s", string2);
            ShowPlayerDialog(playerid, HELP_DIALOG, DIALOG_STYLE_MSGBOX, "Lottery Help", string, "OK", "");
        }
    }

    if((clickedid == Text:INVALID_TEXT_DRAW) && (LotteryStage[playerid] == 0))
    {
        Lottery_HideTD(playerid);
        TogglePlayerControllable(playerid, 1);
    }
    return 1;
}

CMD:lottery(playerid, params[])
{
    if(LotteryStage[playerid] != -1)
        return SendCustomMessage(playerid, "LOTTERY", "You are already playing!");

    LotteryStage[playerid] = 0;
    new b = LotteryBet[playerid];
    format(PrizeString[playerid][0], 128, "01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
    format(PrizeString[playerid][1], 128, "$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
    PlayerTextDrawSetString(playerid, TDPrize[playerid][0], PrizeString[playerid][0]);
    PlayerTextDrawSetString(playerid, TDPrize[playerid][1], PrizeString[playerid][1]);
    for(new i; i < sizeof(gTD); i++) TextDrawShowForPlayer(playerid, gTD[i]);
    for(new i; i < 100; i++) PlayerTextDrawShow(playerid, TD[playerid][i]);
    PlayerTextDrawShow(playerid, TDPrize[playerid][0]);
    PlayerTextDrawShow(playerid, TDPrize[playerid][1]);
    PlayerTextDrawShow(playerid, TDNumber[playerid]);
    PlayerTextDrawShow(playerid, TDHeader[playerid]);
    TextDrawShowForPlayer(playerid, TDLowerBet);
    TextDrawShowForPlayer(playerid, TDRaiseBet);
    TextDrawShowForPlayer(playerid, TDStart);
    TextDrawShowForPlayer(playerid, TDClose);
    new str[8];
    format(str, sizeof(str), "$%d", LotteryBet[playerid]);
    PlayerTextDrawSetString(playerid, TDBet[playerid], str);
    PlayerTextDrawShow(playerid, TDBet[playerid]);
    SelectTextDraw(playerid, 0xFF4040AA);
    return 1;
}

forward Lottery_Main(playerid);
public Lottery_Main(playerid)
{
    switch(LotteryStage[playerid])
    {
        case 1:
        {
            RandomNumbersTimer[playerid] = SetTimerEx("Lottery_ShowRandomNumbers", 50, 1, "i", playerid);
        }
        case 2:
        {
            new Draw = LotteryNumbersPicked[playerid];
            new bool:found, bool:taken, number;
            while(!found)
            {
                taken = false;
                number = random(100);
                for(new i; i < 10; i++)
                    if(number == LotteryNumbers[playerid][i]) taken = true;
                if(!taken) { LotteryNumbers[playerid][Draw] = number; found = true; }
            }

            new str[5], Float:X = 258.0, Float:Y = 189.0;
            format(str, 5, "%02d", number);
            PlayerTextDrawHide(playerid, TDNumber[playerid]);
            PlayerTextDrawSetString(playerid, TDNumber[playerid], str);
            PlayerTextDrawShow(playerid, TDNumber[playerid]);

            new bool:match;
            for(new i; i < 10; i++)
                if(Lot[playerid][i] == number) { Matches[playerid]++; match = true; }

            new horizontal;
            for(new c; c < number; c++)
            {
                X = floatadd(X, 16.0);
                horizontal++;
                if(horizontal == 10) { horizontal = 0; X = 258.0; Y = floatadd(Y, 16.0); }
            }

            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);
            if(match) PlayerPlaySound(playerid, 1057, x, y, z);
            else PlayerPlaySound(playerid, 1085, x, y, z);

            TDDots[playerid][Draw] = CreatePlayerTextDraw(playerid, X, Y, "O");
            PlayerTextDrawBackgroundColor(playerid, TDDots[playerid][Draw], 255);
            PlayerTextDrawFont(playerid, TDDots[playerid][Draw], 2);
            PlayerTextDrawLetterSize(playerid, TDDots[playerid][Draw], 0.650000, 3.400000);
            if(match) PlayerTextDrawColor(playerid, TDDots[playerid][Draw], 0x7DFA2AFF);
            else PlayerTextDrawColor(playerid, TDDots[playerid][Draw], 0xB3D69CFF);
            PlayerTextDrawSetOutline(playerid, TDDots[playerid][Draw], 0);
            PlayerTextDrawSetProportional(playerid, TDDots[playerid][Draw], 1);
            PlayerTextDrawSetShadow(playerid, TDDots[playerid][Draw], 1);
            PlayerTextDrawSetSelectable(playerid, TDDots[playerid][Draw], 0);
            PlayerTextDrawShow(playerid, TDDots[playerid][Draw]);

            new b = LotteryBet[playerid];
            switch(Matches[playerid])
            {
                case 0: format(PrizeString[playerid][0], 128, "~w~01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
                case 1: format(PrizeString[playerid][0], 128, "~r~01: $%d~n~~w~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
                case 2: format(PrizeString[playerid][0], 128, "~w~01: $%d~n~~r~02: $%d~n~~w~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
                case 3: format(PrizeString[playerid][0], 128, "~w~01: $%d~n~02: $%d~n~~r~03: $%d~n~~w~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
                case 4: format(PrizeString[playerid][0], 128, "~w~01: $%d~n~02: $%d~n~03: $%d~n~~r~04: $%d~n~~w~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
                case 5: format(PrizeString[playerid][0], 128, "~w~01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~~r~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
                case 6: format(PrizeString[playerid][1], 128, "~r~$%d :06 ~n~~w~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
                case 7: format(PrizeString[playerid][1], 128, "~w~$%d :06 ~n~~r~$%d :07 ~n~~w~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
                case 8: format(PrizeString[playerid][1], 128, "~w~$%d :06 ~n~$%d :07 ~n~~r~$%d :08 ~n~~w~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
                case 9: format(PrizeString[playerid][1], 128, "~w~$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~~r~$%d :09 ~n~~w~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
                case 10: format(PrizeString[playerid][1], 128, "~w~$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~~r~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
            }
            switch(Matches[playerid])
            {
                case 0..5: format(PrizeString[playerid][1], 128, "~w~$%d :06 ~n~$%d :07 ~n~$%d :08 ~n~$%d :09 ~n~$%d :10", floatround(b*RM[6]), floatround(b*RM[7]), floatround(b*RM[8]), floatround(b*RM[9]), Jackpot);
                case 6..10: format(PrizeString[playerid][0], 128, "~w~01: $%d~n~02: $%d~n~03: $%d~n~04: $%d~n~05: $%d", floatround(b*RM[1]), floatround(b*RM[2]), floatround(b*RM[3]), floatround(b*RM[4]), floatround(b*RM[5]));
            }
            PlayerTextDrawHide(playerid, TDPrize[playerid][0]);
            PlayerTextDrawHide(playerid, TDPrize[playerid][1]);
            PlayerTextDrawSetString(playerid, TDPrize[playerid][0], PrizeString[playerid][0]);
            PlayerTextDrawSetString(playerid, TDPrize[playerid][1], PrizeString[playerid][1]);
            PlayerTextDrawShow(playerid, TDPrize[playerid][0]);
            PlayerTextDrawShow(playerid, TDPrize[playerid][1]);

            Draw++;
            if(Draw == 10)
            {
                AreDotsCreated[playerid] = true;
                LotteryStage[playerid] = 3;
                LotteryTimer[playerid] = SetTimerEx("Lottery_Main", 400, 0, "i", playerid);
            }
            else
            {
                LotteryNumbersPicked[playerid]++;
                LotteryStage[playerid] = 1;
                LotteryTimer[playerid] = SetTimerEx("Lottery_Main", TIME_BETWEEN_NUMBERS, 0, "i", playerid);
            }
        }
        case 3:
        {
            switch(Matches[playerid])
            {
                case 0:
                {
                    SendCustomMessage(playerid, "LOTTERY", "Sorry, you do not have any matches. Better luck next time!");
                    PlayerTextDrawHide(playerid, TDHeader[playerid]);
                    PlayerTextDrawSetString(playerid, TDHeader[playerid], "~r~Loser!");
                    PlayerTextDrawShow(playerid, TDHeader[playerid]);
                }
                case 1..9:
                {
                    new prize = floatround(LotteryBet[playerid] * RM[Matches[playerid]]);
                    PlayerData[playerid][pMoney] += prize;
                    SendCustomMessage(playerid, "LOTTERY", "Congratulations! You got %d match(es) and won $%d!", Matches[playerid], prize);
                    PlayerTextDrawHide(playerid, TDHeader[playerid]);
                    PlayerTextDrawSetString(playerid, TDHeader[playerid], "~w~Winner!");
                    PlayerTextDrawShow(playerid, TDHeader[playerid]);
                }
                case 10:
                {
                    PlayerTextDrawHide(playerid, TDHeader[playerid]);
                    PlayerTextDrawSetString(playerid, TDHeader[playerid], "~w~Jackpot!!");
                    PlayerTextDrawShow(playerid, TDHeader[playerid]);

                    PlayerData[playerid][pMoney] += Jackpot;
                    SendCustomMessage(playerid, "LOTTERY", "Congratulations! You won the JACKPOT of $%d!", Jackpot);

                    new pName[MAX_PLAYER_NAME], str[128];
                    GetPlayerName(playerid, pName, sizeof(pName));
                    format(str, sizeof(str), "%s has won the JACKPOT of $%d! Congratulations!", pName, Jackpot);
                    SendClientMessageToAll(-1, str);

                    new Float:x, Float:y, Float:z;
                    GetPlayerPos(playerid, x, y, z);
                    PlayerPlaySound(playerid, 1183, x, y, z);

                    new File:file, string[12];
                    file = fopen(FILE_PATH, io_write);
                    format(string, 12, "%d", DEFAULT_JACKPOT);
                    fwrite(file, string);
                    fclose(file);
                    Jackpot = DEFAULT_JACKPOT;
                }
            }
            LotteryNumbersPicked[playerid] = 0;
            LotteryStage[playerid] = 0;
            Matches[playerid] = 0;
            SelectTextDraw(playerid, 0xFF4040AA);
            TogglePlayerControllable(playerid, 1);
        }
    }
    return 1;
}

forward Lottery_ShowRandomNumbers(playerid);
public Lottery_ShowRandomNumbers(playerid)
{
    new str[5];
    format(str, 5, "%02d", random(100));
    PlayerTextDrawHide(playerid, TDNumber[playerid]);
    PlayerTextDrawSetString(playerid, TDNumber[playerid], str);
    PlayerTextDrawShow(playerid, TDNumber[playerid]);
    RandomNumbersCount[playerid]++;
    if(RandomNumbersCount[playerid] == 20)
    {
        KillTimer(RandomNumbersTimer[playerid]);
        RandomNumbersCount[playerid] = 0;
        LotteryStage[playerid] = 2;
        Lottery_Main(playerid);
    }
    return 1;
}

forward Lottery_HideError(playerid);
public Lottery_HideError(playerid)
{
    PlayerTextDrawHide(playerid, TDError[playerid]);
    PlayerTextDrawShow(playerid, TDHeader[playerid]);
    return 1;
}
