#include <YSI_Coding\y_hooks>
new Text: LogoCostum;

hook OnGameModeInit()
{
  AddSimpleModel(-1, 19379, -2000, "logo.dff", "logo.txd");

  LogoCostum = TextDrawCreate(293.000, -1.000, "mdl-2000:mave");
  TextDrawTextSize(LogoCostum, 58.000, 61.000);
  TextDrawAlignment(LogoCostum, 1);
  TextDrawColor(LogoCostum, -1);
  TextDrawSetShadow(LogoCostum, 0);
  TextDrawSetOutline(LogoCostum, 0);
  TextDrawBackgroundColor(LogoCostum, 255);
  TextDrawFont(LogoCostum, 4);
  TextDrawSetProportional(LogoCostum, 1);
  return 1;
}

CMD:toglogo(playerid, params[])
{
    if(PlayerData[playerid][pLogo] == 0)
    {
        PlayerData[playerid][pLogo] = 1;
        TextDrawHideForPlayer(playerid, LogoCostum);
        if(!PlayerData[playerid][pTogHud]) {
            TextDrawShowForPlayer(playerid, watermark[0]);
            TextDrawShowForPlayer(playerid, watermark[1]);
        }
        SendClientMessage(playerid, -1, "SERVER: Logo display has been {FF0000}disabled{FFFFFF}.");
    }
    else
    {
        PlayerData[playerid][pLogo] = 0;
        TextDrawHideForPlayer(playerid, watermark[0]);
        TextDrawHideForPlayer(playerid, watermark[1]);
        if(!PlayerData[playerid][pTogHud]) {
            TextDrawShowForPlayer(playerid, LogoCostum);
        }
        SendClientMessage(playerid, -1, "SERVER: Logo display has been {00FF00}enabled{FFFFFF}.");
    }
    return 1;
}
