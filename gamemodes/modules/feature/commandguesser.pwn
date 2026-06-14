stock CommandGuesser_Send(playerid, const cmdtext[])
{
    new guessed[34];
    new dist = Command_Guess(guessed, cmdtext);
    new msg[144];

    if (dist <= 3)
        format(msg, sizeof(msg), "* Tidak ada command tersebut, mungkin yang anda maksud adalah '%s'", guessed);
    else
        format(msg, sizeof(msg), "* Tidak ada command tersebut. Gunakan '/help' untuk melihat daftar command.");

    SendClientMessage(playerid, 0xAFAFAFAA, msg);
    return 1;
}
