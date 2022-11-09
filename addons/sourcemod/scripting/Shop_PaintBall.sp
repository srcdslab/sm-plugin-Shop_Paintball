#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <smartdm>
#include <shop>

#define PLUGIN_VERSION	"2.1.2"
#define CATEGORY	"stuff"
#define ITEM	"paintball"

bool g_clientsPaintballEnabled[MAXPLAYERS + 1];

ConVar g_hPrice
	, g_hSellPrice
	, g_hDuration;

ArrayList g_hArrayMaterials;

int g_iPrice
	, g_iSellPrice
	, g_iDuration;

ItemId id;

public Plugin myinfo =
{
	name		= "[Shop] PaintBall",
	author		= "FrozDark (HLModders LLC)",
	description = "Paintball component for Shop",
	version		= PLUGIN_VERSION,
	url			 = "www.hlmod.ru"
};

public void OnPluginStart()
{
	g_hPrice = CreateConVar("sm_shop_paintball_price", "500", "Price for the paintball.");
	g_iPrice = GetConVarInt(g_hPrice);
	HookConVarChange(g_hPrice, OnConVarChange);
	
	g_hSellPrice = CreateConVar("sm_shop_paintball_sellprice", "250", "Sell price for the paintball. -1 to make unsaleable");
	g_iSellPrice = GetConVarInt(g_hSellPrice);
	HookConVarChange(g_hSellPrice, OnConVarChange);
	
	g_hDuration = CreateConVar("sm_shop_paintball_duration", "86400", "The paintball duration. 0 to make it forever");
	g_iDuration = GetConVarInt(g_hDuration);
	HookConVarChange(g_hDuration, OnConVarChange);
	
	g_hArrayMaterials = CreateArray();
	
	HookEvent("bullet_impact", Event_BulletImpact);	
	
	AutoExecConfig(true, "shop_paintball", "shop");
	LoadTranslations("shop_paintball.phrases");
	
	if (Shop_IsStarted()) Shop_Started();
}

public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hPrice)
	{
		g_iPrice = StringToInt(newValue);
		if (id != INVALID_ITEM)
		{
			Shop_SetItemPrice(id, g_iPrice);
		}
	}
	else if (convar == g_hSellPrice)
	{
		g_iSellPrice = StringToInt(newValue);
		if (id != INVALID_ITEM)
		{
			Shop_SetItemSellPrice(id, g_iSellPrice);
		}
	}
	else if (convar == g_hDuration)
	{
		g_iDuration = StringToInt(newValue);
		if (id != INVALID_ITEM)
		{
			Shop_SetItemValue(id, g_iDuration);
		}
	}
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void Shop_Started()
{
	CategoryId category_id = Shop_RegisterCategory(CATEGORY, "PaintBall", "Shoot colored bullets", OnCategoryDisplay, OnCategoryDescription);
	if (Shop_StartItem(category_id, ITEM))
	{
		Shop_SetInfo("Paintball", "", g_iPrice, g_iSellPrice, Item_Togglable, g_iDuration);
		Shop_SetCallbacks(OnItemRegistered, OnPaintballUsed, _, OnDisplay, OnDescription);
		Shop_EndItem();
	}
}

public bool OnCategoryDisplay(int client, CategoryId category_id, const char[] category, const char[] name, char[] buffer, int maxlen, ShopMenu menu)
{
	FormatEx(buffer, maxlen, "%T", "display", client);
	return true;
}

public bool OnCategoryDescription(int client, CategoryId category_id, const char[] category, const char[] description, char[] buffer, int maxlen, ShopMenu menu)
{
	FormatEx(buffer, maxlen, "%T", "description", client);
	return true;
}

public void OnItemRegistered(CategoryId category_id, const char[] category, const char[] item, ItemId item_id)
{
	id = item_id;
}

public bool OnDisplay(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, bool &disabled, const char[] name, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%T", "paintball", client);
	return true;
}

public bool OnDescription(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, const char[] description, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%T", "paintball_description", client);
	return true;
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(buffer, sizeof(buffer), "paintball.txt");
	
	Handle filehandle = OpenFile(buffer, "r");
	
	if (filehandle == INVALID_HANDLE)
	{
		ThrowError("%s not parsed... file doesn't exist!", buffer);
	}
	
	ClearArray(g_hArrayMaterials);
		
	while (!IsEndOfFile(filehandle))
	{
		if (!ReadFileLine(filehandle,buffer,sizeof(buffer)))
			continue;
	
		int pos;
		pos = StrContains((buffer), "//");
		if (pos != -1)
		{
			buffer[pos] = '\0';
		}
	
		pos = StrContains((buffer), "#");
		if (pos != -1)
		{
			buffer[pos] = '\0';
		}
			
		pos = StrContains((buffer), ";");
		if (pos != -1)
		{
			buffer[pos] = '\0';
		}
	
		TrimString(buffer);
		
		if (buffer[0] == '\0')
		{
			continue;
		}
		
		Downloader_AddFileToDownloadsTable(buffer);
		PushArrayCell(g_hArrayMaterials, PrecacheDecal(buffer[10]));
	}
}

public void OnClientDisconnect(int client)
{
	g_clientsPaintballEnabled[client] = false;
}

public ShopAction OnPaintballUsed(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	g_clientsPaintballEnabled[client] = !isOn;
	if (isOn || elapsed)
	{
		return Shop_UseOff;
	}
	return Shop_UseOn;
}

public void Event_BulletImpact(Event event, const char[] weaponName, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
 	if (!client || !g_clientsPaintballEnabled[client])
	{
		return;
	}
	int size = GetArraySize(g_hArrayMaterials);
	if (!size)
	{
		return;
	}
	
	float bulletDestination[3];//, Float:ang[3];
	bulletDestination[0] = GetEventFloat(event, "x");
	bulletDestination[1] = GetEventFloat(event, "y");
	bulletDestination[2] = GetEventFloat(event, "z");
	
	int index = GetArrayCell(g_hArrayMaterials, Math_GetRandomInt(0, size-1));
	TE_SetupWorldDecal(bulletDestination, index);
	TE_SendToAll();
	
	/*decl Float:fOrigin[3];
	GetClientEyePosition(client, fOrigin);
	
	MakeVectorFromPoints(fOrigin, bulletDestination, ang);
	
	new Handle:trace = TR_TraceRayFilterEx(fOrigin, ang, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(bulletDestination, trace);
		//TE_SetupGlowSprite(bulletDestination, index, 300.0, 0.2, 200);
	}
	
	CloseHandle(trace);*/
}

stock bool TE_SetupWorldDecal(const float vecOrigin[3], int index)
{    
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("m_nIndex",index);
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask) 
{
 	return (entity < 1 && entity > MaxClients);
}

stock int Math_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();
	
	if (!random)
		random++;
		
	int number = RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
	
	return number;
}