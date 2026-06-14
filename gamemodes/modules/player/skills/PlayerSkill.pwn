#include <YSI_Coding\y_hooks>

// ============================================================
//  JOB SKILL - MECHANIC
// ============================================================

#define MAX_SKILL_XP_MECHA  300
#define SKILL_XP_PER_REPAIR 20

#define IsMechaSkillMax(%0) (PlayerData[%0][pSkillMecha] >= MAX_SKILL_XP_MECHA)

stock GiveMechaSkillXP(playerid, xp = SKILL_XP_PER_REPAIR)
{
    PlayerData[playerid][pSkillMecha] = clamp(PlayerData[playerid][pSkillMecha] + xp, 0, MAX_SKILL_XP_MECHA);

    if(IsMechaSkillMax(playerid))
        SendClientMessage(playerid, 0xFFD700FF, "{FFD700}[SKILL MAX] {FFFFFF}Skill Mechanic kamu sudah MAX! Kamu kini bisa menggunakan full mechanic menu di mana saja.");

    SavePlayerSkill(playerid);
}

stock SavePlayerSkill(playerid)
{
    new query[128];
    mysql_format(g_iHandle, query, sizeof(query),
        "UPDATE `characters` SET `SkillMecha`=%d WHERE `id`=%d",
        PlayerData[playerid][pSkillMecha], PlayerData[playerid][pID]);
    mysql_tquery(g_iHandle, query);
}

stock BuildSkillBar(xp, max, bars = 6)
{
    new bar[64], filled;
    filled = xp * bars / max;
    bar[0] = EOS;
    strcat(bar, "{00FF00}");
    for(new i = 0; i < filled; i++) strcat(bar, "|||");
    strcat(bar, "{FFFFFF}");
    for(new i = filled; i < bars; i++) strcat(bar, "|||");
    return bar;
}

forward OnRepairVehicleSuccess(playerid, type);
public OnRepairVehicleSuccess(playerid, type)
{
    if(type == REPAIR_ENGINE || type == REPAIR_TIRES)
        GiveMechaSkillXP(playerid);
    return 1;
}

// ============================================================
//  WEAPON SKILL
// ============================================================

#define MAX_TARGETS 6
#define TARGET_HIT 1584

#define WEAPON_EXP_PER_TRAINING 25
#define WEAPON_EXP_MAX 100

#define TRAIN_PLAYER_X 292.2252
#define TRAIN_PLAYER_Y -25.6839
#define TRAIN_PLAYER_Z 1001.5156
#define TRAIN_PLAYER_A 180.0

#define TRAIN_DURATION 60
#define TRAIN_INTERIOR 1
#define TRAIN_VW_BASE 1000

new Float:TargetSpeed[MAX_PLAYERS][MAX_TARGETS];
new TargetDirection[MAX_PLAYERS][MAX_TARGETS];
new Float:TargetMaxX[MAX_PLAYERS][MAX_TARGETS];
new Float:TargetMinX[MAX_PLAYERS][MAX_TARGETS];

new PlayerText:tdTrainBg[MAX_PLAYERS];
new PlayerText:tdTrainTitle[MAX_PLAYERS];
new PlayerText:tdTrainTimer[MAX_PLAYERS];
new PlayerText:tdTrainScore[MAX_PLAYERS];
new gTrainCountdown[MAX_PLAYERS];
new gTrainCountdownTimer[MAX_PLAYERS];

enum e_ptrain
{
    bool:ptActive,
    ptHits,
    ptTarget,
    ptWeapon,
    ptTimer,
    ptIndex,
    ptCanHit,
    ptTargets[MAX_TARGETS],
    ptHitCount,
    ptMoveTimer
};
new PlayerTraining[MAX_PLAYERS][e_ptrain];

enum eTrainingWeapon
{
    twWeaponId,
    twAmmo
};

new Float:TargetPos[MAX_TARGETS][4] =
{
    {298.3929,-7.6998,1001.5156,179.3},
    {292.4379,-11.9079,1001.5156,204.7},
    {288.4383,-15.1615,1001.5156,159.2},
    {297.6302,-18.2051,1001.5156,173.4},
    {289.7807,-7.5610,1001.5156,182.0},
    {291.3246,-18.1408,1001.5156,180.4}
};

new const TrainingWeapons[][eTrainingWeapon] =
{
    {23, 300},
    {24, 200},
    {25, 100},
    {26, 100},
    {29, 300},
    {31, 300},
    {30, 300},
    {34, 50}
};

stock WeaponSkillNames(level)
{
    static const name[][16] = {"Untrained", "Beginner", "Advanced", "Professional"};
    if(level >= 4) return name[3];
    if(level >= 3) return name[2];
    if(level >= 2) return name[1];
    return name[0];
}

stock GetWeaponSkillIndex(weaponid)
{
    switch(weaponid)
    {
        case 23: return 0;
        case 24: return 1;
        case 25: return 2;
        case 26: return 3;
        case 29: return 4;
        case 31: return 5;
        case 30: return 6;
        case 33: return 7;
    }
    return -1;
}

stock GetWeaponNameByIndex(idx, dest[], size)
{
    switch(idx)
    {
        case 0: format(dest, size, "Silenced 9mm");
        case 1: format(dest, size, "Desert Eagle");
        case 2: format(dest, size, "Shotgun");
        case 3: format(dest, size, "Sawn-Off");
        case 4: format(dest, size, "MP5");
        case 5: format(dest, size, "M4");
        case 6: format(dest, size, "AK47");
        case 7: format(dest, size, "Sniper");
        default: format(dest, size, "Unknown");
    }
    return 1;
}

stock ApplyWeaponSkillLevel(playerid)
{
    new skill;

    if     (PlayerData[playerid][WeaponSkillLevel][0] >= 4) skill = 999;
    else if(PlayerData[playerid][WeaponSkillLevel][0] >= 3) skill = 500;
    else if(PlayerData[playerid][WeaponSkillLevel][0] >= 2) skill = 200;
    else skill = 0;
    SetPlayerSkillLevel(playerid, WEAPONSKILL_PISTOL_SILENCED, skill);

    if     (PlayerData[playerid][WeaponSkillLevel][1] >= 4) skill = 999;
    else if(PlayerData[playerid][WeaponSkillLevel][1] >= 3) skill = 500;
    else if(PlayerData[playerid][WeaponSkillLevel][1] >= 2) skill = 200;
    else skill = 0;
    SetPlayerSkillLevel(playerid, WEAPONSKILL_DESERT_EAGLE, skill);

    if     (PlayerData[playerid][WeaponSkillLevel][2] >= 4) skill = 999;
    else if(PlayerData[playerid][WeaponSkillLevel][2] >= 3) skill = 500;
    else if(PlayerData[playerid][WeaponSkillLevel][2] >= 2) skill = 200;
    else skill = 0;
    SetPlayerSkillLevel(playerid, WEAPONSKILL_SHOTGUN, skill);

    if     (PlayerData[playerid][WeaponSkillLevel][3] >= 4) skill = 999;
    else if(PlayerData[playerid][WeaponSkillLevel][3] >= 3) skill = 500;
    else if(PlayerData[playerid][WeaponSkillLevel][3] >= 2) skill = 200;
    else skill = 0;
    SetPlayerSkillLevel(playerid, WEAPONSKILL_SAWNOFF_SHOTGUN, skill);

    if     (PlayerData[playerid][WeaponSkillLevel][4] >= 4) skill = 999;
    else if(PlayerData[playerid][WeaponSkillLevel][4] >= 3) skill = 500;
    else if(PlayerData[playerid][WeaponSkillLevel][4] >= 2) skill = 200;
    else skill = 0;
    SetPlayerSkillLevel(playerid, WEAPONSKILL_MP5, skill);

    if     (PlayerData[playerid][WeaponSkillLevel][5] >= 4) skill = 999;
    else if(PlayerData[playerid][WeaponSkillLevel][5] >= 3) skill = 500;
    else if(PlayerData[playerid][WeaponSkillLevel][5] >= 2) skill = 200;
    else skill = 0;
    SetPlayerSkillLevel(playerid, WEAPONSKILL_M4, skill);

    if     (PlayerData[playerid][WeaponSkillLevel][6] >= 4) skill = 999;
    else if(PlayerData[playerid][WeaponSkillLevel][6] >= 3) skill = 500;
    else if(PlayerData[playerid][WeaponSkillLevel][6] >= 2) skill = 200;
    else skill = 0;
    SetPlayerSkillLevel(playerid, WEAPONSKILL_AK47, skill);

    return 1;
}

stock AddWeaponSkillExp(playerid, weaponid, exp)
{
    new idx = GetWeaponSkillIndex(weaponid);
    if(idx == -1) return 0;

    PlayerData[playerid][WeaponSkillExp][idx] += exp;

    while(PlayerData[playerid][WeaponSkillExp][idx] >= WEAPON_EXP_MAX)
    {
        PlayerData[playerid][WeaponSkillExp][idx] -= WEAPON_EXP_MAX;
        PlayerData[playerid][WeaponSkillLevel][idx]++;

        new wname[32];
        GetWeaponNameByIndex(idx, wname, sizeof wname);
        SendCustomMessage(playerid, "TRAINING", "Skill %s leveled up to level %d!", wname, PlayerData[playerid][WeaponSkillLevel][idx]);
    }
    SaveWeaponSkill(playerid);
    ApplyWeaponSkillLevel(playerid);
    return 1;
}

stock SaveWeaponSkill(playerid)
{
    new query[512];
    format(query, sizeof(query),
        "UPDATE `characters` SET `ws_silenced_lvl`=%d,`ws_silenced_exp`=%d,`ws_deagle_lvl`=%d,`ws_deagle_exp`=%d,`ws_shotgun_lvl`=%d,`ws_shotgun_exp`=%d,`ws_sawn_lvl`=%d,`ws_sawn_exp`=%d,`ws_mp5_lvl`=%d,`ws_mp5_exp`=%d,`ws_m4_lvl`=%d,`ws_m4_exp`=%d,`ws_ak_lvl`=%d,`ws_ak_exp`=%d,`ws_sniper_lvl`=%d,`ws_sniper_exp`=%d WHERE `id`=%d",
        PlayerData[playerid][WeaponSkillLevel][0], PlayerData[playerid][WeaponSkillExp][0],
        PlayerData[playerid][WeaponSkillLevel][1], PlayerData[playerid][WeaponSkillExp][1],
        PlayerData[playerid][WeaponSkillLevel][2], PlayerData[playerid][WeaponSkillExp][2],
        PlayerData[playerid][WeaponSkillLevel][3], PlayerData[playerid][WeaponSkillExp][3],
        PlayerData[playerid][WeaponSkillLevel][4], PlayerData[playerid][WeaponSkillExp][4],
        PlayerData[playerid][WeaponSkillLevel][5], PlayerData[playerid][WeaponSkillExp][5],
        PlayerData[playerid][WeaponSkillLevel][6], PlayerData[playerid][WeaponSkillExp][6],
        PlayerData[playerid][WeaponSkillLevel][7], PlayerData[playerid][WeaponSkillExp][7],
        PlayerData[playerid][pID]
    );
    mysql_tquery(g_iHandle, query);
}

stock ResetWeaponSkill(playerid)
{
    for(new i; i < 8; i++)
    {
        PlayerData[playerid][WeaponSkillLevel][i] = 0;
        PlayerData[playerid][WeaponSkillExp][i] = 0;
    }
}

stock IsPlayerInWeaponStore(playerid)
{
    new bizid = PlayerData[playerid][pBusiness];
    if(bizid == -1) return 0;

    for(new i = 0; i < MAX_BUSINESSES; i++)
    {
        if(BusinessData[i][bizExists] && BusinessData[i][bizID] == bizid)
        {
            if(BusinessData[i][bizType] != 2) return 0;
            return 1;
        }
    }
    return 0;
}

stock CreateTrainingTextDraw(playerid)
{
    tdTrainBg[playerid] = CreatePlayerTextDraw(playerid, 500.0, 110.0, "LD_SPAC:white");
    PlayerTextDrawFont(playerid, tdTrainBg[playerid], 4);
    PlayerTextDrawTextSize(playerid, tdTrainBg[playerid], 148.0, 70.0);
    PlayerTextDrawColor(playerid, tdTrainBg[playerid], 0x00000099);
    PlayerTextDrawSetShadow(playerid, tdTrainBg[playerid], 0);

    tdTrainTitle[playerid] = CreatePlayerTextDraw(playerid, 502.0, 113.0, "WEAPON TRAINING");
    PlayerTextDrawFont(playerid, tdTrainTitle[playerid], 3);
    PlayerTextDrawLetterSize(playerid, tdTrainTitle[playerid], 0.28, 1.2);
    PlayerTextDrawColor(playerid, tdTrainTitle[playerid], 0xFF9900FF);
    PlayerTextDrawSetOutline(playerid, tdTrainTitle[playerid], 1);
    PlayerTextDrawSetShadow(playerid, tdTrainTitle[playerid], 0);

    tdTrainTimer[playerid] = CreatePlayerTextDraw(playerid, 502.0, 133.0, "Time: 00:60");
    PlayerTextDrawFont(playerid, tdTrainTimer[playerid], 3);
    PlayerTextDrawLetterSize(playerid, tdTrainTimer[playerid], 0.25, 1.1);
    PlayerTextDrawColor(playerid, tdTrainTimer[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetOutline(playerid, tdTrainTimer[playerid], 1);
    PlayerTextDrawSetShadow(playerid, tdTrainTimer[playerid], 0);

    tdTrainScore[playerid] = CreatePlayerTextDraw(playerid, 502.0, 153.0, "Score: 0 | EXP: 0");
    PlayerTextDrawFont(playerid, tdTrainScore[playerid], 3);
    PlayerTextDrawLetterSize(playerid, tdTrainScore[playerid], 0.25, 1.1);
    PlayerTextDrawColor(playerid, tdTrainScore[playerid], 0x00FF88FF);
    PlayerTextDrawSetOutline(playerid, tdTrainScore[playerid], 1);
    PlayerTextDrawSetShadow(playerid, tdTrainScore[playerid], 0);
}

stock ShowTrainingTextDraw(playerid)
{
    PlayerTextDrawShow(playerid, tdTrainBg[playerid]);
    PlayerTextDrawShow(playerid, tdTrainTitle[playerid]);
    PlayerTextDrawShow(playerid, tdTrainTimer[playerid]);
    PlayerTextDrawShow(playerid, tdTrainScore[playerid]);
}

stock HideTrainingTextDraw(playerid)
{
    PlayerTextDrawHide(playerid, tdTrainBg[playerid]);
    PlayerTextDrawHide(playerid, tdTrainTitle[playerid]);
    PlayerTextDrawHide(playerid, tdTrainTimer[playerid]);
    PlayerTextDrawHide(playerid, tdTrainScore[playerid]);

    PlayerTextDrawDestroy(playerid, tdTrainBg[playerid]);
    PlayerTextDrawDestroy(playerid, tdTrainTitle[playerid]);
    PlayerTextDrawDestroy(playerid, tdTrainTimer[playerid]);
    PlayerTextDrawDestroy(playerid, tdTrainScore[playerid]);
}

stock UpdateTrainingTimer(playerid, seconds)
{
    new str[32], color;
    if(seconds <= 10) color = 0xFF0000FF;
    else if(seconds <= 30) color = 0xFF9900FF;
    else color = 0xFFFFFFFF;

    format(str, sizeof str, "Time: 00:%02d", seconds);
    PlayerTextDrawSetString(playerid, tdTrainTimer[playerid], str);
    PlayerTextDrawColor(playerid, tdTrainTimer[playerid], color);
    PlayerTextDrawShow(playerid, tdTrainTimer[playerid]);
}

stock UpdateTrainingScore(playerid, hits)
{
    new str[64];
    new exp = hits * 2;
    format(str, sizeof str, "Score: %d | EXP: %d", hits, exp);
    PlayerTextDrawSetString(playerid, tdTrainScore[playerid], str);
    PlayerTextDrawShow(playerid, tdTrainScore[playerid]);
}

stock SpawnTrainingTargets(playerid)
{
    if(PlayerTraining[playerid][ptMoveTimer] != 0)
    {
        KillTimer(PlayerTraining[playerid][ptMoveTimer]);
        PlayerTraining[playerid][ptMoveTimer] = 0;
    }

    new vw = TRAIN_VW_BASE + playerid;

    for(new i = 0; i < MAX_TARGETS; i++)
    {
        PlayerTraining[playerid][ptTargets][i] = CreateDynamicObject(TARGET_HIT, TargetPos[i][0], TargetPos[i][1], TargetPos[i][2], 0.0, 0.0, TargetPos[i][3], vw, TRAIN_INTERIOR);
        TargetSpeed[playerid][i] = 0.05;
        TargetDirection[playerid][i] = 1;
        TargetMaxX[playerid][i] = TargetPos[i][0] + 1.5;
        TargetMinX[playerid][i] = TargetPos[i][0] - 1.5;
    }

    PlayerTraining[playerid][ptMoveTimer] = SetTimerEx("UpdateTargetsMovement", 50, true, "i", playerid);
}

stock StartWeaponTraining(playerid)
{
    PlayerTraining[playerid][ptActive] = true;
    PlayerTraining[playerid][ptHits] = 0;
    SpawnTrainingTargets(playerid);
    PlayerTraining[playerid][ptTimer] = SetTimerEx("FinishWeaponTraining", TRAIN_DURATION * 1000, false, "i", playerid);
    SendCustomMessage(playerid, "TRAINING", "Training started. You have 1 minute!");
}

forward UnfreezeTrainingPlayer(playerid);
public UnfreezeTrainingPlayer(playerid)
{
    TogglePlayerControllable(playerid, true);
    return 1;
}

forward StartTrainingDelayed(playerid);
public StartTrainingDelayed(playerid)
{
    SetPlayerPos(playerid, TRAIN_PLAYER_X, TRAIN_PLAYER_Y, TRAIN_PLAYER_Z);
    SetPlayerFacingAngle(playerid, TRAIN_PLAYER_A);
    SetPlayerInterior(playerid, TRAIN_INTERIOR);
    SetPlayerVirtualWorld(playerid, TRAIN_VW_BASE + playerid);

    new weapon = GetPVarInt(playerid, "TrainingWeapon");
    new ammo = GetPVarInt(playerid, "TrainingAmmo");

    ResetPlayerWeapons(playerid);
    GivePlayerWeapon(playerid, weapon, ammo);
    SetPlayerArmedWeapon(playerid, weapon);

    PlayerTraining[playerid][ptWeapon] = weapon;
    PlayerTraining[playerid][ptCanHit] = true;

    gTrainCountdown[playerid] = TRAIN_DURATION;

    CreateTrainingTextDraw(playerid);
    ShowTrainingTextDraw(playerid);
    UpdateTrainingTimer(playerid, gTrainCountdown[playerid]);
    UpdateTrainingScore(playerid, 0);

    if(gTrainCountdownTimer[playerid] != 0)
        KillTimer(gTrainCountdownTimer[playerid]);
    gTrainCountdownTimer[playerid] = SetTimerEx("TrainingCountdownTick", 1000, true, "i", playerid);

    StartWeaponTraining(playerid);
    SetTimerEx("UnfreezeTrainingPlayer", 800, false, "i", playerid);
    SendCustomMessage(playerid, "TRAINING", "Training started. Shoot the targets!");
    return 1;
}

forward TrainingCountdownTick(playerid);
public TrainingCountdownTick(playerid)
{
    if(!PlayerTraining[playerid][ptActive])
    {
        KillTimer(gTrainCountdownTimer[playerid]);
        gTrainCountdownTimer[playerid] = 0;
        return 1;
    }

    gTrainCountdown[playerid]--;
    UpdateTrainingTimer(playerid, gTrainCountdown[playerid]);
    UpdateTrainingScore(playerid, PlayerTraining[playerid][ptHits]);

    if(gTrainCountdown[playerid] <= 0)
    {
        KillTimer(gTrainCountdownTimer[playerid]);
        gTrainCountdownTimer[playerid] = 0;
    }
    return 1;
}

forward UpdateTargetsMovement(playerid);
public UpdateTargetsMovement(playerid)
{
    for(new i = 0; i < MAX_TARGETS; i++)
    {
        if(!IsValidDynamicObject(PlayerTraining[playerid][ptTargets][i]))
            continue;

        new Float:x, Float:y, Float:z;
        GetDynamicObjectPos(PlayerTraining[playerid][ptTargets][i], x, y, z);
        x += TargetSpeed[playerid][i] * TargetDirection[playerid][i];
        if(x >= TargetMaxX[playerid][i]) TargetDirection[playerid][i] = -1;
        else if(x <= TargetMinX[playerid][i]) TargetDirection[playerid][i] = 1;
        SetDynamicObjectPos(PlayerTraining[playerid][ptTargets][i], x, y, z);
    }
}

forward RespawnTraining(playerid);
public RespawnTraining(playerid)
{
    PlayerTraining[playerid][ptHitCount] = 0;
    PlayerTraining[playerid][ptActive] = true;
    PlayerTraining[playerid][ptCanHit] = true;
    SpawnTrainingTargets(playerid);
    SendCustomMessage(playerid, "TRAINING", "Target respawn!");
    return 1;
}

forward FinishWeaponTraining(playerid);
public FinishWeaponTraining(playerid)
{
    if(!PlayerTraining[playerid][ptActive]) return 1;

    if(PlayerTraining[playerid][ptMoveTimer] != 0)
    {
        KillTimer(PlayerTraining[playerid][ptMoveTimer]);
        PlayerTraining[playerid][ptMoveTimer] = 0;
    }

    if(gTrainCountdownTimer[playerid] != 0)
    {
        KillTimer(gTrainCountdownTimer[playerid]);
        gTrainCountdownTimer[playerid] = 0;
    }

    HideTrainingTextDraw(playerid);

    new hits = PlayerTraining[playerid][ptHits];
    new weapon = PlayerTraining[playerid][ptWeapon];
    PlayerTraining[playerid][ptActive] = false;

    for(new i = 0; i < MAX_TARGETS; i++)
    {
        if(IsValidDynamicObject(PlayerTraining[playerid][ptTargets][i]))
        {
            DestroyDynamicObject(PlayerTraining[playerid][ptTargets][i]);
            PlayerTraining[playerid][ptTargets][i] = INVALID_OBJECT_ID;
        }
    }

    new exp = hits * 2;
    AddWeaponSkillExp(playerid, weapon, exp);

    SendCustomMessage(playerid, "TRAINING", "Training finished! Hits: %d | EXP gained: %d", hits, exp);

    if(IsPlayerDuty(playerid)) RefreshFactionWeapon(playerid);
    else RefreshWeapon(playerid);

    new bizid = PlayerData[playerid][pBusiness];
    for(new i = 0; i < MAX_BUSINESSES; i++)
    {
        if(BusinessData[i][bizExists] && BusinessData[i][bizID] == bizid)
        {
            SetPlayerPos(playerid, 285.9346, -30.1827, 1001.5156);
            SetPlayerFacingAngle(playerid, 179.0002);
            SetPlayerInterior(playerid, BusinessData[i][bizInterior]);
            SetPlayerVirtualWorld(playerid, BusinessData[i][bizID] + 6000);
            break;
        }
    }
    return 1;
}

public OnPlayerShootDynamicObject(playerid, weaponid, objectid, Float:x, Float:y, Float:z)
{
    if(!PlayerTraining[playerid][ptActive]) return 1;

    for(new i = 0; i < MAX_TARGETS; i++)
    {
        if(PlayerTraining[playerid][ptTargets][i] == objectid)
        {
            DestroyDynamicObject(objectid);
            PlayerTraining[playerid][ptTargets][i] = INVALID_OBJECT_ID;
            PlayerTraining[playerid][ptHits]++;
            PlayerPlaySound(playerid, 1057, 0.0, 0.0, 0.0);
            UpdateTrainingScore(playerid, PlayerTraining[playerid][ptHits]);

            new bool:stillExist = false;
            for(new j = 0; j < MAX_TARGETS; j++)
            {
                if(IsValidDynamicObject(PlayerTraining[playerid][ptTargets][j]))
                {
                    stillExist = true;
                    break;
                }
            }
            if(!stillExist)
                SetTimerEx("RespawnTraining", 2000, false, "i", playerid);
            break;
        }
    }
    return 1;
}

// ============================================================
//  HOOKS
// ============================================================

forward UnfreezeSkillPlayer(playerid);
public UnfreezeSkillPlayer(playerid)
{
    TogglePlayerControllable(playerid, true);
    return 1;
}

hook OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    new idx = GetWeaponSkillIndex(weaponid);
    if(idx == -1) return 1;

    new level = PlayerData[playerid][WeaponSkillLevel][idx];
    new delay = 0;

    if(level == 0)      delay = 1000;
    else if(level == 2) delay = 800;
    else if(level == 3) delay = 400;

    if(delay > 0)
    {
        TogglePlayerControllable(playerid, false);
        SetTimerEx("UnfreezeSkillPlayer", delay, false, "i", playerid);
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerData[playerid][pSkillMecha] = 0;
    ResetWeaponSkill(playerid);
    ApplyWeaponSkillLevel(playerid);
    return 1;
}

// ============================================================
//  COMMANDS
// ============================================================

CMD:infoskills(playerid)
{
    new buf[512];
    format(buf, sizeof(buf),
        "Mechanic Skills :\n        Skill ini didapatkan saat kamu berhasil\n        melakukan repair engine atau repair tires.\n\n        Jika XP sudah mencapai 300, kamu akan\n        mendapatkan akses full mechanic menu\n        di mana saja tanpa harus berada\n        di area mechanic center.");
    Dialog_Show(playerid, DIALOG_SKILLINFO, DIALOG_STYLE_MSGBOX, "Skill Information", buf, "Tutup", "");
    return 1;
}

CMD:myskills(playerid)
{
    new buf[512];
    format(buf, sizeof(buf),
        "Skills	Exp	Progress\nMechanic	%d/300	%s\nWeapon Skills >>		",
        PlayerData[playerid][pSkillMecha],
        BuildSkillBar(PlayerData[playerid][pSkillMecha], MAX_SKILL_XP_MECHA));
    Dialog_Show(playerid, DIALOG_MYSKILLS, DIALOG_STYLE_TABLIST_HEADERS, "Player Skills", buf, "Select", "Close");
    return 1;
}

Dialog:DIALOG_MYSKILLS(playerid, response, listitem, inputtext[])
{
    if(!response) return 1;
    if(listitem == 1)
    {
        new shstr[2048];
        format(shstr, sizeof(shstr),
            "Skill	Level	Experience\nSilenced 9mm	%s	[%d/%d]\nDesert Eagle	%s	[%d/%d]\nShotgun	%s	[%d/%d]\nSawn-Off	%s	[%d/%d]\nMP5	%s	[%d/%d]\nM4	%s	[%d/%d]\nAK47	%s	[%d/%d]\nSniper	%s	[%d/%d]",
            WeaponSkillNames(PlayerData[playerid][WeaponSkillLevel][0]), PlayerData[playerid][WeaponSkillExp][0], WEAPON_EXP_MAX,
            WeaponSkillNames(PlayerData[playerid][WeaponSkillLevel][1]), PlayerData[playerid][WeaponSkillExp][1], WEAPON_EXP_MAX,
            WeaponSkillNames(PlayerData[playerid][WeaponSkillLevel][2]), PlayerData[playerid][WeaponSkillExp][2], WEAPON_EXP_MAX,
            WeaponSkillNames(PlayerData[playerid][WeaponSkillLevel][3]), PlayerData[playerid][WeaponSkillExp][3], WEAPON_EXP_MAX,
            WeaponSkillNames(PlayerData[playerid][WeaponSkillLevel][4]), PlayerData[playerid][WeaponSkillExp][4], WEAPON_EXP_MAX,
            WeaponSkillNames(PlayerData[playerid][WeaponSkillLevel][5]), PlayerData[playerid][WeaponSkillExp][5], WEAPON_EXP_MAX,
            WeaponSkillNames(PlayerData[playerid][WeaponSkillLevel][6]), PlayerData[playerid][WeaponSkillExp][6], WEAPON_EXP_MAX,
            WeaponSkillNames(PlayerData[playerid][WeaponSkillLevel][7]), PlayerData[playerid][WeaponSkillExp][7], WEAPON_EXP_MAX
        );
        Dialog_Show(playerid, DIALOG_WEAPON_SKILLS, DIALOG_STYLE_TABLIST_HEADERS, "Weapon Skills", shstr, "Back", "Close");
    }
    return 1;
}

Dialog:DIALOG_WEAPON_SKILLS(playerid, response, listitem, inputtext[])
{
    if(response) cmd_myskills(playerid);
    return 1;
}

CMD:training(playerid, params[])
{
    if(!IsPlayerInWeaponStore(playerid))
        return SendErrorMessage(playerid, "You must be inside a Weapon Store to train.");

    Dialog_Show(playerid, DIALOG_WEAPON_TRAINING, DIALOG_STYLE_LIST,
        "Weapon Training",
        "Silenced 9mm\nDesert Eagle\nShotgun\nSawn-Off\nMP5\nM4\nAK47\nSniper",
        "Select", "Cancel");
    return 1;
}

Dialog:DIALOG_WEAPON_TRAINING(playerid, response, listitem, inputtext[])
{
    if(!response) return 1;

    if(listitem < 0 || listitem >= sizeof(TrainingWeapons))
        return SendCustomMessage(playerid, "TRAINING", "Invalid weapon selection.");

    new bizVW = PlayerData[playerid][pBusiness] + 6000;
    SetPVarInt(playerid, "TrainingBizVW", bizVW);
    SetPVarInt(playerid, "TrainingWeapon", TrainingWeapons[listitem][twWeaponId]);
    SetPVarInt(playerid, "TrainingAmmo", TrainingWeapons[listitem][twAmmo]);

    TogglePlayerControllable(playerid, false);

    SetPlayerPos(playerid, TRAIN_PLAYER_X, TRAIN_PLAYER_Y, TRAIN_PLAYER_Z);
    SetPlayerFacingAngle(playerid, TRAIN_PLAYER_A);
    SetPlayerInterior(playerid, TRAIN_INTERIOR);
    SetPlayerVirtualWorld(playerid, TRAIN_VW_BASE + playerid);

    SetTimerEx("StartTrainingDelayed", 500, false, "i", playerid);
    return 1;
}
