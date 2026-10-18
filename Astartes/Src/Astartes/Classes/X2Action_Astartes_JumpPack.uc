//---------------------------------------------------------------------------------------
//  FILE:    X2Action_Astartes_JumpPack.uc
//  PURPOSE: Visualize a jump-pack move as an arc: leap animation, flight along a precomputed
//           ballistic path to the destination, landing animation. The game state is the vanilla
//           Icarus Jump relocation; this only replaces its teleport-style visualization.
//           Approach modelled on the Jedi Class Revised mod's Force Jump (credit in README), written
//           here against vanilla soldier animations so no other mod's content is required.
//           Animation names, play rates, arc timing and an optional ignition sound are config
//           (X2Ability_Astartes_Assault).
//---------------------------------------------------------------------------------------
class X2Action_Astartes_JumpPack extends X2Action_Move;

var vector DesiredLocation;

var private XComPrecomputedPath Path;
var private CustomAnimParams Params;
var private AnimNodeSequence PlayingSequence;
var private bool bFlying, bLanded, bSkipJump;
var private float FlightTime;
var private AudioComponent IgnitionSound;

function Init()
{
	local XComGameStateContext_Ability Context;
	local SoundCue Cue;
	local vector Empty;

	super.Init();
	Context = XComGameStateContext_Ability(StateChangeContext);
	if (DesiredLocation == Empty && Context != none && Context.InputContext.MovementPaths.Length > 0
		&& Context.InputContext.MovementPaths[0].MovementData.Length > 1)
	{
		DesiredLocation = Context.InputContext.MovementPaths[0].MovementData[Context.InputContext.MovementPaths[0].MovementData.Length - 1].Position;
	}
	if (DesiredLocation == Empty)
	{
		DesiredLocation = UnitPawn.Location;
		bSkipJump = true;
	}
	if (class'X2Ability_Astartes_Assault'.default.JUMP_SOUND_CUE != "")
	{
		Cue = SoundCue(`CONTENT.RequestGameArchetype(class'X2Ability_Astartes_Assault'.default.JUMP_SOUND_CUE));
		if (Cue != none)
		{
			IgnitionSound = CreateAudioComponent(Cue, false);
		}
	}
}

/// Build the ballistic arc from the pawn to the destination and shorten it to the configured flight time.
private function bool BuildArc()
{
	local PrecomputedPathData PathData;
	local XGWeapon Weapon;
	local XComWeapon Entity;
	local float Scale, StartZ, Diff;
	local int i;

	Path = XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).GetPrecomputedPath();
	if (Path == none)
	{
		return false;
	}
	Weapon = Unit.GetInventory().GetPrimaryWeapon();
	if (Weapon != none)
	{
		Entity = Weapon.GetEntity();
	}
	PathData.InitialPathTime = 0.8;
	PathData.MaxPathTime = 2.5;
	PathData.MaxNumberOfBounces = 0;
	Path.ActivatePath(Entity, Unit.GetTeam(), PathData);
	Path.SetHidden(true);
	Path.bUseOverrideSourceLocation = true;
	Path.OverrideSourceLocation = UnitPawn.Location;
	Path.bUseOverrideTargetLocation = true;
	Path.OverrideTargetLocation = DesiredLocation;
	Path.OverrideTargetLocation.Z = Unit.GetDesiredZForLocation(DesiredLocation);
	Path.bNoSpinUntilBounce = true;
	Path.UpdateTrajectory();
	Path.bUseOverrideSourceLocation = false;
	Path.bUseOverrideTargetLocation = false;
	Path.ClearPathGraphics();
	if (Path.iNumKeyframes <= 1)
	{
		return false;
	}

	// The grenade arc starts at the weapon's hand height; lift it so the first frame is where the pawn stands,
	// easing the correction out over the first half of the flight, then speed the whole thing up.
	StartZ = UnitPawn.Location.Z;
	Diff = Path.akKeyframes[0].vLoc.Z - StartZ;
	Scale = class'X2Ability_Astartes_Assault'.default.JUMP_ARC_TIME_SCALE;
	for (i = 0; i < Path.iNumKeyframes; i++)
	{
		if (i >= Path.iNumKeyframes / 2 && Diff > 0)
		{
			Diff = FMax(Diff - (Path.akKeyframes[0].vLoc.Z - StartZ) * 2.0 / Path.iNumKeyframes, 0.0);
		}
		Path.akKeyframes[i].vLoc.Z -= Diff;
		Path.akKeyframes[i].fTime *= Scale;
	}
	return true;
}

/// Move the pawn along the arc. True once the landing animation should start.
private function bool Fly(float Time)
{
	local XKeyframe KF;
	local vector Loc;
	local Rotator Rot;
	local float EndTime, FloorZ;

	KF = Path.ExtractInterpolatedKeyframe(Time);
	Loc = KF.vLoc;
	EndTime = Path.akKeyframes[Path.iNumKeyframes - 1].fTime;
	if (Time > EndTime * 0.5)
	{
		// never clip below the landing tile on the way down
		FloorZ = `XWORLD.GetFloorZForPosition(Path.OverrideTargetLocation, true) + UnitPawn.CollisionHeight + class'XComWorldData'.const.Cover_BufferDistance;
		Loc.Z = FMax(Loc.Z, FloorZ);
	}
	UnitPawn.SetLocation(Loc);
	Rot = UnitPawn.Rotation;
	Rot.Yaw = KF.rRot.Yaw;
	UnitPawn.SetRotation(Rot);
	return Time >= EndTime - FMin(class'X2Ability_Astartes_Assault'.default.JUMP_LANDING_LEAD, EndTime * 0.5);
}

simulated state Executing
{
	simulated event Tick(float DeltaTime)
	{
		if (bFlying)
		{
			FlightTime += DeltaTime;
			if (Fly(FlightTime))
			{
				bLanded = true;
			}
		}
	}

Begin:
	if (bSkipJump || !BuildArc())
	{
		UnitPawn.SetLocation(DesiredLocation);
		Unit.ProcessNewPosition();
		CompleteAction();
	}

	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bSkipIK = true;

	// leap
	Params = default.Params;
	Params.AnimName = class'X2Ability_Astartes_Assault'.default.JUMP_ANIM_START;
	Params.PlayRate = class'X2Ability_Astartes_Assault'.default.JUMP_START_PLAYRATE;
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	if (IgnitionSound != none)
	{
		IgnitionSound.Play();
	}
	if (PlayingSequence != none)
	{
		Sleep(FMax(PlayingSequence.GetAnimPlaybackLength() * class'X2Ability_Astartes_Assault'.default.JUMP_START_FRACTION, 0.05));
	}

	// flight
	bFlying = true;
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	Params = default.Params;
	Params.AnimName = class'X2Ability_Astartes_Assault'.default.JUMP_ANIM_LOOP;
	Params.Looping = true;
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	while (!bLanded)
	{
		Sleep(0.0);
	}
	bFlying = false;
	if (PlayingSequence != none)
	{
		PlayingSequence.StopAnim();
	}

	// landing
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	UnitPawn.SetLocation(Path.OverrideTargetLocation);
	UnitPawn.SnapToGround();
	Params = default.Params;
	Params.AnimName = class'X2Ability_Astartes_Assault'.default.JUMP_ANIM_STOP;
	Params.PlayRate = class'X2Ability_Astartes_Assault'.default.JUMP_STOP_PLAYRATE;
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	if (PlayingSequence != none)
	{
		FinishAnim(PlayingSequence);
	}
	if (IgnitionSound != none)
	{
		IgnitionSound.Stop();
	}
	UnitPawn.bSkipIK = false;
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	Unit.ProcessNewPosition();
	CompleteAction();
}
