#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smartdm>
#include <shop>

#define PLUGIN_VERSION	"2.1.1"
#define CATEGORY	"stuff"
#define ITEM	"paintball"

new g_clientsPaintballEnabled[MAXPLAYERS+1];
new Handle:g_hPrice, g_iPrice;
new Handle:g_hSellPrice, g_iSellPrice;
new Handle:g_hDuration, g_iDuration;
new Handle:g_hArrayMaterials;

new ItemId:id;

public Plugin:myinfo =
{
	name		= "[Shop] PaintBall",
	author		= "FrozDark (HLModders LLC)",
	description = "Paintball component for Shop",
	version		= PLUGIN_VERSION,
	url			 = "www.hlmod.ru"
};

public OnPluginStart()
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

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
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

public OnPluginEnd()
{
	Shop_UnregisterMe();
}

public Shop_Started()
{
	new CategoryId:category_id = Shop_RegisterCategory(CATEGORY, "PaintBall", "", OnCategoryDisplay, OnCategoryDescription);
	if (Shop_StartItem(category_id, ITEM))
	{
		Shop_SetInfo("Paintball", "", g_iPrice, g_iSellPrice, Item_Togglable, g_iDuration);
		Shop_SetCallbacks(OnItemRegistered, OnPaintballUsed, _, OnDisplay, OnDescription);
		Shop_EndItem();
	}
}

public bool:OnCategoryDisplay(client, CategoryId:category_id, const String:category[], const String:name[], String:buffer[], maxlen)
{
	FormatEx(buffer, maxlen, "%T", "display", client);
	return true;
}

public bool:OnCategoryDescription(client, CategoryId:category_id, const String:category[], const String:description[], String:buffer[], maxlen)
{
	FormatEx(buffer, maxlen, "%T", "description", client);
	return true;
}

public OnItemRegistered(CategoryId:category_id, const String:category[], const String:item[], ItemId:item_id)
{
	id = item_id;
}

public bool:OnDisplay(client, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[], ShopMenu:menu, &bool:disabled, const String:name[], String:buffer[], maxlen)
{
	FormatEx(buffer, maxlen, "%T", "paintball", client);
	return true;
}

public bool:OnDescription(client, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[], ShopMenu:menu, const String:description[], String:buffer[], maxlen)
{
	FormatEx(buffer, maxlen, "%T", "paintball_description", client);
	return true;
}

public OnMapStart()
{
	decl String:buffer[PLATFORM_MAX_PATH];
	Shop_GetCfgFile(buffer, sizeof(buffer), "paintball.txt");
	
	new Handle:filehandle = OpenFile(buffer, "r");
	
	if (filehandle == INVALID_HANDLE)
	{
		ThrowError("%s not parsed... file doesn't exist!", buffer);
	}
	
	ClearArray(g_hArrayMaterials);
		
	while (!IsEndOfFile(filehandle))
	{
		if (!ReadFileLine(filehandle,buffer,sizeof(buffer)))
			continue;
	
		new pos;
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

public OnClientDisconnect_Post(client)
{
	g_clientsPaintballEnabled[client] = false;
}

public ShopAction:OnPaintballUsed(client, CategoryId:category_id, const String:category[], ItemId:item_id, const String:item[], bool:isOn, bool:elapsed)
{
	g_clientsPaintballEnabled[client] = !isOn;
	if (isOn || elapsed)
	{
		return Shop_UseOff;
	}
	return Shop_UseOn;
}

public Event_BulletImpact(Handle:event, const String:weaponName[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
 	if (!client || !g_clientsPaintballEnabled[client])
	{
		return;
	}
	new size = GetArraySize(g_hArrayMaterials);
	if (!size)
	{
		return;
	}
	
	decl Float:bulletDestination[3];//, Float:ang[3];
	bulletDestination[0] = GetEventFloat(event, "x");
	bulletDestination[1] = GetEventFloat(event, "y");
	bulletDestination[2] = GetEventFloat(event, "z");
	
	new index = GetArrayCell(g_hArrayMaterials, Math_GetRandomInt(0, size-1));
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

stock TE_SetupWorldDecal(const Float:vecOrigin[3], index)
{    
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin",vecOrigin);
    TE_WriteNum("m_nIndex",index);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) 
{
 	return (entity < 1 && entity > MaxClients);
}

stock Math_GetRandomInt(min, max)
{
	new random = GetURandomInt();
	
	if (!random)
		random++;
		
	new number = RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
	
	return number;
}