//---------------------------------------------------------------------------------------
//  FILE:    X2Action_Astartes_JumpPack.uc
//  PURPOSE: Visualize a jump-pack move as an arc: leap animation, flight along a parabola to the
//           destination, landing animation. The game state is the vanilla Icarus Jump relocation;
//           this only replaces its teleport-style visualization.
//           Approach modelled on the Jedi Class Revised mod's Force Jump (credit in README), written
//           here against vanilla soldier animations and a self-computed arc, so no other mod's
//           content and no shared engine path object is involved (the shared grenade path sent the
//           first version to the world origin). Animation names, play rates, arc shape and an
//           optional ignition sound are config (X2Ability_Astartes_Assault). Jet sounds and flames are the
//           Alien Hunters Icarus Suit assets by default (vanilla DLC content), also config.
//---------------------------------------------------------------------------------------
class X2Action_Astartes_JumpPack extends X2Action_Move;

var vector DesiredLocation;

var private vector StartLocation, EndLocation;
var private float FlightDuration, ApexHeight, FlightTime;
var private CustomAnimParams Params;
var private AnimNodeSequence PlayingSequence;
var private bool bFlying, bLanded, bSkipJump;
var private AudioComponent IgnitionSound;
var private AkEvent TakeoffSound, FlightSound, LandSound;
var private ParticleSystem TakeoffFX, LandFX;
var private array<ParticleSystem> ThrusterFX;
var private array<ParticleSystemComponent> Thrusters;

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
	TakeoffSound = LoadSound(class'X2Ability_Astartes_Assault'.default.JUMP_TAKEOFF_SOUND);
	FlightSound = LoadSound(class'X2Ability_Astartes_Assault'.default.JUMP_FLIGHT_SOUND);
	LandSound = LoadSound(class'X2Ability_Astartes_Assault'.default.JUMP_LAND_SOUND);
	TakeoffFX = LoadFX(class'X2Ability_Astartes_Assault'.default.JUMP_TAKEOFF_FX);
	LandFX = LoadFX(class'X2Ability_Astartes_Assault'.default.JUMP_LAND_FX);
	LoadThrusters();
}

private function AkEvent LoadSound(string Path)
{
	local AkEvent Event;

	if (Path == "")
	{
		return none;
	}
	Event = AkEvent(DynamicLoadObject(Path, class'AkEvent'));
	if (Event == none)
	{
		`log("Astartes: jump sound" @ Path @ "not found; flying without it",, 'Astartes');
	}
	return Event;
}

private function ParticleSystem LoadFX(string Path)
{
	local ParticleSystem System;

	if (Path == "")
	{
		return none;
	}
	System = ParticleSystem(DynamicLoadObject(Path, class'ParticleSystem'));
	if (System == none)
	{
		`log("Astartes: jump effect" @ Path @ "not found; flying without it",, 'Astartes');
	}
	return System;
}

private function LoadThrusters()
{
	local int i;
	local ParticleSystem System;

	for (i = 0; i < class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS.Length; i++)
	{
		System = LoadFX(class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS[i].FX);
		if (System != none)
		{
			ThrusterFX.AddItem(System);
		}
	}
}

private function PlayJumpSound(AkEvent Event)
{
	if (Event != none)
	{
		UnitPawn.PlayAkEvent(Event);
	}
}

/// A one-shot effect at the pawn's feet.
private function SpawnBurst(ParticleSystem System, vector At)
{
	if (System != none)
	{
		At.Z -= UnitPawn.CollisionHeight;
		WorldInfo.MyEmitterPool.SpawnEmitter(System, At, UnitPawn.Rotation);
	}
}

/// Thruster flames ride the configured bone for the whole flight (the pawn itself if the bone is missing).
private function StartThrusters()
{
	local ParticleSystemComponent Component;
	local name Bone;
	local vector Offset;
	local bool bOnBone;
	local int i;
	local array<name> Bones;
	local string Candidates;

	Bone = class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTER_BONE;
	bOnBone = Bone != '' && UnitPawn.Mesh.MatchRefBone(Bone) != INDEX_NONE;
	if (Bone != '' && !bOnBone)
	{
		UnitPawn.Mesh.GetBoneNames(Bones);
		for (i = 0; i < Bones.Length; i++)
		{
			if (InStr(Caps(string(Bones[i])), "SPINE") != INDEX_NONE || InStr(Caps(string(Bones[i])), "TORSO") != INDEX_NONE || InStr(Caps(string(Bones[i])), "CHEST") != INDEX_NONE || InStr(Caps(string(Bones[i])), "BACK") != INDEX_NONE || InStr(Caps(string(Bones[i])), "PELVIS") != INDEX_NONE)
			{
				Candidates @= string(Bones[i]);
			}
		}
		`log("Astartes: jump thruster bone" @ Bone @ "not on this pawn (" $ Bones.Length @ "bones; torso candidates:" @ Candidates $ "); flames attached to the pawn instead",, 'Astartes');
	}
	for (i = 0; i < ThrusterFX.Length; i++)
	{
		Offset = class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS[Min(i, class'X2Ability_Astartes_Assault'.default.JUMP_THRUSTERS.Length - 1)].Offset;
		if (bOnBone)
		{
			Component = WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(ThrusterFX[i], UnitPawn.Mesh, Bone, false, Offset);
		}
		else
		{
			Component = WorldInfo.MyEmitterPool.SpawnEmitter(ThrusterFX[i], UnitPawn.Location + (Offset >> UnitPawn.Rotation), UnitPawn.Rotation, UnitPawn);
		}
		if (Component != none)
		{
			Thrusters.AddItem(Component);
		}
	}
}

private function StopThrusters()
{
	local int i;

	for (i = 0; i < Thrusters.Length; i++)
	{
		Thrusters[i].DeactivateSystem();
	}
	Thrusters.Length = 0;
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

	// leap: ignition sound and launch burst at the feet
	PlayJumpSound(TakeoffSound);
	SpawnBurst(TakeoffFX, UnitPawn.Location);
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
	StartThrusters();
	PlayJumpSound(FlightSound);
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

	// landing: flames off, landing sound, hover burst at the feet
	StopThrusters();
	UnitPawn.SetLocation(EndLocation);
	UnitPawn.SnapToGround();
	PlayJumpSound(LandSound);
	SpawnBurst(LandFX, UnitPawn.Location);
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
