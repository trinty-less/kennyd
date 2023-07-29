// ============= INCLUDE =======================================================
#include <a_samp>

#define YSI_NO_HEAP_MALLOC

#include <easyDialog>
#include <sscanf2>
#include <streamer>
#include <crashdetect>
#include <Pawn.Regex>
#include <YSI_Coding\y_hooks>
#include <YSI_Coding\y_va>
#include <YSI_Storage\y_ini>
#include <YSI_Visual\y_commands>
#include <YSI_Coding\y_timers>
#include <YSI_Data\y_iterate>

// ===========================================================================//


// ============= COLORS =======================================================//
#define c_white  "{ffffff}"
#define c_blue   "{00C0FF}"
#define c_server "{1976D2}"
#define c_red    "{F44336}"
// ===========================================================================//

// ============================== Konstante ==================================//
static stock const USER_PATH[64] = "/Korisnici/%s.ini";

const MAX_PASSWORD_LENGTH = 64;
const MIN_PASSWORD_LENGTH = 6;
const MAX_LOGIN_ATTEMPTS = 	3;
// ===========================================================================//


// ================================== ENUMS ===================================//
enum
{
	e_SPAWN_TYPE_REGISTER = 1,
    e_SPAWN_TYPE_LOGIN
};

// =============================================================================

// ================= VARIJABLE ==============================================-//
static
    player_Password[MAX_PLAYERS][MAX_PASSWORD_LENGTH],
    player_Score[MAX_PLAYERS],
	player_Skin[MAX_PLAYERS],
    player_Money[MAX_PLAYERS],
	player_Admin[MAX_PLAYERS],
	player_Staff[MAX_PLAYERS],
    player_LoginAttempts[MAX_PLAYERS],
    player_AdminDuty[MAX_PLAYERS],
    player_AdminVehicle[MAX_VEHICLES],
    player_GodMode[MAX_PLAYERS];
// =============================================================================



main()
{

	printf("---------------------------");
	printf("Credits for Script: Trinty");
	printf("Owner of Script: Trinty");
	printf("Project Name: Kenny Project");
	printf("---------------------------");
	return 1;
}

// ===================== FUNCS ================================================
forward Account_Load(const playerid, const string: name[], const string: value[]);
public Account_Load(const playerid, const string: name[], const string: value[])
{
	INI_String("Password", player_Password[playerid]);
	INI_Int("Level", player_Score[playerid]);
	INI_Int("Skin", player_Skin[playerid]);
	INI_Int("Money", player_Money[playerid]);
	INI_Int("Admin", player_Admin[playerid]);
	INI_Int("Staff", player_Staff[playerid]);

	return 1;
}

stock Account_Path(const playerid)
{
	static tmp_fmt[64];
	format(tmp_fmt, sizeof(tmp_fmt), USER_PATH, ReturnPlayerName(playerid));

	return tmp_fmt;
}


stock IsVehicleBicycle(m)
{
    if (m == 481 || m == 509 || m == 510) return true;

    return false;
}

stock ProxDetector(playerid, Float:max_range, color, const string[], va_args<>)
{
	new
		f_string[YSI_MAX_STRING],
		Float:pos_x,
		Float:pos_y,
		Float:pos_z,
		Float:range,
		Float:range_ratio,
		Float:range_with_ratio,
		clr_r, clr_g, clr_b,
		Float:color_r, Float:color_g, Float:color_b;

	if (!GetPlayerPos(playerid, pos_x, pos_y, pos_z)) {
		return 0;
	}

	va_format(f_string, sizeof(f_string), string, va_start<4>);

	color_r = float(color >> 24 & 0xFF);
	color_g = float(color >> 16 & 0xFF);
	color_b = float(color >> 8 & 0xFF);
	range_with_ratio = max_range * 1.6;

	foreach (new i : Player)
	{
		if(!IsPlayerStreamedIn(i, playerid)) {
			continue;
		}

		range = GetPlayerDistanceFromPoint(i, pos_x, pos_y, pos_z);
		if (range > max_range) {
			continue;
		}

		range_ratio = (range_with_ratio - range) / range_with_ratio;
		clr_r = floatround(range_ratio * color_r);
		clr_g = floatround(range_ratio * color_g);
		clr_b = floatround(range_ratio * color_b);

		SendClientMessage(i, (color & 0xFF) | (clr_b << 8) | (clr_g << 16) | (clr_r << 24), f_string);
	}

	SendClientMessage(playerid, color, f_string);
	return 1;
}

stock IsRpNickname(const nickname[])
{
  static Regex:regex;
  if (!regex) regex = Regex_New("[A-Z][a-z]+_[A-Z][a-z]+");

  return Regex_Check(nickname, regex);
}
// =============================================================================
timer KickTimer[1000](playerid)
{
	Kick(playerid);

	return 1;
}
// ========================== PUBLICS FUNCTION ===============================//
public OnGameModeInit()
{

    DisableInteriorEnterExits();
	ManualVehicleEngineAndLights();
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
	SetNameTagDrawDistance(20.0);
	LimitGlobalChatRadius(20.0);
	AllowInteriorWeapons(1);
	EnableVehicleFriendlyFire();
	EnableStuntBonusForAll(0);
	SetGameModeText("v2.0 release script");
	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	for(new i = 0; i < 20; i++) { SendClientMessage(playerid, -1, ""); }

	if (fexist(Account_Path(playerid)))
	{
		INI_ParseFile(Account_Path(playerid), "Account_Load", true, true, playerid);
		Dialog_Show(playerid, "dialog_login", DIALOG_STYLE_PASSWORD,
			""c_server"[LOGIN]:",
			""c_white"%s, unesite Vasu tacnu lozinku:\nZapamtite: ne odgovaramo za ono sto se desi vasem nalogu ! ",
			"Potvrdi", "Izlaz", ReturnPlayerName(playerid)
		);

		return 1;
	}

	Dialog_Show(playerid, "dialog_register", DIALOG_STYLE_INPUT,
		""c_server"[REGISTER]:",
		""c_white"%s, unesite Vasu zeljenu lozinku:\nZapamtite: ne odgovaramo za ono sto se desi vasem nalogu ! ",
		"Potvrdi", "Izlaz", ReturnPlayerName(playerid)
	);

	if(!fexist(Account_Path(playerid)))
	{
        if(!IsRpNickname(ReturnPlayerName(playerid)))
		{
		SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Vase Ime i Prezime nije u formatu Ime_Prezime !");
		defer KickTimer(playerid);
		}
	}

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(fexist(Account_Path(playerid)))
	{
	new INI:File = INI_Open(Account_Path(playerid));
    INI_SetTag(File,"data");
    INI_WriteInt(File, "Level",GetPlayerScore(playerid));
    INI_WriteInt(File, "Skin",GetPlayerSkin(playerid));
    INI_WriteInt(File, "Money", GetPlayerMoney(playerid));
    INI_WriteInt(File, "Admin", player_Admin[playerid]);
    INI_WriteInt(File, "Staff", player_Staff[playerid]);
    INI_Close(File);
    }
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	static engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);

    if (IsVehicleBicycle(GetVehicleModel(vehicleid)))
    {
        SetVehicleParamsEx(vehicleid, 1, 0, 0, doors, bonnet, boot, objective);
    }
    else
    {
        SetVehicleParamsEx(vehicleid, 0, 0, 0, doors, bonnet, boot, objective);
    }

	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
    {
        if(newkeys & KEY_LOOK_BEHIND)
        {
            new veh = GetPlayerVehicleID(playerid),
                engine,
                lights,
                alarm,
                doors,
                bonnet,
                boot,
                objective;

            if(IsVehicleBicycle(GetVehicleModel(veh)))
            {
                return true;
            }

            GetVehicleParamsEx(veh, engine, lights, alarm, doors, bonnet, boot, objective);

            if(engine == VEHICLE_PARAMS_OFF)
            {
                SetVehicleParamsEx(veh, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective);
            }
            else
            {
                SetVehicleParamsEx(veh, VEHICLE_PARAMS_OFF, lights, alarm, doors, bonnet, boot, objective);
            }

            new str[60];
            format(str, sizeof(str),""c_server"( Engine ) "c_white"%s si motor.", (engine == VEHICLE_PARAMS_OFF) ? "Upalio" : "Ugasio");
            SendClientMessage(playerid, -1, str);

            return true;
        }
        if(newkeys & KEY_YES)
        {
            new veh = GetPlayerVehicleID(playerid),
                engine,
                lights,
                alarm,
                doors,
                bonnet,
                boot,
                objective;

            if(IsVehicleBicycle(GetVehicleModel(veh)))
            {
                return true;
            }

            GetVehicleParamsEx(veh, engine, lights, alarm, doors, bonnet, boot, objective);

            if(lights == VEHICLE_PARAMS_OFF)
            {
                SetVehicleParamsEx(veh, engine, VEHICLE_PARAMS_ON, alarm, doors, bonnet, boot, objective);
            }
            else
            {
                SetVehicleParamsEx(veh, engine, VEHICLE_PARAMS_OFF, alarm, doors, bonnet, boot, objective);
            }
            new str[60];
            format(str, sizeof(str),""c_server"( Engine ) "c_white"%s si svetla.", (lights == VEHICLE_PARAMS_OFF) ? "Upalio" : "Ugasio");
            SendClientMessage(playerid, -1, str);

            return true;
        }
    }
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    SendClientMessage(playerid, -1, ""c_white"( Engine ) "c_white"Pritisnite `N` da upalite vozilo");

    return 1;
}

public e_COMMAND_ERRORS:OnPlayerCommandReceived(playerid, cmdtext[], e_COMMAND_ERRORS:success)
{
    if(success != COMMAND_OK)
	{
		SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Upisali ste ne postojecu komandu ( /help )");

        return COMMAND_OK;
    }
    return COMMAND_OK;
}

public OnPlayerText(playerid, text[])
{
	new string[128];
	format(string, sizeof string, ""c_server"%s "c_white"kaze: %s", ReturnPlayerName(playerid), text);
	ProxDetector(playerid, 30.0, -1, string);
	return 0;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(player_AdminDuty[playerid])
	{
		player_AdminDuty[playerid] = false;
		va_SendClientMessage(playerid, -1, ""c_red"[DEATH]: "c_white"Umro si, skinuta ti je Admin Duznost !");
		return 1;
	}
	return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
    if(player_GodMode[playerid]) RepairVehicle(vehicleid); SetVehicleHealth(vehicleid, 1000.0);
    return 1;
}

// ===========================================================================//

// > === timers ========================================================= > = //

timer Spawn_Player[100](playerid, type)
{
	if (type == e_SPAWN_TYPE_REGISTER)
	{
        for(new i = 0; i < 20; i++) { SendClientMessage(playerid, -1, ""); }
		SendClientMessage(playerid, -1, ""c_server"[REGISTER]: "c_white"Uspesno ste se registrovali!");
		SetSpawnInfo(playerid, 0, player_Skin[playerid],
			1093.3943,-1793.5070,13.6135,89.0326,
			0, 0, 0, 0, 0, 0
		);
		SpawnPlayer(playerid);

		SetPlayerScore(playerid, 5);
		GivePlayerMoney(playerid, 50000);
		SetPlayerSkin(playerid, 240);
		/*PlayerTextDrawSetPreviewModel(playerid, fortztde_PTD[playerid][0], GetPlayerSkin(playerid));
		PlayerTextDrawShow(playerid, fortztde_PTD[playerid][0]);*/
	}

	else if (type == e_SPAWN_TYPE_LOGIN)
	{
        for(new i = 0; i < 20; i++) { SendClientMessage(playerid, -1, ""); }
		SendClientMessage(playerid, -1, ""c_server"[LOGIN]: "c_white"Uspesno ste se prijavili!");
		SetSpawnInfo(playerid, 0, player_Skin[playerid],
			1093.3943,-1793.5070,13.6135,89.0326,
			0, 0, 0, 0, 0, 0
		);
		SpawnPlayer(playerid);

		SetPlayerScore(playerid, player_Score[playerid]);
		GivePlayerMoney(playerid, player_Money[playerid]);
		SetPlayerSkin(playerid, player_Skin[playerid]);
		/*PlayerTextDrawSetPreviewModel(playerid, fortztde_PTD[playerid][0], GetPlayerSkin(playerid));
		PlayerTextDrawShow(playerid, fortztde_PTD[playerid][0]);*/
    }
}
// ===========================================================================//

// =============== > Dialog ===================================================//
Dialog:dialog_register(playerid, response, listitem, string: inputtext[])
{
	if (!response)
		return Kick(playerid);

	if (!(MIN_PASSWORD_LENGTH <= strlen(inputtext) <= MAX_PASSWORD_LENGTH))
		return Dialog_Show(playerid, "dialog_register", DIALOG_STYLE_INPUT,
		""c_server"[REGISTER]:",
		""c_white"%s, unesite Vasu zeljenu lozinku:\nZapamtite: ne odgovaramo za ono sto se desi vasem nalogu ! ",
		"Potvrdi", "Izlaz", ReturnPlayerName(playerid)
	);
	strcopy(player_Password[playerid], inputtext);

	new INI:File = INI_Open(Account_Path(playerid));
	INI_SetTag(File,"data");
	INI_WriteString(File, "Password", player_Password[playerid]);
	INI_WriteInt(File, "Level", 5);
	INI_WriteInt(File, "Skin", 240);
	INI_WriteInt(File, "Money", 50000);
	INI_WriteInt(File, "Admin", 0);
	INI_WriteInt(File, "Staff", 0);
	INI_Close(File);

	GivePlayerMoney(playerid, 50000);
	SetPlayerScore(playerid, 5);
	SetPlayerSkin(playerid, 240);

	defer Spawn_Player(playerid, 1);


	return 1;
}

Dialog:dialog_login(const playerid, response, listitem, string: inputtext[])
{
	if (!response)
		return Kick(playerid);

	if (!strcmp(player_Password[playerid], inputtext, false))
		defer Spawn_Player(playerid, 2);
	else
	{
		if (player_LoginAttempts[playerid] == MAX_LOGIN_ATTEMPTS)
			return Kick(playerid);

		++player_LoginAttempts[playerid];
		Dialog_Show(playerid, "dialog_login", DIALOG_STYLE_PASSWORD,
			""c_server"[LOGIN]:",
			""c_white"%s, unesite Vasu tacnu lozinku:\nZapamtite: ne odgovaramo za ono sto se desi vasem nalogu ! ",
			"Potvrdi", "Izlaz", ReturnPlayerName(playerid)
		);
	}

	return 1;
}
// ===========================================================================//


/////////////////// playerstaff ////////////////////////////////////////////////
YCMD:makeadmin(playerid, const string:params[], help)= postaviadmina;
YCMD:postaviadmina(playerid, const string:params[], help)
{
	if(!IsPlayerAdmin(playerid))
	    return SendClientMessage(playerid, -1, ""c_server"[SERVER]: "c_white"Nisi ovlascen !");
	    
 	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da postavite admina igracu !");
		return 1;
 	}

	new id, level;
	if(sscanf(params, "ud", id, level))
	    return SendClientMessage(playerid, -1, ""c_server"[SERVER]: "c_white"/makeadmin [ID/Ime_Prezime] [Level]");
	if(!IsPlayerConnected(id))
	    	return SendClientMessage(playerid, -1, ""c_server"[SERVER]: "c_white"Pogresan ID !");

	if(level < 0 || level > 6)
	    return SendClientMessage(playerid, -1, ""c_server"[WARNING]: "c_white"Admin Level ne moze biti manji od 0,a veci od 6!");
	    
	player_Admin[id] = level;
	
	va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Admin %s [ID: %d] vam je postavio Admin Level %d", ReturnPlayerName(playerid), playerid, level);
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s ste postavili Admin Level %d", ReturnPlayerName(id), level);
	return 1;
}

YCMD:adminchat(playerid, const string:params[], help)= a;
YCMD:a(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"You don't have permissions for our command !");

	if(isnull(params))
	    return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/adminchat [Text]");
	    
	static
		arank[138];
	if(player_Admin[playerid] == 1) { arank = "Admin Level 1"; }
	else if(player_Admin[playerid] == 2) { arank = "Admin Level 2"; }
	else if(player_Admin[playerid] == 3) { arank = "Admin Level 3"; }
	else if(player_Admin[playerid] == 4) { arank = "Head Admin"; }
	else if(player_Admin[playerid] == 5) { arank = "Direktor"; }
	else if(player_Admin[playerid] == 6) { arank = "Vlasnik"; }

	static
		string[128];
	format(string, sizeof string, ""c_red"(AChat): "c_red"%s "c_white"%s: "c_white"%s", arank, ReturnPlayerName(playerid), params);
	
	foreach(new i: Player)
		if(player_Admin[i])
			SendClientMessage(i, -1 , string);

	return 1;
}

YCMD:setskin(playerid, const string:params[], help)= postaviskin;
YCMD:postaviskin(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 4)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nemas permisiju za koriscenje ove komande !");
 	
 	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da postavite skin igracu !");
		return 1;
	}
	    
    
    
	    
	static skinid, targetid;
	if(sscanf(params, "ui", targetid, skinid))
 	return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/setskin [ID/Ime_Prezime] [Skin ID]");
	    
	if(!IsPlayerConnected(targetid))
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");

	if(skinid < 1 || skinid > 311)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong Skin ID");
	    
	player_Skin[targetid] = skinid;
	SetPlayerSkin(targetid, skinid);
	
	va_SendClientMessage(targetid, -1, ""c_server"[NOTIFICATION]: "c_white"Admin %s vam je setovao skin ID: %d", ReturnPlayerName(playerid), skinid);
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s si setovao skin ID: %d", ReturnPlayerName(targetid), skinid);
	return 1;
}

YCMD:setstats(playerid, const string:params[], help)= pstats;
YCMD:pstats(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 5)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");
 	
 	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da postavite stats igracu !");
		return 1;
	}
	    
 	
    
    
    static targetid, vrsta, kolicina;
    if(sscanf(params, "uii", targetid, vrsta, kolicina))
	{
		SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/setstats [ID/Ime_Prezime] [Vrsta] [Kolicina]");
		SendClientMessage(playerid, -1, ""c_server"[VRSTE]: "c_white"1. Novac | 2. Level | 3. Skin");
		return true;
	}
	
	if(!IsPlayerConnected(targetid))
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");
	switch(vrsta)
	{
 	case 1:
 	{
		if(kolicina > 9999999) return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Kolicina ne moze biti iznad  9999999$");
		player_Money[targetid] = kolicina;
		GivePlayerMoney(targetid, kolicina);
		
		va_SendClientMessage(targetid, -1, ""c_server"[NOTIFICATION]: "c_white"Admin %s vam je dao Kolicinu novca %d", ReturnPlayerName(playerid), kolicina);
		va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s si setovao Kolicinu novca na %d", ReturnPlayerName(targetid), kolicina);
	}

	case 2:
	{
		if(kolicina > 50) return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Level ne moze biti iznad 50 !");
		player_Score[targetid] = kolicina;
		SetPlayerScore(targetid, kolicina);
		
		va_SendClientMessage(targetid, -1, ""c_server"[NOTIFICATION]: "c_white"Admin %s vam je dao Kolicinu levela %d", ReturnPlayerName(playerid), kolicina);
		va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s si setovao Kolicinu levela na %d", ReturnPlayerName(targetid), kolicina);
	}

	case 3:
	{
	if(kolicina > 311) return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Skin ID ne moze biti iznad  311");
		
	player_Skin[targetid] = kolicina;
	SetPlayerSkin(targetid, kolicina);

	va_SendClientMessage(targetid, -1, ""c_server"[NOTIFICATION]: "c_white"Admin %s vam je setovao skin ID: %d", ReturnPlayerName(playerid), kolicina);
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s si setovao skin ID: %d", ReturnPlayerName(targetid), kolicina);
	}

	}
	return 1;
}

YCMD:clearchat(playerid, const string:params[], help)= cc;
YCMD:cc(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	for(new i = 0; i < 145; i++) { SendClientMessageToAll(-1, ""); }
	
	va_SendClientMessageToAll(-1, ""c_server"[CLEAR-CHAT]: "c_white"Administrator %s je obrisao chat", ReturnPlayerName(playerid));
	return 1;
}

YCMD:adminduty(playerid, const string:params[], help)= aduty;
YCMD:aduty(playerid, const string:params[], help)= ad;
YCMD:ad(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");
	    
 	if(help)
	{
	SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi idete na duty !");
	return 1;
	}
	    
	if(!player_AdminDuty[playerid])
	{
		player_AdminDuty[playerid] = true;
		SetPlayerArmour(playerid, 100.0);
		SetPlayerHealth(playerid, 100.0);
		player_GodMode[playerid] = 1;

		new string[128];
		format(string, sizeof string, ""c_red"(A-DUTY) "c_white"Administrator %s je na duznosti /pitaj !", ReturnPlayerName(playerid));
		SendClientMessageToAll(-1, string);
	}
	else
	{
		if(player_AdminDuty[playerid])
		{
			player_AdminDuty[playerid] = false;
			SetPlayerArmour(playerid, 0);
			SetPlayerHealth(playerid, 100.0);
			player_GodMode[playerid] = 0;
			
			new string[128];
			format(string, sizeof string, ""c_red"(A-DUTY) "c_white"Administrator %s vise nije na duznosti !", ReturnPlayerName(playerid));
			SendClientMessageToAll(-1, string);

		}

	}
	return 1;
}

YCMD:kill(playerid, const string:params[], help)= ubij;
YCMD:ubij(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1) 
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");
	    
    if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da ubijete igraca !");
		return 1;
	}
	    
	if(!player_AdminDuty[playerid])
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
    	
    	
	static id;
	if(sscanf(params, "u", id))
    	return SendClientMessage(playerid, -1, ""c_server"[SERVER]: "c_white"/kill [ID/Ime_Prezime]");
    	
	if(!IsPlayerConnected(id))
    	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");
    	
	if(player_Admin[playerid] < player_Admin[id])
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: ne mozes ubiti veci rank od sebe !");
	    
	SetPlayerArmour(id, 0);
	SetPlayerHealth(id, 0);
	
	va_SendClientMessage(id, -1, ""c_red"Kenny Project >>> "c_white"Administrator %s vas je ubio !", ReturnPlayerName(playerid));
	va_SendClientMessage(playerid, -1, ""c_red"Kenny Project >>> "c_white"Ubio si Igraca %s", ReturnPlayerName(id));
	return 1;
}

YCMD:setlife(playerid, const string:params[], help)= postavizivot;
YCMD:postavizivot(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

    if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da postavite helte, pancir igracu!");
		return 1;
	}

	
    	
    	
	static id, life, value;
	if(sscanf(params, "uii", id, life, value))
	{
		SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/setlife [ID/Ime_Prezime] [Life] [Value]");
		SendClientMessage(playerid, -1, ""c_server"[LIFE]: "c_white"1. Health | 2. Armour | 3. All");
		return true;
	}
	if(!IsPlayerConnected(id))
    	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");

	switch(life)
	{
		case 1:
		{
		if(value > 100) return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Kolicina ne moze biti veca od 100");
		SetPlayerHealth(id, value);
		
		va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s ti je podesio helte na %d", ReturnPlayerName(playerid), value);
		va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s si podesio helte na %d", ReturnPlayerName(id), value);
		}

		case 2:
		{
			if(value > 100) return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Kolicina ne moze biti veca od 100");
			SetPlayerArmour(id, value);
			
			va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s ti je podesio pancir na %d", ReturnPlayerName(playerid), value);
			va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s si podesio pancir na %d", ReturnPlayerName(id), value);
		}
		
		case 3:
		{
            if(value > 100) return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Kolicina ne moze biti veca od 100");
            SetPlayerArmour(id, value);
            SetPlayerHealth(id, value);

			va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s ti je podesio pancir i helte na %d", ReturnPlayerName(playerid), value);
			va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s si podesio pancir i helte na %d", ReturnPlayerName(id), value);

		}
	}
	return 1;
}

YCMD:slap(playerid, const string:params[], help)= osamari;
YCMD:osamari(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
	
    	
	static id;
	if(sscanf(params, "u", id))
 	return SendClientMessage(playerid, -1, ""c_server"[SERVER]: "c_white"/slap [ID/Ime_Prezime]");

	if(!IsPlayerConnected(id))
	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");
    	
 	if(player_Admin[playerid] < player_Admin[id])
  	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Ne mozete osamariti jaci rank od vaseg!");
	    
	new Float:X, Float:Y, Float:Z, Float:health;
	GetPlayerPos(id, X, Y, Z);
	
	va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s vas je osamario ", ReturnPlayerName(playerid));
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Osamarili ste igraca %s", ReturnPlayerName(id));
	SetPlayerPos(id, X, Y, Z + 5.0);
	GetPlayerHealth(id, health);
	SetPlayerHealth(id, health-10);
	return 1;
}

YCMD:freeze(playerid, const string:params[], help)= zaledi;
YCMD:zaledi(playerid, const string:params[], help)
{
    if(player_Admin[playerid] < 1)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
	

	static id;
	if(sscanf(params, "u", id))
 	return SendClientMessage(playerid, -1, ""c_server"[SERVER]: "c_white"/freeze [ID/Ime_Prezime]");

	if(!IsPlayerConnected(id))
	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");

 	if(player_Admin[playerid] < player_Admin[id])
  	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Ne mozete freezovati jaci rank od vaseg!");
  	
  	TogglePlayerControllable(id, false);
  	
  	va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s vas je zaledio", ReturnPlayerName(playerid));
  	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Zaledio si Igraca %s", ReturnPlayerName(id));

	return 1;
}

YCMD:unfreeze(playerid, const string:params[], help)= odledi;
YCMD:odledi(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
	

	static id;
	if(sscanf(params, "u", id))
 	return SendClientMessage(playerid, -1, ""c_server"[SERVER]: "c_white"/unfreeze [ID/Ime_Prezime]");

	if(!IsPlayerConnected(id))
	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");

 	if(player_Admin[playerid] < player_Admin[id])
  	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Ne mozete unfreezovati jaci rank od vaseg!");

  	TogglePlayerControllable(id, true);

  	va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s vas je Odledio", ReturnPlayerName(playerid));
  	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Odledio si Igraca %s", ReturnPlayerName(id));

	return 1;
}

YCMD:killall(playerid, const string:params[], help)= ubijsve;
YCMD:ubijsve(playerid, const string:params[], help)
{

	if(player_Admin[playerid] < 4)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
	
	
	foreach(new i : Player)
	SetPlayerHealth(i, 0);

	static string[128];
	format(string, sizeof string, ""c_red"Kenny Project >>> "c_white"Administrator %s je ubio sve na serveru !", ReturnPlayerName(playerid));
	SendClientMessageToAll(-1, string);
	return 1;
}

YCMD:freezeall(playerid, const string:params[], help)= zaledisve;
YCMD:zaledisve(playerid, const string:params[], help)
{

	if(player_Admin[playerid] < 4)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
	

	foreach(new i : Player)
	TogglePlayerControllable(i, false);

	static string[128];
	format(string, sizeof string, ""c_red"Kenny Project >>> "c_white"Administrator %s je zaledio sve na serveru !", ReturnPlayerName(playerid));
	SendClientMessageToAll(-1, string);
	return 1;
}

YCMD:unfreezeall(playerid, const string:params[], help)= odledisve;
YCMD:odledisve(playerid, const string:params[], help)
{

	if(player_Admin[playerid] < 4)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
	

	foreach(new i : Player)
	TogglePlayerControllable(i, true);

	static string[128];
	format(string, sizeof string, ""c_red"Kenny Project >>> "c_white"Administrator %s je zaledio sve na serveru !", ReturnPlayerName(playerid));
	SendClientMessageToAll(-1, string);
	return 1;
}

YCMD:adminveh(playerid, const string:params[], help) = aveh;
YCMD:aveh(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
	
	
	new VehicleModel;
	if(sscanf(params, "i", VehicleModel))
	    return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/adminveh [Vehicle ID]");
	if(VehicleModel < 400 || VehicleModel > 611)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Vehicle Model can't be smaller of 400 and bigger than 611");

	if(player_AdminVehicle[playerid] == -1)
	{
	new Float:X, Float:Y, Float:Z;
	GetPlayerPos(playerid, X, Y, Z);
	player_AdminVehicle[playerid] = CreateVehicle(VehicleModel, X, Y, Z, 0.0, 0, 0, -1);
	PutPlayerInVehicle(playerid, player_AdminVehicle[playerid], 0);
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Stvorili ste Admin Vozilo !");
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Da upalis Auto pritisni broj 2");
	return 1;
	}
    DestroyVehicle(player_AdminVehicle[playerid]);
    player_AdminVehicle[playerid] = -1;
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Unistili ste Admin Vozilo !");
	return 1;
}

YCMD:goto(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");
 	
 	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da se teleportujete do igraca !");
		return 1;
	}

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");

	
	

	new targetid, Float:X, Float:Y, Float:Z;
	if(sscanf(params, "u", targetid))
 	return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/goto [ID/Ime_Prezime]");
 	
 	if(!IsPlayerConnected(targetid))
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID!");
 	
 	if(player_Admin[playerid] < player_Admin[targetid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Ne mozes se teleportovati do jaceg ranka !");
 	
 	if(targetid == playerid)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Ne mozes se teleportovati do samog sebe !");
 	
 	GetPlayerPos(targetid, X, Y, Z);
 	SetPlayerPos(playerid, X, Y+2, Z);
 	
 	va_SendClientMessage(targetid, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s se teleportovao do tebe !", ReturnPlayerName(playerid));
 	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Teleportovan si do igraca %s", ReturnPlayerName(targetid));

	return 1;
}

YCMD:gethere(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");
 	
 	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da teleportujete igraca do sebe!");
		return 1;
	}

	if(!player_AdminDuty[playerid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi na AdminDuty(/ad) !");


	new targetid, Float:X, Float:Y, Float:Z;
	if(sscanf(params, "u", targetid))
 	return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/gethere [ID/Ime_Prezime]");

 	if(!IsPlayerConnected(targetid))
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID!");

 	if(player_Admin[playerid] < player_Admin[targetid])
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Ne mozes teleportovati jaci rank do sebe !");

 	if(targetid == playerid)
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Ne mozes teleportovati samog sebe !");

 	GetPlayerPos(playerid, X, Y, Z);
 	SetPlayerPos(targetid, X + 2.0, Y, Z);
 	SetPlayerInterior(targetid, GetPlayerInterior(playerid));
	SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));

 	va_SendClientMessage(targetid, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s te je teleportovao do sebe !", ReturnPlayerName(playerid));
 	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Teleportovao si igraca %s do sebe", ReturnPlayerName(targetid));

	return 1;
}

YCMD:changename(playerid, const string:params[], help)= specnick;
YCMD:specnick(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 5)
	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_server"Nisi ovlascen !");

	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da promenite ime igracu !");
		return 1;
	}

	new targetid, nplayername[256];

	if(sscanf(params, "us[256]", targetid, nplayername))
	return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/changename [ID/Ime_Prezime] [Novo Ime]");

	va_SendClientMessage(targetid, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s ti je promenio ime u %s", ReturnPlayerName(playerid), nplayername);
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Igracu %s si promenio ime u %s", ReturnPlayerName(targetid), nplayername);

	SetPlayerName(targetid, nplayername);
	strmid(ReturnPlayerName(targetid), nplayername, 0, strlen(nplayername), 256);
	return 1;
}

YCMD:fine(playerid, const string:params[], help)= oduzminovac;
YCMD:oduzminovac(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 3)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: Nisi ovlascen !");
	    
	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da oduzmete novce igracu !");
		return 1;
	}
	
	new targetid, money;
	if(sscanf(params, "ui", targetid, money))
	    return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/fine [ID/Ime_Prezime] [Kolicina]");
	    
	if(!IsPlayerConnected(targetid))
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");

	GivePlayerMoney(targetid, -money);
	
	va_SendClientMessage(targetid, -1, ""c_red"[FINE]: "c_white"Administrator %s ti je oduzeo Novac | Oduzet Novac: %d", ReturnPlayerName(playerid), money);
	va_SendClientMessage(playerid, -1, ""c_red"[FINE]: "c_white"Oduzeo si igracu %s Novac | Oduzet Novac: %d", ReturnPlayerName(targetid), money);
	
	va_SendClientMessageToAll(-1, ""c_red"[FINE]: "c_white"Administrator %s je oduzeo novac igracu %s | Oduzet Novac: %d", ReturnPlayerName(playerid), ReturnPlayerName(targetid), money);
	return 1;
}

YCMD:afv(playerid, const string:params[], help)= fv;
YCMD:fv(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
  	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: Nisi ovlascen !");

	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da popravite vozilo !");
		return 1;
	}
	
	new vehicleid = GetPlayerVehicleID(playerid);
	
	if(isnull(params))
	{
	static
	    Float:X,
	    Float:Y,
	    Float:Z,
		Float:A;

	if(!IsPlayerInAnyVehicle(playerid))
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi u vozilu !");
	    
	GetPlayerPos(playerid, X, Y, Z);
	GetVehicleZAngle(vehicleid, A);
	SetVehicleZAngle(vehicleid, A);
	RepairVehicle(vehicleid);
	SetVehicleHealth(vehicleid, 1000.0);
	
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Uspesno ste Popravili vozilo !");
	}
	
	else {

		new id;
		if(sscanf(params, "u", id))
		return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/afv [ID/Ime_Prezime]");
		
		new vehiclepid = GetPlayerVehicleID(id);
		
		if(!IsPlayerConnected(id))
		return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Wrong ID");
		
		if(!IsPlayerInAnyVehicle(id))
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Igrac Nije u vozilu !");
	    
	    static Float:X, Float:Y, Float:Z, Float:A;
	    
		GetPlayerPos(id, X, Y, Z);
		GetVehicleZAngle(vehiclepid, A);
		SetVehicleZAngle(vehiclepid, A);
		RepairVehicle(vehiclepid);
		SetVehicleHealth(vehiclepid, 1000.0);
		
		va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s vam je popravio vozilo !", ReturnPlayerName(playerid));
        va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Uspesno ste Popravili vozilo Igracu %s !", ReturnPlayerName(id));
	}
	return 1;
}

YCMD:nitro(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");
	    
	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda vam daje nitro !");
		return 1;
	}

	if(isnull(params))
	{
	
	if(!IsPlayerInAnyVehicle(playerid))
	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi u vozilu !");

	AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Ugradio si Nitro !");
	}
	
	else {

		new id;
		if(sscanf(params, "u", id)) return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/nitro [ID/Ime_Prezime]");
		
		if(!IsPlayerInAnyVehicle(id))
		return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Igrac Nije u vozilu !");

		AddVehicleComponent(GetPlayerVehicleID(id), 1010);
		va_SendClientMessage(id, -1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s vam je ugradio nitro !", ReturnPlayerName(playerid));
		va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Ugradio si Nitro igracu %s !", ReturnPlayerName(id));
	}
	return 1;
}

YCMD:ao(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");
	    
	if(isnull(params))
	    return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/ao [Text]");
	    
	va_SendClientMessageToAll(-1, ""c_red"(( "c_white"Administrator %s : %s "c_red"))", ReturnPlayerName(playerid), params);
	return 1;
}

YCMD:flip(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen");
	
	if(!IsPlayerInAnyVehicle(playerid))
 	return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi u vozilu !");
 	
	new fvehicleid = GetPlayerVehicleID(playerid), Float:X, Float:Y, Float:Z, Float:CA;
	GetPlayerPos(playerid, X, Y, Z);
	SetVehiclePos(fvehicleid, X, Y, Z);
	GetVehicleZAngle(fvehicleid, CA);
	SetVehicleZAngle(fvehicleid, CA);
	RepairVehicle(fvehicleid);
	
	va_SendClientMessage(playerid, -1, ""c_server"[NOTIFICATION]: "c_white"Okrenuo si svoje vozilo !");
	return 1;
}

YCMD:kick(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 1)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");
	    
	if(help)
	{
		SendClientMessage(playerid, -1, ""c_server"[HELP]: "c_white"Ova komanda sluzi da izbacite igraca sa servera !");
		return 1;
	}
	
	new id, reason[64];
	if(sscanf(params, "us[64]", id, reason))
	    return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/kick [ID/Ime_Prezime] [Razlog]");
	    
	va_SendClientMessage(id, -1, ""c_red"[KICK]: "c_white"Administrator %s te je Izbacio sa servera | Razlog: %s", ReturnPlayerName(playerid), reason);
	va_SendClientMessage(playerid, -1, ""c_red"[KICK]: "c_white"Izbacio si Igraca %s sa servera | Razlog: %s", ReturnPlayerName(id), reason);
	
	va_SendClientMessageToAll(-1, ""c_red"[KICK]: "c_white"Administrator %s je Izbacio Igraca %s sa servera | Razlog: %s", ReturnPlayerName(playerid), ReturnPlayerName(id), reason);
	defer KickTimer[500](id);
	return 1;
}

YCMD:everyonehp(playerid, const string:params[], help)= svihp;
YCMD:svihp(playerid, const string:params[], help)
{
	if(player_Admin[playerid] < 3)
	    return SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Nisi ovlascen !");

	foreach(new i : Player) { SetPlayerHealth(i, 100.0); SetPlayerArmour(i, 100.0); }
	
	va_SendClientMessageToAll(-1, ""c_server"[NOTIFICATION]: "c_white"Administrator %s je napunio svima pancir/helte", ReturnPlayerName(playerid));
	return 1;
}
///////////////////////////////////////////////////////////////////////////////

// ==================== player commands ========================================
YCMD:b(playerid, const string:params[], help)
{
	
	if(isnull(params))
	    return SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_white"/b [Text]");
	    
	new string[128];
	format(string, sizeof string, ""c_server"(( "c_white"%s kaze: %s "c_server"))", ReturnPlayerName(playerid), params);
	ProxDetector(playerid, 30.0, -1, string);
	return 1;
}

YCMD:help(playerid, params[], help)
{
	if (help)
	{
		SendClientMessage(playerid, -1, ""c_server"[USAGE]: "c_server"[USAGE]: "c_white"/help << TYPE COMMAND >>");
	}
	else if (IsNull(params))
	{
		SendClientMessage(playerid, -1, ""c_red"[WARNING]: "c_white"Ukucaj komandu !");
	}
	else
	{
		Command_ReProcess(playerid, params, true);
	}
	return 1;
}

// ============================================================================
