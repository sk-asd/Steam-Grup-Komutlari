#include <sourcemod>
#include <SteamWorks>
#pragma newdecls required 
#pragma semicolon 1
ConVar iGroupID = null;
bool b_IsMember[MAXPLAYERS + 1];
public void OnPluginStart()
{
	RegAdminCmd("sm_grupkomutyenile", CMD_RELOAD, ADMFLAG_ROOT);
	iGroupID = CreateConVar("steam_grupid", "", "Grubunuza girip, grup profilini düzenleye basınız. Kimlik yazan numarayı buraya yapıştırınız.", FCVAR_NOTIFY);
	AutoExecConfig(true, "Grup_Komutlari");
	LoadConfig();
}
public Action CMD_RELOAD(int iClient, int iArgs)
{
	LoadConfig();
	return Plugin_Handled;
}
public Action Check(int client, char[] sCommand, int iArgc)
{
	if (client == 0)
	{
		return Plugin_Stop;
	}
	
	SteamWorks_GetUserGroupStatus(client, iGroupID.IntValue);
	
	if (client && !b_IsMember[client])
	{
		PrintToChat(client, "[SM] \x0cBu Komutu Kullanmak İçin \x09Steam Grubumuzda Olmalısın.");
		PrintToChat(client, "[SM] \x0cGruba Katılmak İçin \x0e!grup \x09Yazarak Gruba Katılabilirsin.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
void LoadConfig()
{
	KeyValues kv = CreateKeyValues("Steam_Grup_Komutlari");
	char sBuffer[256];
	
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/Steam_Grup_Komutlari.ini");
	kv.ImportFromFile(sBuffer);
	if (!FileToKeyValues(kv, sBuffer))
	{
		SetFailState("Dosya bulunamadi: %s", sBuffer);
	}
	
	if (kv.GotoFirstSubKey(true))
	{
		do
		{
			if (kv.GetSectionName(sBuffer, sizeof(sBuffer)))
			{
				AddCommandListener(Check, sBuffer);
			}
		} 
		while (kv.GotoNextKey(true));
	}
	delete kv;
}
public void OnClientPostAdminCheck(int client)
{
	b_IsMember[client] = false;
	
	if (IsValidClient(client))
	{
		CreateTimer(1.0, Kontrol, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}
public Action Kontrol(Handle Timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client == 0)
	{
		return Plugin_Stop;
	}
	SteamWorks_GetUserGroupStatus(client, iGroupID.IntValue);
	return Plugin_Handled;
}
public int SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool isMember, bool isOfficer)
{
	int client = UserAuthGrab(authid);
	
	b_IsMember[client] = false;
	
	if (client != -1 && isMember)
	{
		b_IsMember[client] = true;
	}
}
int UserAuthGrab(int authid)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			char charauth[64];
			char authchar[64];
			GetClientAuthId(i, AuthId_Steam3, charauth, sizeof(charauth), true);
			IntToString(authid, authchar, sizeof(authchar));
			if (StrContains(charauth, authchar) != -1)
			{
				return i;
			}
		}
	}
	return -1;
}
stock bool IsValidClient(int client)
{
	return 1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}