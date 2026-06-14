new CalculatorFirstNumber[MAX_PLAYERS];
new CalculatorOperator[MAX_PLAYERS];

stock Calculator_ShowMain(playerid)
{
    Dialog_Show(playerid, CalculatorMain, DIALOG_STYLE_LIST, "Calculator", "Addition (+)\nSubtraction (-)\nMultiplication (*)\nDivision (/)", "Select", "Back");
    return 1;
}

CMD:calculator(playerid, params[])
{
    #pragma unused params

    if(!Inventory_HasItem(playerid, "Cellphone"))
        return SendErrorMessage(playerid, "You don't have a cellphone on you.");

    if(PlayerData[playerid][pHospital] != -1 || PlayerData[playerid][pCuffed] || PlayerData[playerid][pInjured] || !IsPlayerSpawned(playerid) || PlayerData[playerid][pJailTime])
        return SendErrorMessage(playerid, "You can't use this command now.");

    if(PlayerData[playerid][pPhoneOff])
        return SendErrorMessage(playerid, "Your phone must be powered on.");

    return Calculator_ShowMain(playerid);
}

Dialog:CalculatorMain(playerid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    if(response)
    {
        switch(listitem)
        {
            case 0: CalculatorOperator[playerid] = '+';
            case 1: CalculatorOperator[playerid] = '-';
            case 2: CalculatorOperator[playerid] = '*';
            case 3: CalculatorOperator[playerid] = '/';
        }

        Dialog_Show(playerid, CalculatorFirstInput, DIALOG_STYLE_INPUT, "Calculator", "Enter the first number:", "Continue", "Back");
    }
    else Phone_ShowApplicationMenu(playerid);
    return 1;
}

Dialog:CalculatorFirstInput(playerid, response, listitem, inputtext[])
{
    #pragma unused listitem

    if(response)
    {
        if(isnull(inputtext) || !IsNumeric(inputtext))
            return Dialog_Show(playerid, CalculatorFirstInput, DIALOG_STYLE_INPUT, "Calculator", "Error: Please enter a valid number.\n\nEnter the first number:", "Continue", "Back");

        CalculatorFirstNumber[playerid] = strval(inputtext);
        Dialog_Show(playerid, CalculatorSecondInput, DIALOG_STYLE_INPUT, "Calculator", "Enter the second number:", "Calculate", "Back");
    }
    else Calculator_ShowMain(playerid);
    return 1;
}

Dialog:CalculatorSecondInput(playerid, response, listitem, inputtext[])
{
    #pragma unused listitem

    if(response)
    {
        new number = strval(inputtext), resultText[96];

        if(isnull(inputtext) || !IsNumeric(inputtext))
            return Dialog_Show(playerid, CalculatorSecondInput, DIALOG_STYLE_INPUT, "Calculator", "Error: Please enter a valid number.\n\nEnter the second number:", "Calculate", "Back");

        switch(CalculatorOperator[playerid])
        {
            case '+': format(resultText, sizeof(resultText), "%d + %d = %d", CalculatorFirstNumber[playerid], number, CalculatorFirstNumber[playerid] + number);
            case '-': format(resultText, sizeof(resultText), "%d - %d = %d", CalculatorFirstNumber[playerid], number, CalculatorFirstNumber[playerid] - number);
            case '*': format(resultText, sizeof(resultText), "%d * %d = %d", CalculatorFirstNumber[playerid], number, CalculatorFirstNumber[playerid] * number);
            case '/':
            {
                if(!number)
                    return Dialog_Show(playerid, CalculatorSecondInput, DIALOG_STYLE_INPUT, "Calculator", "Error: You can't divide by zero.\n\nEnter the second number:", "Calculate", "Back");

                format(resultText, sizeof(resultText), "%d / %d = %.2f", CalculatorFirstNumber[playerid], number, float(CalculatorFirstNumber[playerid]) / float(number));
            }
        }

        Dialog_Show(playerid, CalculatorResult, DIALOG_STYLE_MSGBOX, "Calculator", resultText, "Back", "Close");
    }
    else Dialog_Show(playerid, CalculatorFirstInput, DIALOG_STYLE_INPUT, "Calculator", "Enter the first number:", "Continue", "Back");
    return 1;
}

Dialog:CalculatorResult(playerid, response, listitem, inputtext[])
{
    #pragma unused listitem
    #pragma unused inputtext

    if(response)
        Calculator_ShowMain(playerid);

    return 1;
}
