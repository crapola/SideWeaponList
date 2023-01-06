/*
This mutator adds a new colored weapon list to the HUD.
Made with help from
https://wiki.beyondunreal.com/Legacy:Useful_Mutator_Functions#HUD_Mutators.
*/

class SideWeaponListMutator extends Mutator;

var Color white;
var PlayerPawn owner;
var float scale;
var Font my_font;
var bool invert_order;

simulated function PostBeginPlay() {
	Log("SideWeaponListMutator PostBeginPlay().");
	my_font=class'FontInfo'.static.GetStaticMediumFont(1920);
	Super.PostBeginPlay();
}

simulated function Tick(float dt) {
	if ( !bHUDMutator && Level.NetMode != NM_DedicatedServer ) {
		RegisterHUDMutator();
		Log("SideWeaponListMutator registered.");
	}
}

function Mutate(string string, PlayerPawn sender)
{
	if (sender==owner && string=="sidelist") {
		invert_order=!invert_order;
		Log("SideWeaponListMutator invert:"@invert_order);
	}
	Super.Mutate(string,sender);
}

function GetListPos(Canvas c,out int x,out int y) {
	x=c.ClipX-256*scale;
	y=c.ClipY-128*scale;
}

simulated function PostRender(Canvas c)
{
	local Weapon w;
	local int i,j,k;
	local Inventory inv;
	local int x,y;
	local float xl,yl;
	local string txt;
	local Weapon stuff[32];
	local int stuff_count;

	if (owner==None) {
		owner=c.Viewport.Actor;
		//owner=None;
		if (owner==None) {
			c.DrawColor.R=255;
			c.DrawColor.G=0;
			c.DrawColor.B=0;
			c.DrawText("SideWeaponListMutator error: owner is none.");
			//Warn("SideWeaponListMutator error: owner is none.");
			return;
		}
		scale=ChallengeHUD(owner.MyHUD).Scale;
	}

	// Build list of weapons sorted by InventoryGroup.
	i=0;
	for (inv=owner.Inventory;inv!=None;inv=inv.Inventory) {
		if (inv.IsA('Weapon')) {
			w=Weapon(inv);
			j=0;
			// Check if below one of the items in list.
			for (j=0;j<i;j++) {
				if (inv.InventoryGroup<stuff[j].InventoryGroup) {
					// Shift all items to the right.
					for (k=i;k>j;k--) {
						stuff[k]=stuff[k-1];
					}
					stuff[j]=Weapon(inv);
					break;
				}
			}
			// Otherwise append it.
			if (j==i) {
				stuff[i]=Weapon(inv);
			}
			i++;
			if (i>=32)
				break;
		}
	}
	stuff_count=i;

	c.Reset();
	c.DrawColor=white;
	c.Font=my_font;
	// Draw everything.
	for (i=0;i<stuff_count;i++) {
			w=stuff[i];
			if (invert_order)
				w=stuff[stuff_count-1-i];
			GetListPos(c,x,y);
			c.StrLen(w.ItemName,xl,yl);
			txt=w.ItemName;
			if (w.AmmoType!=None) {
				txt=txt@w.AmmoType.AmmoAmount;
			}
			// Selection chevron.
			if (w==owner.Weapon) {
				c.DrawColor=white;
				c.SetPos(x-16,y-i*yl);
				c.DrawText(">");
			}
			// Pending selection chevron.
			if (w==owner.PendingWeapon) {
				c.DrawColor=0.5*white;
				c.SetPos(x-16,y-i*yl);
				c.DrawText(">");
			}
			// Item name and ammo.
			c.DrawColor=w.NameColor;
			if (w.AmmoType!=None && w.AmmoType.AmmoAmount==0) {
				c.DrawColor=0.25*c.DrawColor;
			}
			c.SetPos(x,y-i*yl);
			c.DrawText(txt);
	}

	if ( NextHUDMutator != None )
		NextHUDMutator.PostRender(c);
}

defaultproperties {
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bNetTemporary=True
	white=(R=255,G=255,B=255)
	invert_order=False
}