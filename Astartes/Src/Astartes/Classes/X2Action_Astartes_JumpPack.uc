//---------------------------------------------------------------------------------------
//  FILE:    X2Action_Astartes_JumpPack.uc
//  PURPOSE: Visualize a jump-pack move as an arc: leap animation, flight along a parabola to the
//           destination, landing animation. The game state is the vanilla Icarus Jump relocation;
//           this only replaces its teleport-style visualization.
//           Approach modelled on the Jedi Class Revised mod's Force Jump (credit in README), written
//           here against vanilla soldier animations and a self-computed arc, so no other mod's
//           content and no shared engine path object is involved (the shared grenade path sent the
//           first version to the world origin). Animation names, play rates, arc shape and an
//           optional ignition sound are config (X2Ability_Astartes_Assault).
//---------------------------------------------------------------------------------------
class X2Action_Astartes_JumpPack extends X2Action_Move;

var vector DesiredLocation;

var private vector StartLocation, EndLocation;
var private float FlightDuration, ApexHeight, FlightTime;
var private CustomAnimParams Params;
var private AnimNodeSequence PlayingSequence;
var private bool bFlying, bLanded, bSkipJump;
var private AudioComponent IgnitionSound;

function Init()
{
	local SoundCue Cue;

	super.Init();
	if (class'X2Ability_Astartes_Assault'.default.JUMP_SOUND_CUE != "")
	{
		Cue = SoundCue(`CONTENT.RequestGameArchetype(class'X2Ability_Astartes_Assault'.default.JUMP_SOUND_CUE));
		if (Cue != none)
		{
			IgnitionSound = CreateAudioComponent(Cue, false);
		}
	}
}

/// The landing spot: what the visualization gave us, else the end of the ability's movement path.
private function ResolveDestination()
{
	local XComGameStateContext_Ability Context;
	local vector Empty;
	local int Last;

	Context = XComGameStateContext_Ability(StateChangeContext);
	if (DesiredLocation == Empty && Context != none && Context.InputContext.MovementPaths.Length > 0)
	{
		Last = Context.InputContext.MovementPaths[0].MovementData.Length - 1;
		if (Last > 0)
		{
			DesiredLocation = Context.InputContext.MovementPaths[0].MovementData[Last].Position;
		}
	}
	if (DesiredLocation == Empty && Context != none && Context.InputContext.TargetLocations.Length > 0)
	{
		DesiredLocation = Context.InputContext.TargetLocations[0];
	}
	if (DesiredLocation == Empty)
	{
		DesiredLocation = UnitPawn.Location;
		bSkipJump = true;
	}
	`log("Astartes: jump from" @ UnitPawn.Location @ "to" @ DesiredLocation @ (bSkipJump ? "(no destination: skipping)" : ""),, 'Astartes');
}

/// Start and end at pawn height on their tiles; flight time and apex scale with the distance.
private function BuildArc()
{
	local float Tiles;

	StartLocation = UnitPawn.Location;
	EndLocation = DesiredLocation;
	EndLocation.Z = `XWORLD.GetFloorZForPosition(DesiredLocation, true) + UnitPawn.CollisionHeight + class'XComWorldData'.const.Cover_BufferDistance;

	Tiles = VSize2D(EndLocation - StartLocation) / class'XComWorldData'.const.WORLD_StepSize;
	FlightDuration = FClamp(Tiles * class'X2Ability_Astartes_Assault'.default.JUMP_SECONDS_PER_TILE,
		class'X2Ability_Astartes_Assault'.default.JUMP_MIN_FLIGHT_SECONDS, class'X2Ability_Astartes_Assault'.default.JUMP_MAX_FLIGHT_SECONDS);
	ApexHeight = FMax(class'X2Ability_Astartes_Assault'.default.JUMP_ARC_HEIGHT_TILES * class'XComWorldData'.const.WORLD_FloorHeight,
		Abs(EndLocation.Z - StartLocation.Z) * 0.5);
}

/// Place the pawn on the parabola at Time. True once the landing animation should start.
private function bool Fly(float Time)
{
	local float T, Lead;
	local vector Loc, Dir;
	local Rotator Rot;

	T = FClamp(Time / FlightDuration, 0.0, 1.0);
	Loc = StartLocation + (EndLocation - StartLocation) * T;
	Loc.Z += ApexHeight * 4.0 * T * (1.0 - T);
	UnitPawn.SetLocation(Loc);

	Dir = EndLocation - StartLocation;
	Dir.Z = 0;
	if (VSizeSq(Dir) > 1.0)
	{
		Rot = UnitPawn.Rotation;
		Rot.Yaw = Rotator(Dir).Yaw;
		UnitPawn.SetRotation(Rot);
	}
	Lead = FMin(class'X2Ability_Astartes_Assault'.default.JUMP_LANDING_LEAD, FlightDuration * 0.5);
	return Time >= FlightDuration - Lead;
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

	/// Play a full-body animation if this pawn has it (a jump animation pack may be absent). None otherwise.
	function AnimNodeSequence PlayIfAvailable(name AnimName, float Rate, bool bLoop)
	{
		if (AnimName == '' || !UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimName))
		{
			if (AnimName != '')
			{
				`log("Astartes: jump animation" @ AnimName @ "not on this pawn (jump animation pack not loaded?); flying without it",, 'Astartes');
			}
			return none;
		}
		Params = default.Params;
		Params.AnimName = AnimName;
		Params.PlayRate = Rate;
		Params.Looping = bLoop;
		return UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	}

Begin:
	ResolveDestination();
	if (bSkipJump)
	{
		UnitPawn.SetLocation(DesiredLocation);
		Unit.ProcessNewPosition();
		CompleteAction();
	}
	BuildArc();

	// Root motion stays OFF throughout: we place the pawn ourselves. Vanilla climb/fall animations carry root
	// motion of their own and dragged the pawn to the world origin (playtest 2026-10-18); the configured jump
	// animations must be authored without it (the Jedi Class Revised set is).
	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.bSkipIK = true;

	// leap
	PlayingSequence = PlayIfAvailable(class'X2Ability_Astartes_Assault'.default.JUMP_ANIM_START, class'X2Ability_Astartes_Assault'.default.JUMP_START_PLAYRATE, false);
	if (IgnitionSound != none)
	{
		IgnitionSound.Play();
	}
	if (PlayingSequence != none)
	{
		Sleep(FMax(PlayingSequence.GetAnimPlaybackLength() * class'X2Ability_Astartes_Assault'.default.JUMP_START_FRACTION, 0.05));
	}

	// flight
	StartLocation = UnitPawn.Location;
	bFlying = true;
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	PlayingSequence = PlayIfAvailable(class'X2Ability_Astartes_Assault'.default.JUMP_ANIM_LOOP, 1.0, true);
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
	UnitPawn.SetLocation(EndLocation);
	UnitPawn.SnapToGround();
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	PlayingSequence = PlayIfAvailable(class'X2Ability_Astartes_Assault'.default.JUMP_ANIM_STOP, class'X2Ability_Astartes_Assault'.default.JUMP_STOP_PLAYRATE, false);
	if (PlayingSequence != none)
	{
		FinishAnim(PlayingSequence);
	}
	if (IgnitionSound != none)
	{
		IgnitionSound.Stop();
	}
	UnitPawn.bSkipIK = false;
	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	UnitPawn.SetLocation(EndLocation);
	UnitPawn.SnapToGround();
	Unit.ProcessNewPosition();
	`log("Astartes: jump landed; pawn at" @ UnitPawn.Location @ "flight" @ FlightDuration $ "s apex" @ ApexHeight,, 'Astartes');
	CompleteAction();
}
