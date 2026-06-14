#include <YSI\y_hooks>

new
		tick_CrouchKey[MAX_PLAYERS],
Timer:	SitDownTimer[MAX_PLAYERS];

#define MAX_ANIMS (1811)

forward Float:GetPlayerTotalVelocity(playerid);
Float:GetPlayerTotalVelocity(playerid)
{
    if(!SQL_IsLogged(playerid))
        return 0.0;

    new Float:velocity,
        Float:vx,
        Float:vy,
        Float:vz;

    GetPlayerVelocity(playerid, vx, vy, vz);
    velocity = floatsqroot( (vx*vx)+(vy*vy)+(vz*vz) ) * 150.0;

    return velocity;
}

timer SitLoop[1900](playerid)
{
	ApplyAnimation(playerid, "BEACH", "PARKSIT_M_LOOP", 4.0, 1, 0, 0, 0, 0);
}

timer SitDown[800](playerid)
{
	ApplyAnimation(playerid, "SUNBATHE", "PARKSIT_M_IN", 4.0, 0, 0, 0, 0, 0);
	defer SitLoop(playerid);
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(!IsPlayerInAnyVehicle(playerid) && !PlayerData[playerid][pInjured])
	{
		if(GetPlayerTotalVelocity(playerid) == 0.0)
		{
			if(newkeys == KEY_CROUCH)
			{
				tick_CrouchKey[playerid] = GetTickCount();
				SitDownTimer[playerid] = defer SitDown(playerid);
			}

			if(oldkeys == KEY_CROUCH)
			{
				if(GetTickCountDifference(GetTickCount(), tick_CrouchKey[playerid]) < 250)
				{
					stop SitDownTimer[playerid];
				}
			}

			if(newkeys & KEY_SPRINT && newkeys & KEY_CROUCH)
			{
				if(GetPlayerAnimationIndex(playerid) == 1381)
				{
					ClearAnimations(playerid);
				}
				else
				{
					ApplyAnimation(playerid, "ROB_BANK", "SHP_HandsUp_Scr", 4.0, 0, 1, 1, 1, 0);
				}
			}
		}
		if(newkeys & KEY_CROUCH || newkeys & KEY_SPRINT || newkeys & KEY_JUMP)
		{
			if(GetPlayerAnimationIndex(playerid) == 43 || GetPlayerAnimationIndex(playerid) == 1497)
			{
				ApplyAnimation(playerid, "SUNBATHE", "PARKSIT_M_OUT", 4.0, 0, 0, 0, 0, 0);
			}
		}
		if(newkeys & KEY_JUMP && !(oldkeys & KEY_JUMP) && GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_CUFFED)
		{
			if(random(100) < 60)
				ApplyAnimation(playerid, "GYMNASIUM", "gym_jog_falloff", 4.1, 0, 1, 1, 0, 0);
		}
	}

	return 1;
}

CMD:anim(playerid, params[])
{
	new
		animlib[32],
		animname[32],
		index;

	if (sscanf(params, "d", index)) return SendSyntaxMessage(playerid, "/anim [index 1-1811]");

	if(!AnimationCheck(playerid))
        return SendErrorMessage(playerid, "You can't perform animations at the moment.");

	if(index < 1 || index > MAX_ANIMS) return SendErrorMessage(playerid, "Invalid index!");
	else
	{
		GetAnimationName(index, animlib, 32, animname, 32);
		ApplyAnimationEx(playerid, animlib, animname, 4.1, 1, 0, 0, 1, 0, 1);
	}
	return 1;
}


//Anim Menu
#define ANIM_PER_PAGE   15

static const AnimData[][3][] = {
    { "Dance - Joget",           "DANCING",      "dance_loop"        },
    { "Dance - Kiri",            "DANCING",      "DAN_Left_A"        },
    { "Dance - Kanan",           "DANCING",      "DAN_Right_A"       },
    { "Dance - Loop A",          "DANCING",      "DAN_Loop_A"        },
    { "Dance - Up",              "DANCING",      "DAN_Up_A"          },
    { "Dance - Down",            "DANCING",      "DAN_Down_A"        },
    { "Dance - Male A",          "DANCING",      "dnce_M_a"          },
    { "Dance - Male B",          "DANCING",      "dnce_M_b"          },
    { "Dance - Male C",          "DANCING",      "dnce_M_c"          },
    { "Dance - Male E",          "DANCING",      "dnce_M_e"          },
    { "Duduk - Santai",          "ped",          "SEAT_down"         },
    { "Duduk - Console",        "CRIB",          "PED_Console_Loop"  },
    { "Duduk - Sofa",           "INT_HOUSE",     "LOU_In"            },
    { "Duduk - Kursi Kiri",     "MISC",          "SEAT_LR"           },
    { "Duduk - Ngobrol 1",      "MISC",          "Seat_talk_01"      },
    { "Duduk - Ngobrol 2",      "MISC",          "Seat_talk_02"      },
    { "Baring - Pantai",        "BEACH",         "bather"            },
    { "Baring - Telentang",     "BEACH",         "Lay_Bac_Loop"      },
    { "Duduk - Taman (M)",      "BEACH",         "ParkSit_M_loop"    },
    { "Duduk - Taman (W)",      "BEACH",         "ParkSit_W_loop"    },
    { "Duduk - Tunggu (W)",     "BEACH",         "SitnWait_loop_W"   },
    { "Kantor - Bosan",         "INT_OFFICE",    "OFF_Sit_Bored_Loop"},
    { "Kantor - Crash",         "INT_OFFICE",    "OFF_Sit_Crash"     },
    { "Kantor - Minum",         "INT_OFFICE",    "OFF_Sit_Drink"     },
    { "Kantor - Baca",          "INT_OFFICE",    "OFF_Sit_Read"      },
    { "Kantor - Ketik",         "INT_OFFICE",    "OFF_Sit_Type_Loop" },
    { "Kantor - Lihat",         "INT_OFFICE",    "OFF_Sit_Watch"     },
    { "Rokok - Hisap",          "SMOKING",       "M_smk_drag"        },
    { "Rokok - Sandaran",       "SMOKING",       "M_smklean_loop"    },
    { "Rokok - Berdiri",        "SMOKING",       "M_smkstnd_loop"    },
    { "Bar - Bartender Idle",   "BAR",           "BARman_idle"       },
    { "Bar - Sajikan Botol",    "BAR",           "Barserve_bottle"   },
    { "Bar - Sajikan Gelas",    "BAR",           "Barserve_glass"    },
    { "Bar - Kasih",            "BAR",           "Barserve_give"     },
    { "Bar - Order",            "BAR",           "Barserve_order"    },
    { "Bar - Minum (M)",        "BAR",           "dnk_stndM_loop"    },
    { "Bar - Minum (W)",        "BAR",           "dnk_stndF_loop"    },
    { "Makan - Burger",         "FOOD",          "EAT_Burger"        },
    { "Makan - Ayam",           "FOOD",          "EAT_Chicken"       },
    { "Makan - Pizza",          "FOOD",          "EAT_Pizza"         },
    { "Muntah",                 "FOOD",          "EAT_Vomit_P"       },
    { "Telpon - Tangan Kiri",   "PED",           "PHONE_Talk"        },
    { "Telpon - Akhiri",        "PED",           "PHONE_hangup"      },
    { "Telpon - Tegang",        "PED",           "phone_in"          },
    { "Lambaian - Selamat",     "PED",           "endchat_03"        },
    { "Lambaian - Cewek",       "KISSING",       "gfwave2"           },
    { "Lambaian - Loop",        "ON_LOOKERS",    "wave_loop"         },
    { "Sorak - Teriak 1",       "ON_LOOKERS",    "shout_01"          },
    { "Sorak - Teriak 2",       "ON_LOOKERS",    "shout_02"          },
    { "Riot - Marah",           "RIOT",          "RIOT_ANGRY_B"      },
    { "Riot - Chant",           "RIOT",          "RIOT_CHANT"        },
    { "Riot - Teriak",          "RIOT",          "RIOT_shout"        },
    { "Holler",                 "STRIP",         "PUN_HOLLER"        },
    { "Menang",                 "OTB",           "wtchrace_win"      },
    { "Tunjuk - Lurus",         "PED",           "ARRESTgun"         },
    { "Tunjuk - Ancam",         "SHOP",          "ROB_Loop_Threat"   },
    { "Tunjuk - Loop",          "ON_LOOKERS",    "point_loop"        },
    { "Tunjuk - Atas",          "ON_LOOKERS",    "Pointup_loop"      },
    { "Ngobrol - Gaya 1",       "GANGS",         "prtial_gngtlkA"    },
    { "Ngobrol - Gaya 2",       "GANGS",         "prtial_gngtlkB"    },
    { "Ngobrol - Gaya 3",       "GANGS",         "prtial_gngtlkD"    },
    { "Ngobrol - Gaya 4",       "GANGS",         "prtial_gngtlkE"    },
    { "Ngobrol - Gaya 5",       "GANGS",         "prtial_gngtlkF"    },
    { "Ngobrol - Gaya 6",       "GANGS",         "prtial_gngtlkG"    },
    { "Ngobrol - Gaya 7",       "GANGS",         "prtial_gngtlkH"    },
    { "Gang Sign 1",            "GHANDS",        "gsign1"            },
    { "Gang Sign 1 (Kiri)",     "GHANDS",        "gsign1LH"          },
    { "Gang Sign 2",            "GHANDS",        "gsign2"            },
    { "Gang Sign 2 (Kiri)",     "GHANDS",        "gsign2LH"          },
    { "Gang Sign 3",            "GHANDS",        "gsign3"            },
    { "Gang Sign 4",            "GHANDS",        "gsign4"            },
    { "Gang Sign 5",            "GHANDS",        "gsign5"            },
    { "Gang Invite No",         "GANGS",         "Invite_No"         },
    { "Gang Invite Yes",        "GANGS",         "Invite_Yes"        },
    { "Smoke Gang",             "GANGS",         "smkcig_prtl"       },
    { "Strip - A",              "STRIP",         "strip_A"           },
    { "Strip - B",              "STRIP",         "strip_B"           },
    { "Strip - C",              "STRIP",         "strip_C"           },
    { "Strip - D",              "STRIP",         "strip_D"           },
    { "Strip - E",              "STRIP",         "strip_E"           },
    { "Strip - F",              "STRIP",         "strip_F"           },
    { "Strip - G",              "STRIP",         "strip_G"           },
    { "Gym - Bench Press Atas A","benchpress",   "gym_bp_up_A"       },
    { "Gym - Bench Press Atas B","benchpress",   "gym_bp_up_B"       },
    { "Gym - Bench Press Turun","benchpress",    "gym_bp_down"       },
    { "Gym - Naik",             "benchpress",    "gym_bp_geton"      },
    { "Gym - Turun",            "benchpress",    "gym_bp_getoff"     },
    { "Gym - Rayakan",          "benchpress",    "gym_bp_celebrate"  },
    { "Jalan - Gemuk",          "FAT",           "FatWalk"           },
    { "Jalan - Berotot",        "MUSCULAR",      "MuscleWalk"        },
    { "Jalan - Bersenjata",     "PED",           "WALK_armed"        },
    { "Jalan - Sipil",          "PED",           "WALK_civi"         },
    { "Jalan - Gang 1",         "PED",           "WALK_gang1"        },
    { "Jalan - Gang 2",         "PED",           "WALK_gang2"        },
    { "Jalan - Tua",            "PED",           "WALK_old"          },
    { "Jalan - Wuzi",           "PED",           "WALK_wuzi"         },
    { "Jalan - Wanita Sibuk",   "PED",           "WOMAN_walkbusy"    },
    { "Jalan - Wanita Normal",  "PED",           "WOMAN_walknorm"    },
    { "Jalan - Wanita Seksi",   "PED",           "WOMAN_walksexy"    },
    { "Jalan - Wanita Belanja", "PED",           "WOMAN_walkshop"    },
    { "Bersandar - Tembok",     "PED",           "WALL_lean_loop"    },
    { "Idle - Capek",           "PED",           "IDLE_tired"        },
    { "Idle - Takut",           "PED",           "cower"             },
    { "Idle - Mabuk",           "PED",           "WALK_drunk"        },
    { "Idle - Tai Chi",         "PARK",          "Tai_Chi_Loop"      },
    { "Idle - Gosip (F)",       "PED",           "f_fbtlt_bnch_idl"  },
    { "Idle - Ayun Tangan",     "PED",           "ARMbitrch_loop"    },
    { "Silang Tangan - Polisi", "COP_AMBIENT",   "Coplook_loop"      },
    { "Silang Tangan - Pastor", "GRAVEYARD",     "prst_loopa"        },
    { "Silang Tangan - Pria",   "GRAVEYARD",     "mrnM_loop"         },
    { "Silang Tangan - Cewek",  "GRAVEYARD",     "mrnF_loop"         },
    { "Silang Tangan - Dealer", "DEALER",        "DEALER_IDLE"       },
    { "Dealer - Deal",          "DEALER",        "DEALER_DEAL"       },
    { "Dealer - Beli",          "DEALER",        "DRUGS_BUY"         },
    { "Dealer - Bayar",         "DEALER",        "shop_pay"          },
    { "Dealer - Idle 1",        "DEALER",        "DEALER_IDLE_01"    },
    { "Dealer - Idle 2",        "DEALER",        "DEALER_IDLE_02"    },
    { "Dealer - Idle 3",        "DEALER",        "DEALER_IDLE_03"    },
    { "Crack - Mati 1",         "CRACK",         "crckdeth1"         },
    { "Crack - Mati 2",         "CRACK",         "crckdeth2"         },
    { "Crack - Mati 3",         "CRACK",         "crckdeth3"         },
    { "Crack - Tidur",          "CRACK",         "crckdeth4"         },
    { "Crack - Idle 1",         "CRACK",         "crckidle1"         },
    { "Crack - Idle 2",         "CRACK",         "crckidle2"         },
    { "Crack - Idle 3",         "CRACK",         "crckidle3"         },
    { "Jatuh - Ke Depan",       "PED",           "KO_skid_front"     },
    { "Jatuh - Kena Muka",      "PED",           "KO_shot_face"      },
    { "Jatuh - Kena Perut",     "PED",           "KO_shot_stom"      },
    { "Jatuh - Dari Motor",     "PED",           "BIKE_fallR"        },
    { "Fucku",                  "PED",           "fucku"             },
    { "Garuk - DJ 1",           "SCRATCHING",    "scdldlp"           },
    { "Garuk - DJ 2",           "SCRATCHING",    "scdlulp"           },
    { "Garuk - DJ 3",           "SCRATCHING",    "scdrdlp"           },
    { "Garuk - DJ 4",           "SCRATCHING",    "scdrulp"           },
    { "Spray Cat",              "GRAFFITI",      "spraycan_fire"     },
    { "Lempar",                 "GRENADE",       "WEAPON_throw"      },
    { "Swipe Kartu",            "HEIST9",        "Use_SwipeCard"     },
    { "Cuci Tangan",            "BD_FIRE",       "wash_up"           },
    { "CPR",                    "Fire",          "CPR"               },
    { "Kiss - Kekasih 1 (F)",   "KISSING",       "Grlfrd_Kiss_01"    },
    { "Kiss - Kekasih 2 (F)",   "KISSING",       "Grlfrd_Kiss_02"    },
    { "Kiss - Kekasih 3 (F)",   "KISSING",       "Grlfrd_Kiss_03"    },
    { "Kiss - Player 1",        "KISSING",       "Playa_Kiss_01"     },
    { "Kiss - Player 2",        "KISSING",       "Playa_Kiss_02"     },
    { "Kiss - Player 3",        "KISSING",       "Playa_Kiss_03"     },
    { "Reload - Buddy",         "BUDDY",         "buddy_reload"      },
    { "Reload - Uzi",           "UZI",           "UZI_reload"        },
    { "Reload - Colt45",        "COLT45",        "colt45_reload"     },
    { "Reload - Rifle",         "RIFLE",         "rifle_load"        },
    { "Pisau - Serang 1",       "KNIFE",         "knife_1"           },
    { "Pisau - Serang 2",       "KNIFE",         "knife_2"           },
    { "Pisau - Serang 3",       "KNIFE",         "knife_3"           },
    { "Pisau - Serang 4",       "KNIFE",         "knife_4"           },
    { "Pisau - Idle",           "KNIFE",         "WEAPON_knifeidle"  },
    { "Pisau - Kill",           "KNIFE",         "KILL_Knife_Player" },
    { "Bat - Ayun 1",           "BASEBALL",      "Bat_1"             },
    { "Bat - Ayun 2",           "BASEBALL",      "Bat_2"             },
    { "Bat - Ayun 3",           "BASEBALL",      "Bat_3"             },
    { "Bat - Ayun 4",           "BASEBALL",      "Bat_4"             },
    { "Bat - Idle",             "BASEBALL",      "Bat_IDLE"          },
    { "Bat - Tampar",           "BASEBALL",      "Bat_M"             },
    { "Angkat - Normal",        "CARRY",         "liftup"            },
    { "Angkat - 05",            "CARRY",         "liftup05"          },
    { "Angkat - 105",           "CARRY",         "liftup105"         },
    { "Taruh - Normal",         "CARRY",         "putdwn"            },
    { "Taruh - 05",             "CARRY",         "putdwn05"          },
    { "Bom - Tanam",            "BOMBER",        "BOM_Plant"         },
    { "Menangis",               "GRAVEYARD",     "mrnF_loop"         },
    { "Menguap",                "PED",           "IDLE_tired"        },
    { "Goggles - Pasang",       "goggles",       "goggles_put_on"    },
    { "Kencing",                "PED",           "piss_loop"         },
    { "Muntah Dramatis",        "PED",           "vomit_p"           },
    { "Wank 1",                 "PAULNMAC",      "wank_loop"         },
    { "Lompat",                 "DODGE",         "Crush_Jump"        },
    { "Slap",                   "BASEBALL",      "Bat_M"             }
};

new AnimMenuPage[MAX_PLAYERS];

static GetAnimCount()
{
    return sizeof(AnimData);
}

static ShowAnimMenuDialog(playerid, page)
{
    new
        str[4096],
        total   = GetAnimCount(),
        start   = page * ANIM_PER_PAGE,
        finish  = start + ANIM_PER_PAGE,
        pages   = (total + ANIM_PER_PAGE - 1) / ANIM_PER_PAGE;

    if(start >= total) { start = 0; page = 0; }
    if(finish > total) finish = total;

    AnimMenuPage[playerid] = page;
    str[0] = EOS;

    for(new i = start; i < finish; i++)
    {
        strcat(str, AnimData[i][0], sizeof(str));
        strcat(str, "\n", sizeof(str));
    }

    if(pages > 1)
    {
        if(page < pages - 1)
            strcat(str, ">> Next Page >>\n", sizeof(str));
        if(page > 0)
            strcat(str, "<< Prev Page <<\n", sizeof(str));
    }

    new title[64];
    format(title, sizeof(title), "My Animations  (Hal. %d/%d)", page + 1, pages);
    Dialog_Show(playerid, AnimMenuDb, DIALOG_STYLE_LIST, title, str, "Select", "Close");
}

CMD:animmenu(playerid, params[])
{
    if(PlayerData[playerid][pInjured])
        return SendErrorMessage(playerid, "Kamu tidak bisa melakukan animasi saat terluka.");

    if(!AnimationCheck(playerid))
        return SendErrorMessage(playerid, "Kamu tidak bisa melakukan animasi saat ini.");

    AnimMenuPage[playerid] = 0;
    ShowAnimMenuDialog(playerid, 0);
    return 1;
}

CMD:am(playerid, params[])
    return cmd_animmenu(playerid, params);

Dialog:AnimMenuDb(playerid, response, listitem, inputtext[])
{
    if(!response) return 1;

    new
        page    = AnimMenuPage[playerid],
        total   = GetAnimCount(),
        start   = page * ANIM_PER_PAGE,
        finish  = start + ANIM_PER_PAGE,
        pages   = (total + ANIM_PER_PAGE - 1) / ANIM_PER_PAGE;

    if(finish > total) finish = total;

    new navBase  = finish - start;
    new hasNext  = (page < pages - 1) ? 1 : 0;
    new hasPrev  = (page > 0)         ? 1 : 0;

    if(hasNext && listitem == navBase)
    {
        ShowAnimMenuDialog(playerid, page + 1);
        return 1;
    }

    if(hasPrev && listitem == navBase + hasNext)
    {
        ShowAnimMenuDialog(playerid, page - 1);
        return 1;
    }

    new animIdx = start + listitem;
    if(animIdx < 0 || animIdx >= total) return 1;

    new lib[32], name[64];
    format(lib,  sizeof(lib),  "%s", AnimData[animIdx][1]);
    format(name, sizeof(name), "%s", AnimData[animIdx][2]);

    new bool:isSitType = (
        strfind(name, "sit",    true) != -1 ||
        strfind(name, "seat",   true) != -1 ||
        strfind(name, "lou_in", true) != -1 ||
        strfind(name, "lay",    true) != -1 ||
        strfind(name, "bather", true) != -1 ||
        strfind(name, "lean",   true) != -1 ||
        strfind(name, "liftup", true) != -1 ||
        strfind(name, "putdwn", true) != -1
    );

    if(isSitType)
        ApplyAnimationEx(playerid, lib, name, 4.1, 0, 0, 0, 1, 0);
    else
        ApplyAnimationEx(playerid, lib, name, 4.1, 1, 0, 0, 0, 0);

    SendCustomMessage(playerid, "ANIM", "Animasi: %s | Sprint untuk stop.", AnimData[animIdx][0]);
    return 1;
}
