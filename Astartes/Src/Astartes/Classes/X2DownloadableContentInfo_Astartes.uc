//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo_Astartes.uc
//  PURPOSE: Entry point for the Warhammer 40K overhaul. Campaign-start hooks and
//           Highlander event registration live here.
//---------------------------------------------------------------------------------------
class X2DownloadableContentInfo_Astartes extends X2DownloadableContentInfo;

/// Called when the player starts a new campaign while this mod is installed.
static event InstallNewCampaign(XComGameState StartState)
{
	`log("Astartes: new campaign started",, 'Astartes');
}

/// Called when the player loads a saved game that was created without this mod.
static event OnLoadedSavedGame()
{
	`log("Astartes: loaded a save created without this mod",, 'Astartes');
}

/// Called once all mods' templates exist. Use for edits that must run after every CreateTemplates.
static event OnPostTemplatesCreated()
{
	`log("Astartes: OnPostTemplatesCreated",, 'Astartes');
}
