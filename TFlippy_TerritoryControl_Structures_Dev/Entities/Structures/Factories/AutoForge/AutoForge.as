﻿#include "MakeMat.as";

void onInit(CSprite@ this)
{
	// Building
	this.SetZ(-50); //-60 instead of -50 so sprite layers are behind ladders
}

const string[] matNames = { 
	"mat_copper",
	"mat_iron",
	"mat_gold",
	"mat_wood"
};

const string[] matNamesResult = { 
	"mat_copperingot",
	"mat_ironingot",
	"mat_goldingot",
	"mat_coal"
};

const int[] matRatio = { 
	5,
	5,
	25,
	10
};

const int[] matResult = { 
	1,
	1,
	2,
	1
};

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
}

void onTick(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 60 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
	
	if (this.hasBlob("mat_ironingot", 2) && this.hasBlob("mat_coal", 2)) //steel ingots require coal to be created
	{
		if (isServer())
		{
			CBlob@ mat = server_CreateBlob("mat_steelingot", -1, this.getPosition());
			mat.server_SetQuantity(1);
			mat.Tag("justmade");
			this.TakeBlob("mat_ironingot", 2);
			this.TakeBlob("mat_coal", 2);
		}
		if (isClient())
		{
			this.getSprite().PlaySound("ProduceSound.ogg");
			this.getSprite().PlaySound("BombMake.ogg");
		}
	}
	for (int i = 0; i < matNames.length; i++)
	{
		if (this.hasBlob(matNames[i], matRatio[i]))
		{
			if (isServer())
			{
				CBlob@ mat = server_CreateBlob(matNamesResult[i], -1, this.getPosition());
				mat.server_SetQuantity(matResult[i]);
				mat.Tag("justmade");
				this.TakeBlob(matNames[i], matRatio[i]);
			}
			if (isClient())
			{
				this.getSprite().PlaySound("ProduceSound.ogg");
				this.getSprite().PlaySound("BombMake.ogg");
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	if (blob.hasTag("justmade"))
	{
		blob.Untag("justmade");
		return;
	}
	
	if (!blob.isAttached() && blob.hasTag("material"))
	{
		string config = blob.getName();
		for (int i = 0; i < matNames.length; i++)
		{
			if (config == matNames[i] || config == "mat_ironingot" || config == "mat_coal")
			{
				if (isServer()) this.server_PutInInventory(blob);
				if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	// return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this));
	return forBlob !is null && forBlob.isOverlapping(this);
}