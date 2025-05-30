﻿unit RSM.Config;

interface

type
  TRSMConfig = class
  private
  { Private Types }
    // UI
    type
      TRSMConfigIU = record // Saved on main form destroy event except nav, serverinfo
        navIndex: Integer;  // Saved on index change
        windowPosX: Integer;
        windowPosY: Integer;
        windowHeight: Single;
        windowWidth: Single;
        ShowServerInfoPanel: Boolean; // Saved on btnShowHideServerInfoClick
        serverInstallerBranchIndex: Integer; // Item index for server installer branch
       // quickServerControls: Boolean; // Quick Server controls under server info
      end;
    // Tray Icon
    type
      TRSMConfigTrayIcon = record
        Enabled: Boolean;
        Title: string;
        AppTitle: string;
      end;
      // Auto Restart Server
    type
      TRSMConfigAutoRestartItem = record
        Enabled: Boolean;
        Time: TTime;
        WarningTimeSecs: Integer;
      end;
    type
      TRSMConfigAutoRestart = record
        AutoRestart1: TRSMConfigAutoRestartItem;
        AutoRestart2: TRSMConfigAutoRestartItem;
        AutoRestart3: TRSMConfigAutoRestartItem;
      end;
      // Misc Start Settings
    type
      TRSMConfigMisc = record
        StartServerOnRSMBoot: Boolean;
        UpdateServerBeforeServerStart: Boolean;
        InstallOxideBeforeServerStart: Boolean;
        StartServerAfterShutdown: Boolean;
        ExecuteBeforeServerStart: Boolean;
        ExecuteBeforeServerStartFilePath: string;
      end;
      // API Settings
    type
      TRSMConfigAPIKeys = record
        SteamAPIKey: string;
        RustMapsAPIKey: string;
      end;
      // Login Tokens
    type
      TRSMConfigLoginTokens = record
        uModToken: string;
        CodeFlingToken: string;
      end;

      // Services - Map Server
    type
      TRSMConfigMapServer = record
        IP: string;
        Port: Integer;
        AutoStart: boolean;
      end;

      // Services - RSM API
    type
      TRSMConfigAPIServer = record
        Host: string;
        Port: Integer;
        TLSEnabled: Boolean;
        TLSCertFile: string;
        TLSKeyFile: string;
        TLSPassword: string;
        APIKey: string;
        AutoStart: Boolean;
      end;
    // Services
    type
      TRSMConfigServices = record
        MapServer: TRSMConfigMapServer;
        RSMAPI: TRSMConfigAPIServer;
      end;
    // RCON Events Handle
    type
      TRSMConfigRCONEvents = record
        HandleOnPlayerList: Boolean;
        HandleOnChat: Boolean;
        HandleOnServerInfo: Boolean;
        HandleOnServerManifest: Boolean;
      end;
  public
    { Public Variables }
    UI: TRSMConfigIU;
    TrayIcon: TRSMConfigTrayIcon;
    AutoRestart: TRSMConfigAutoRestart;
    Misc: TRSMConfigMisc;
    APIKeys: TRSMConfigAPIKeys;
    LoginTokens: TRSMConfigLoginTokens;
    Services: TRSMConfigServices;
    RCON: TRSMConfigRCONEvents;
  public
    { Public Methods }
    constructor Create;
    procedure SaveConfig;
    procedure LoadConfig;
  end;

var
  rsmConfig: TRSMConfig;

implementation

uses
  XSuperObject, System.SysUtils, System.IOUtils, uframeMessageBox, RSM.Core,
  uHelpers;

{ TRSMConfig }

constructor TRSMConfig.Create;
begin
  // UI
  Self.UI.navIndex := 0;
  Self.UI.windowPosX := 0;
  Self.UI.windowPosY := 0;
  Self.UI.windowHeight := 600;
  Self.UI.windowWidth := 1000;
  Self.UI.ShowServerInfoPanel := True;
  Self.UI.serverInstallerBranchIndex := 0;
 // Self.UI.quickServerControls := True;

  // Tray Icon
  Self.TrayIcon.Enabled := True;
  Self.TrayIcon.Title := 'RSMfmx v3';
  Self.TrayIcon.AppTitle := 'RSMfmx v3';

  // Auto Restart
  Self.AutoRestart.AutoRestart1.Enabled := False;
  Self.AutoRestart.AutoRestart1.Time := EncodeTime(5, 0, 0, 0);
  Self.AutoRestart.AutoRestart1.WarningTimeSecs := 300;
  Self.AutoRestart.AutoRestart2.Enabled := False;
  Self.AutoRestart.AutoRestart2.Time := EncodeTime(12, 0, 0, 0);
  Self.AutoRestart.AutoRestart2.WarningTimeSecs := 300;
  Self.AutoRestart.AutoRestart3.Enabled := False;
  Self.AutoRestart.AutoRestart3.Time := EncodeTime(17, 0, 0, 0);
  Self.AutoRestart.AutoRestart3.WarningTimeSecs := 300;

  // Misc
  Self.Misc.StartServerOnRSMBoot := False;
  Self.Misc.UpdateServerBeforeServerStart := False;
  Self.Misc.InstallOxideBeforeServerStart := False;
  Self.Misc.StartServerAfterShutdown := False;
  Self.Misc.ExecuteBeforeServerStart := False;
  Self.Misc.ExecuteBeforeServerStartFilePath := '';

  // API Keys
  Self.APIKeys.SteamAPIKey := '';
  Self.APIKeys.RustMapsAPIKey := '';

  // Login Tokens
  Self.LoginTokens.uModToken := '';
  Self.LoginTokens.CodeFlingToken := '';

  // Services - Map Server
  Self.Services.MapServer.IP := '0.0.0.0';
  Self.Services.MapServer.Port := 3000;
  Self.Services.MapServer.AutoStart := False;

  // Services - RSM API
  Self.Services.RSMAPI.Host := '0.0.0.0';
  Self.Services.RSMAPI.Port := 7744;
  Self.Services.RSMAPI.TLSEnabled := False;
  Self.Services.RSMAPI.TLSCertFile := '';
  Self.Services.RSMAPI.TLSKeyFile := '';
  Self.Services.RSMAPI.TLSPassword := '';
  Self.Services.RSMAPI.APIKey := GenerateAPIKey;
  Self.Services.RSMAPI.AutoStart := False;

  // RCON Handles
  Self.RCON.HandleOnPlayerList := True;
  Self.RCON.HandleOnChat := True;
  Self.RCON.HandleOnServerInfo := True;
  Self.RCON.HandleOnServerManifest := True;

  // Load Config
  Self.LoadConfig;
end;

procedure TRSMConfig.LoadConfig;
begin
   // Check if config file exists
  if not TFile.Exists(rsmCore.Paths.GetRSMConfigFilePath) then
  begin
    Self.SaveConfig;
    Exit;
  end;

  // Load Config
  Self.AssignFromJSON(TFile.ReadAllText(rsmCore.Paths.GetRSMConfigFilePath, TEncoding.UTF8));

  // Save Config again after loading to populate new properties in the file.
  Self.SaveConfig;

  // Check Params
  for var I := 1 to System.ParamCount do
  begin
    var param := System.ParamStr(I).ToLower;

    // Reset
    if param = '-reset' then
    begin
      // Skip if there's no options supplied
      if I + 1 > System.ParamCount then
        Continue;

      var paramOption := System.ParamStr(I + 1).ToLower;

      // Window Pos
      if paramOption = 'windowpos' then
      begin
        Self.UI.windowPosX := 0;
        Self.UI.windowPosY := 0;

        Self.SaveConfig;
      end;

      // Window Size
      if paramOption = 'windowsize' then
      begin
        Self.UI.windowHeight := 600;
        Self.UI.windowWidth := 1000;

        Self.SaveConfig;
      end;
    end;
  end;
end;

procedure TRSMConfig.SaveConfig;
begin
  if not TDirectory.Exists(rsmCore.Paths.GetRSMConfigDir) then
    ForceDirectories(rsmCore.Paths.GetRSMConfigDir);

  TFile.WriteAllText(rsmCore.Paths.GetRSMConfigFilePath, Self.AsJSON(True), TEncoding.UTF8);
end;

end.

