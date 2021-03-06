unit main;

{


Unicode:
variable 'Utf8string' is the same as 'string'
UTF8String          = type ansistring;
All 'string' should be rename to 'UTF8String' to show the intention that we should
use UTF8 in the program.
}


{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, CheckLst, DecodeTorrent, LCLType, ActnList, Menus, ComCtrls,
  Grids, controlergridtorrentdata;

type

  { TFormTrackerModify }

  TFormTrackerModify = class(TForm)
    CheckListBoxPublicPrivateTorrent: TCheckListBox;
    CheckListBoxTrackersList: TCheckListBox;
    GroupBoxTorrentContents: TGroupBox;
    GroupBoxPublicPrivateTorrent: TGroupBox;
    GroupBoxNewTracker: TGroupBox;
    GroupBoxPresentTracker: TGroupBox;
    MainMenu: TMainMenu;
    MemoNewTrackers: TMemo;
    MenuFile: TMenuItem;
    MenuFileTorrentFolder: TMenuItem;
    MenuFileOpenTrackerList: TMenuItem;
    MenuHelpReportingIssue: TMenuItem;
    MenuItemTorrentFilesTreeHideAll: TMenuItem;
    MenuItemTorrentFilesTreeShowTrackers: TMenuItem;
    MenuItemTorrentFilesTreeShowInfo: TMenuItem;
    MenuItemTorrentFilesTreeShowAll: TMenuItem;
    MenuItemTorrentFilesTreeShowFiles: TMenuItem;
    MenuTrackersAllTorrentArePrivate: TMenuItem;
    MenuTrackersAllTorrentArePublic: TMenuItem;
    MenuUpdateTorrent: TMenuItem;
    MenuHelp: TMenuItem;
    MenuHelpVisitWebsite: TMenuItem;
    MenuTrackersDeleteAllTrackers: TMenuItem;
    MenuTrackersKeepAllTrackers: TMenuItem;
    MenuTrackers: TMenuItem;
    MenuOpenTorrentFile: TMenuItem;
    OpenDialog: TOpenDialog;
    PageControl: TPageControl;
    PanelTopPublicTorrent: TPanel;
    PanelTop: TPanel;
    PopupMenuTorrentFilesContent: TPopupMenu;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    Splitter1: TSplitter;
    StringGridTorrentData: TStringGrid;
    TabSheetTorrentsContents: TTabSheet;
    TabSheetTorrentData: TTabSheet;
    TabSheetTrackersList: TTabSheet;
    TabSheetPublicPrivateTorrent: TTabSheet;
    TreeViewFileContents: TTreeView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    //Drag and drop '*.torrent' files/directory or 'tracker.txt'
    procedure FormDropFiles(Sender: TObject; const FileNames: array of UTF8String);



    //At start of the program the form will be show/hide
    procedure FormShow(Sender: TObject);
    procedure MenuFileOpenTrackerListClick(Sender: TObject);
    procedure MenuHelpReportingIssueClick(Sender: TObject);
    procedure MenuHelpVisitWebsiteClick(Sender: TObject);

    //Popup menu in treeview show all/hide all/ individual items selection.
    procedure MenuItemTorrentFilesTreeShowAllClick(Sender: TObject);
    procedure MenuItemTorrentFilesTreeHideAllClick(Sender: TObject);
    procedure MenuItemTorrentFilesTreeShowOrHideItemClick(Sender: TObject);

    //Select via menu torrent file or directory
    procedure MenuOpenTorrentFileClick(Sender: TObject);
    procedure MenuFileTorrentFolderClick(Sender: TObject);

    //Menu trackers
    procedure MenuTrackersAllTorrentArePublicPrivateClick(Sender: TObject);
    procedure MenuTrackersKeepOrDeleteAllTrackersClick(Sender: TObject);

    //Menu update torrent
    procedure MenuUpdateTorrentClick(Sender: TObject);

  private
    { private declarations }
    FTrackerFinalList, //Trackers that must be put inside the torrent.
    FTrackerAddedByUserList, //Trackers that we want too add.
    FTrackerBanByUserList, //trackers that must not be present inside torrent.
    FTrackerFromInsideTorrentFilesList, //Trackers that are already inside the torrent.
    FTorrentFileNameList,// All the torrent files that must be updated
    FLogStringList //Log string text output
    : TStringList;
    FDecodePresentTorrent: TDecodeTorrent; // is the present torrent file being process
    FConcoleMode, //user have start the program in console mode
    FFilePresentBanByUserList//There is a file 'remove_trackers.txt' detected
    : boolean;
    FLogFile, FTrackerFile: TextFile;
    FTotalFileInsideTorrent: integer;
    FTotalFileSizeInsideTorrent: int64;
    FProcessTimeStart, FProcessTimeTotal: TDateTime;
    FTreeNodeRoot: TTreeNode;
    FControlerGridTorrentData: TControlerGridTorrentData;

    function ByteSizeToBiggerSizeFormatStr(ByteSize: int64): string;

    procedure ShowHourGlassCursor(HourGlass: boolean);
    procedure ViewUpdateBegin(ClearView: boolean = True);
    procedure ViewUpdateOneTorrentFileDecoded;
    procedure ViewUpdateEnd;
    procedure ViewUpdateFormCaption;
    procedure ClearAllTorrentFilesNameAndTrackerInside;

    procedure MenuItemTorrentFilesTreeSyncWithPopupMenu;
    procedure SaveTrackerFinalListToFile;
    procedure ConsoleMode;
    procedure UpdateViewRemoveTracker;


    procedure ReloadAllTorrentAndRefreshView;
    function AddTorrentFileList(TorrentFileNameStringList: TStringList): boolean;
    function ReadAddTrackerFileFromUser(const FileName: UTF8String): boolean;
    function LoadTorrentViaDir(const Dir: UTF8String): boolean;
    function DecodeTorrentFile(const FileName: UTF8String): boolean;
    procedure UpdateTrackerInsideFileList;
    procedure UpdateTorrentTrackerList;
    procedure CombineThreeTrackerListToOne;
    procedure ShowTrackerInsideFileList;

    procedure CheckedOnOffAllTrackers(Value: boolean);
    function CopyUserInputNewTrackersToList: boolean;
    procedure LoadTrackersTextFileAddTrackers;
    procedure LoadTrackersTextFileRemoveTrackers;
    function ValidTrackerURL(const TrackerURL: UTF8String): boolean;
  public
    { public declarations }
  end;

var
  FormTrackerModify: TFormTrackerModify;

implementation

uses LCLIntf, lazutf8;

const
  RECOMENDED_TRACKERS: array[0..2] of UTF8String =
    (
    'udp://tracker.openbittorrent.com:80/announce',
    'udp://tracker.publicbt.com:80/announce',
    'udp://tracker.istole.it:80/announce'
    //    'udp://open.demonii.com:1337/announce'
    );
  //program name and version
  FORM_CAPTION = 'Bittorrent tracker editor (1.31)';
  TORRENT_FILES_CONTENTS_FORM_CAPTION =
    'Show all the files inside the torrents. (Use right mouse for popup menu.)';

  //'add trackers' text file must be place in the same directory as the program.
  ADD_TRACKERS_FILE_NAME = 'add_trackers.txt';

  //'remove trackers' text file must be place in the same directory as the program.
  REMOVE_TRACKERS_FILE_NAME = 'remove_trackers.txt';

  //'export trackers' text file wil be created in the same directory as the program.
  EXPORT_TRACKERS_FILE_NAME = 'export_trackers.txt';

  //'log' text file will be saved in the same directory as the program
  // only in the console mode.
  LOG_FILE_NAME = 'console_log.txt';

{$R *.lfm}

{ TFormTrackerModify }

procedure TFormTrackerModify.FormCreate(Sender: TObject);
begin
  Caption := FORM_CAPTION;

  //Create controler for StringGridTorrentData
  FControlerGridTorrentData := TControlerGridTorrentData.Create(StringGridTorrentData);

  //Log file output string List.
  FLogStringList := TStringList.Create;

  //Create filename list for all the torrent files.
  FTorrentFileNameList := TStringList.Create;
  FTorrentFileNameList.Duplicates := dupIgnore;
  //Must NOT be sorted. Must in sync with CheckListBoxPublicPrivateTorrent.
  FTorrentFileNameList.Sorted := False;

  //Create ban tracker list where the user can manualy add items to it.
  FTrackerBanByUserList := TStringList.Create;
  FTrackerBanByUserList.Duplicates := dupIgnore;
  FTrackerBanByUserList.Sorted := False;

  //Create tracker list where the user can manualy add items to it
  FTrackerAddedByUserList := TStringList.Create;
  FTrackerAddedByUserList.Duplicates := dupIgnore;
  //must be sorted. is visible to user.
  //drag and drop tracker list will accept duplicates in memo text, if false. Need to check out why.
  FTrackerAddedByUserList.Sorted := True;

  //Create tracker list where all the trackers from all the torrent files are collected
  FTrackerFromInsideTorrentFilesList := TStringList.Create;
  FTrackerFromInsideTorrentFilesList.Duplicates := dupIgnore;
  //must be sorted. is visible to user. In tracker list tab page.
  FTrackerFromInsideTorrentFilesList.Sorted := True;

  //Create tracker list that combine FTrackerFromInsideTorrentFilesList + FTrackerAddedByUserList together.
  FTrackerFinalList := TStringList.Create;
  FTrackerFinalList.Duplicates := dupIgnore;

  //must be sorted. because we want to insert it in torrent files.
  FTrackerFinalList.Sorted := True;


  //Decoding class for torrent.
  FDecodePresentTorrent := TDecodeTorrent.Create;

  //start the program at mimimum visual size. (this is optional)
  Width := Constraints.MinWidth;
  Height := Constraints.MinHeight;

  //Show the default trackers
  LoadTrackersTextFileAddTrackers;

  //Load the unwanted trackers list.
  LoadTrackersTextFileRemoveTrackers;

  //Check is program is started as console
  ConsoleMode;

  GroupBoxTorrentContents.Caption := TORRENT_FILES_CONTENTS_FORM_CAPTION;
end;

procedure TFormTrackerModify.FormDestroy(Sender: TObject);
begin
  //The program is being closed. Free all the memory.
  FLogStringList.Free;
  FTrackerFinalList.Free;
  FDecodePresentTorrent.Free;
  FTrackerAddedByUserList.Free;
  FTrackerBanByUserList.Free;
  FTrackerFromInsideTorrentFilesList.Free;
  FTorrentFileNameList.Free;
  FControlerGridTorrentData.Free;
end;

procedure TFormTrackerModify.MenuFileTorrentFolderClick(Sender: TObject);
begin
  ClearAllTorrentFilesNameAndTrackerInside;
  ViewUpdateBegin;
  //User what to select one torrent file. Show the user dialog file selection.
  SelectDirectoryDialog1.InitialDir := ExtractFilePath(Application.ExeName);
  if SelectDirectoryDialog1.Execute then
  begin
    ShowHourGlassCursor(True);
    LoadTorrentViaDir(SelectDirectoryDialog1.FileName);
    ShowHourGlassCursor(False);
  end;
  ViewUpdateEnd;
end;

procedure TFormTrackerModify.MenuHelpVisitWebsiteClick(Sender: TObject);
begin
  //There is no help file in this progam. Show user main web site.
  OpenURL('http://code.google.com/p/bittorrent-tracker-editor');
end;

procedure TFormTrackerModify.MenuItemTorrentFilesTreeHideAllClick(Sender: TObject);
var
  i, CountTorrents: integer;
begin
  //Show only torrent file names

  //user what to hide all the items.
  //All the popup menu item must first be unchecked.
  MenuItemTorrentFilesTreeShowInfo.Checked := False;
  MenuItemTorrentFilesTreeShowFiles.Checked := False;
  MenuItemTorrentFilesTreeShowTrackers.Checked := False;
  //Update the TorrentFilesTree
  //  MenuItemTorrentFilesTreeSyncWithPopupMenu;

  if not assigned(FTreeNodeRoot) then
    exit;

  //how many torrent files are there.
  CountTorrents := FTreeNodeRoot.Count;
  if CountTorrents = 0 then
    exit;

  //Show the torrent files names only.
  for i := 0 to CountTorrents - 1 do
  begin
    FTreeNodeRoot.Items[i].Collapse(True);
  end;

end;

procedure TFormTrackerModify.MenuItemTorrentFilesTreeShowAllClick(Sender: TObject);
begin
  //show everything
  if assigned(FTreeNodeRoot) then
    FTreeNodeRoot.Expand(True);

  //user what to see all the items.
  //All the popup menu item must first be checked.
  MenuItemTorrentFilesTreeShowInfo.Checked := True;
  MenuItemTorrentFilesTreeShowFiles.Checked := True;
  MenuItemTorrentFilesTreeShowTrackers.Checked := True;
  //Update the TorrentFilesTree
  //  MenuItemTorrentFilesTreeSyncWithPopupMenu;
end;

procedure TFormTrackerModify.MenuItemTorrentFilesTreeShowOrHideItemClick(
  Sender: TObject);
var
  i, CountTorrents, itemsNr: integer;
  ShowNode: boolean;
begin
  //Show or hide all the items below the torrent files.

  //Get the top node.
  if not assigned(FTreeNodeRoot) then
    exit;

  //how many torrent files are there.
  CountTorrents := FTreeNodeRoot.Count;
  if CountTorrents = 0 then
    exit;

  //The tag number define if it is for files, trackers or info items
  itemsNr := TMenuItem(Sender).tag;
  //Must show or hide the items
  ShowNode := TMenuItem(Sender).Checked;
  //process all the torrent files one by one.
  for i := 0 to CountTorrents - 1 do
  begin
    if ShowNode then
    begin
      FTreeNodeRoot.Items[i].Expand(False); //Show the torrent name + child
      FTreeNodeRoot.Items[i].Items[itemsNr].Expand(False); //expand child
    end
    else
    begin
      FTreeNodeRoot.Items[i].Items[itemsNr].Collapse(False);
    end;
  end;
end;


procedure TFormTrackerModify.MenuUpdateTorrentClick(Sender: TObject);
var
  Reply, BoxStyle, i, CountTrackers: integer;
  PopUpMenuStr: string;

begin
  //Update the all the torrent files.

  //The StringGridTorrentData where the comment are place by user
  //    must be in sync again with FTorrentFileNameList.
  //Undo all posible sort column used by the user. Sort it back to 'begin state'
  FControlerGridTorrentData.ReorderGrid;

  try

    if not FConcoleMode then
    begin
      //Warn user before updating the torrent
      BoxStyle := MB_ICONWARNING + MB_OKCANCEL;
      Reply := Application.MessageBox('Warning: There is no undo.',
        'Torrent files will be change!', BoxStyle);
      if Reply <> idOk then
      begin
        ShowHourGlassCursor(True);
        exit;
      end;
    end;


    //Must have some torrent selected
    if (FTorrentFileNameList.Count = 0) then
    begin
      if FConcoleMode then
      begin
        FLogStringList.Add('ERROR: No torrent file selected');
      end
      else
      begin
        Application.MessageBox('No torrent file selected',
          '', MB_ICONERROR);
      end;
      ShowHourGlassCursor(True);
      exit;
    end;

    //User must wait for a while.
    ShowHourGlassCursor(True);

    //Copy the tracker list inside torrent -> FTrackerFromInsideTorrentFilesList
    UpdateTrackerInsideFileList;

    //Check for error in user tracker list -> FTrackerAddedByUserList
    if not CopyUserInputNewTrackersToList then
      Exit;

    //There are 3 list that must be combine
    //FTrackerFinalList := FTrackerAddedByUserList + FTrackerFromInsideTorrentFilesList
    // - FTrackerBanByUserList
    CombineThreeTrackerListToOne;

    //In console mode we can ignore this warning
    if not FConcoleMode and (FTrackerFinalList.Count = 0) then
    begin //Torrent without a tracker is posible. But is this what the user realy want? a DHT torrent.
      BoxStyle := MB_ICONWARNING + MB_OKCANCEL;
      Reply := Application.MessageBox(
        'Warning: Create torrent file without any URL of the tracker?',
        'There are no Trackers selected!', BoxStyle);
      if Reply <> idOk then
      begin
        ShowHourGlassCursor(False);
        exit;
      end;
      //Reset process timer
      ShowHourGlassCursor(True);
    end;

    //How many trackers must be put inside each torrent file
    CountTrackers := FTrackerFinalList.Count;

    //process all the files one by one.
    //FTorrentFileNameList is not sorted it is still in sync with CheckListBoxPublicPrivateTorrent
    for i := 0 to FTorrentFileNameList.Count - 1 do
    begin //read the torrent file in FDecodePresentTorrent and modify it.

      //read one torrent file. If error then skip it. (continue)
      if not FDecodePresentTorrent.DecodeTorrent(FTorrentFileNameList[i]) then
        Continue;

      case CountTrackers of
        0://if no tracker selected then delete 'announce' and 'announce-list'
        begin
          FDecodePresentTorrent.RemoveAnnounce;
          FDecodePresentTorrent.RemoveAnnounceList;
        end;
        1://if one tracker selected then delete 'announce-list'
        begin
          //Announce use the only tracker present in the FTrackerFinalList. index 0
          FDecodePresentTorrent.ChangeAnnounce(FTrackerFinalList[0]);
          FDecodePresentTorrent.RemoveAnnounceList;
        end;
        else//More than 1 trackers selected. Create 'announce-list'
        begin
          //Announce use the first tracker from the list. index 0
          FDecodePresentTorrent.ChangeAnnounce(FTrackerFinalList[0]);
          FDecodePresentTorrent.ChangeAnnounceList(FTrackerFinalList);
        end;
      end;



      //update the torrent public/private flag
      if CheckListBoxPublicPrivateTorrent.Checked[i] then
      begin
        //if private torrent then make it public torrent by removing the private flag.
        if FDecodePresentTorrent.PrivateTorrent then
          FDecodePresentTorrent.RemovePrivateTorrentFlag;
      end
      else
      begin
        FDecodePresentTorrent.AddPrivateTorrentFlag;
      end;

      //update the comment item
      FDecodePresentTorrent.Comment := FControlerGridTorrentData.ReadComment(i + 1);

      //save the torrent file.
      FDecodePresentTorrent.SaveTorrent(FTorrentFileNameList[i]);
    end;

    //Create tracker.txt file
    SaveTrackerFinalListToFile;

    //Show/reload the just updated torrent files.
    ReloadAllTorrentAndRefreshView;

    //make sure cursor is default again
  finally
    ShowHourGlassCursor(False);
    ViewUpdateFormCaption;
  end;


  if FConcoleMode then
  begin
    //When succesfull the log file shows, 3 lines,
    //     OK + Count torrent files  + Count Trackers
    FLogStringList.Add('OK');
    FLogStringList.Add(IntToStr(FTorrentFileNameList.Count));
    FLogStringList.Add(IntToStr(CountTrackers));
  end
  else
  begin
    //Via popup show user how many trackers are inside the torrent after update.
    PopUpMenuStr := 'All torrent file(s) have now ' + IntToStr(CountTrackers) +
      ' trackers.';
    Application.MessageBox(
      PChar(@PopUpMenuStr[1]),
      '', MB_ICONINFORMATION + MB_OK);
  end;

end;

function TFormTrackerModify.ByteSizeToBiggerSizeFormatStr(ByteSize: int64): string;
begin
  if ByteSize >= (1024 * 1024 * 1024) then
    Result := Format('%0.2f GiB', [ByteSize / (1024 * 1024 * 1024)])
  else
  if ByteSize >= (1024 * 1024) then
    Result := Format('%0.2f MiB', [ByteSize / (1024 * 1024)])
  else
  if ByteSize >= (1024) then
    Result := Format('%0.2f KiB', [ByteSize / 1024]);
  Result := Result + Format('  (%d Bytes)', [ByteSize]);

end;



procedure TFormTrackerModify.MenuItemTorrentFilesTreeSyncWithPopupMenu;
begin
  MenuItemTorrentFilesTreeShowOrHideItemClick(MenuItemTorrentFilesTreeShowTrackers);
  MenuItemTorrentFilesTreeShowOrHideItemClick(MenuItemTorrentFilesTreeShowInfo);
  MenuItemTorrentFilesTreeShowOrHideItemClick(MenuItemTorrentFilesTreeShowFiles);
end;


procedure TFormTrackerModify.SaveTrackerFinalListToFile;
var
  TrackerStr: UTF8String;
begin
  //Create the tracker text file. The old one will be overwritten
  AssignFile(FTrackerFile, ExtractFilePath(Application.ExeName) +
    EXPORT_TRACKERS_FILE_NAME);
  ReWrite(FTrackerFile);
  for TrackerStr in FTrackerFinalList do
  begin
    WriteLn(FTrackerFile, TrackerStr);

    //Must create an empty line betwean trackers.
    //Every tracker must be a seperate tracker group.
    //This is what the user probably want.
    //The file content can then be copy/pasted to uTorrent etc.
    WriteLn(FTrackerFile, '');
  end;
  CloseFile(FTrackerFile);
end;

procedure TFormTrackerModify.ConsoleMode;
var
  FileNameOrDirStr: UTF8String;
  StringList: TStringList;
begin
  //if program is started with one parameter then in must be stated console mode.
  //This parameter is path to file or dir.

  //update the torrent via console mode if there is a parameter detected.
  if ParamCount > 0 then
  begin
    FConcoleMode := True;

    //Create the log file. The old one will be overwritten
    AssignFile(FLogFile, ExtractFilePath(Application.ExeName) + LOG_FILE_NAME);
    ReWrite(FLogFile);

    //Get the first parameter.
    FileNameOrDirStr := UTF8Trim(ParamStr(1));

    //If FLogStringList empty then there is no error.
    if FLogStringList.Text = '' then
    begin
      //There is no error. Proceed with reading the torrent files

      if ExtractFileExt(FileNameOrDirStr) = '' then
      begin //There is no file extention. It must be a folder.
        if LoadTorrentViaDir(FileNameOrDirStr) then
        begin
          //Show all the tracker inside the torrent files.
          ShowTrackerInsideFileList;
          //Mark all trackers as selected
          CheckedOnOffAllTrackers(True);
          //Some tracker must be removed. Console and windows mode.
          UpdateViewRemoveTracker;
          //update torrent
          MenuUpdateTorrentClick(self);
        end;
      end
      else //a torrent file is selected?
      begin
        if ExtractFileExt(FileNameOrDirStr) = '.torrent' then
        begin
          StringList := TStringList.Create;
          try
            //Convert Filenames to stringlist format.
            StringList.Add(FileNameOrDirStr);
            AddTorrentFileList(StringList);

            //Show all the tracker inside the torrent files.
            ShowTrackerInsideFileList;
            //Mark all trackers as selected
            CheckedOnOffAllTrackers(True);
            //Some tracker must be removed. Console and windows mode.
            UpdateViewRemoveTracker;
            //update torrent
            MenuUpdateTorrentClick(self);
          finally
            StringList.Free;
          end;
        end
        else
        begin //Error. this is not a torrent file
          FLogStringList.Add('ERROR: No torrent file selected.');
        end;
      end;
    end;

    //Write to log file. And close the file.
    WriteLn(FLogFile, FLogStringList.Text);
    CloseFile(FLogFile);

    //Shutdown the console program
    Application.terminate;
  end
  else
  begin //the program
    FConcoleMode := False;
  end;

end;


procedure TFormTrackerModify.UpdateViewRemoveTracker;
var
  TrackerStr: UTF8String;
  i: integer;
begin
  {
    Called when user load the torrent files.
    Trackers that are forbidden must be uncheck.
    Trackers add by user in the memo text filed must also be removed.
    This routine is also use in the console mode to remove trackers
  }

  //If file remove_trackers.txt is present but empty then remove all tracker inside torrent.
  if FFilePresentBanByUserList and (UTF8Trim(FTrackerBanByUserList.Text) = '') then
  begin
    CheckedOnOffAllTrackers(False);
  end;


  //reload the memo. This will sanitize the MemoNewTrackers.Lines.
  if not CopyUserInputNewTrackersToList then
    exit;

  //remove all the trackers that are ban.
  MemoNewTrackers.Lines.BeginUpdate;
  for TrackerStr in FTrackerBanByUserList do
  begin

    //uncheck tracker that are listed in FTrackerBanByUserList
    i := CheckListBoxTrackersList.Items.IndexOf(UTF8Trim(TrackerStr));
    if i >= 0 then //Found it.
    begin
      CheckListBoxTrackersList.Checked[i] := False;
    end;

    //remove tracker from user memo text that are listed in FTrackerBanByUserList
    //Find TrackerStr in MemoNewTrackers.Lines and remove it.
    i := MemoNewTrackers.Lines.IndexOf(UTF8Trim(TrackerStr));
    if i >= 0 then //Found it.
    begin
      MemoNewTrackers.Lines.Delete(i);
    end;
  end;
  MemoNewTrackers.Lines.EndUpdate;

  //reload the memo again.
  CopyUserInputNewTrackersToList;

end;




function TFormTrackerModify.DecodeTorrentFile(const FileName: UTF8String): boolean;
begin
  //Called when user add torrent files
  //False if something is wrong with decoding torrent.
  Result := FDecodePresentTorrent.DecodeTorrent(FileName);
  ViewUpdateOneTorrentFileDecoded;
end;

procedure TFormTrackerModify.UpdateTorrentTrackerList;
var
  TrackerStr: UTF8String;
begin
  //Copy the trackers found in one torrent file to FTrackerFromInsideTorrentFilesList
  for TrackerStr in FDecodePresentTorrent.TrackerList do
    FTrackerFromInsideTorrentFilesList.Add(TrackerStr);
end;

procedure TFormTrackerModify.ShowTrackerInsideFileList;
var
  TrackerStr: UTF8String;
begin
  //Called after torrent is being loaded.

  CheckListBoxTrackersList.Items.BeginUpdate;
  //remove the previeus list
  CheckListBoxTrackersList.Clear;
  //Add new items to the list.
  for TrackerStr in FTrackerFromInsideTorrentFilesList do
  begin
    CheckListBoxTrackersList.Items.Add(TrackerStr);
  end;
  CheckListBoxTrackersList.Items.EndUpdate;
end;


procedure TFormTrackerModify.CheckedOnOffAllTrackers(Value: boolean);
var
  i: integer;
begin
  //Set all the trackers checkbox ON or OFF
  with CheckListBoxTrackersList do
    if Count > 0 then
      for i := 0 to Count - 1 do
        Checked[i] := Value;
end;

function TFormTrackerModify.ValidTrackerURL(const TrackerURL: UTF8String): boolean;
begin
  //TrackerURL should be cleanup with UTF8trim()
  Result := (Pos('http://', TrackerURL) = 1) or (Pos('udp://', TrackerURL) = 1);
end;

function TFormTrackerModify.CopyUserInputNewTrackersToList: boolean;
var
  TrackerStr: UTF8String;
begin
  {
   Called after 'update torrent' is selected.
   All the user entery from Memo text field will be add to FTrackerAddedByUserList.
  }
  FTrackerAddedByUserList.Clear;

  for TrackerStr in MemoNewTrackers.Lines do
  begin
    TrackerStr := UTF8trim(TrackerStr);

    //Skip empty line
    if TrackerStr = '' then
      continue;

    //All the tracker must begin with 'http://' or 'udp://'
    if ValidTrackerURL(TrackerStr) then
    begin
      FTrackerAddedByUserList.Add(TrackerStr);
    end
    else
    begin
      //There is error. Show the error and do not continue.
      if FConcoleMode then
      begin
        FLogStringList.Add('ERROR: Tracker URL must begin with http:// or udp://');
      end
      else
      begin
        //Show error
        Application.MessageBox(PChar(@TrackerStr[1]),
          'Error: Tracker URL must begin with http:// or udp://', MB_ICONERROR);
      end;
      //dot not continue with error.
      Result := False;
      exit;
    end;

  end;

  Result := True; //no error

  //Show the torrent list we have just created.
  MemoNewTrackers.Text := FTrackerAddedByUserList.Text;

end;




procedure TFormTrackerModify.CombineThreeTrackerListToOne;
var
  TrackerStr: UTF8String;
  i: integer;
begin
  // FTrackerFinalList = (FTrackerAddedByUserList + FTrackerFromInsideTorrentFilesList)
  //   - FTrackerBanByUserList
  FTrackerFinalList.Clear;

  for TrackerStr in FTrackerAddedByUserList do
    FTrackerFinalList.Add(TrackerStr);

  for TrackerStr in FTrackerFromInsideTorrentFilesList do
    FTrackerFinalList.Add(TrackerStr);

  //Remove the trackers must be the last step.
  for TrackerStr in FTrackerBanByUserList do
  begin
    //Find the tracker and remove it from the list.
    //FTrackerBanByUserList is not UTF8Trim() before. Must use with UTF8Trim()
    i := FTrackerFinalList.IndexOf(UTF8Trim(TrackerStr));
    if i >= 0 then
      FTrackerFinalList.Delete(i);
  end;
end;


procedure TFormTrackerModify.UpdateTrackerInsideFileList;
var
  i: integer;
begin
  //Copy items from CheckListBoxTrackersList to FTrackerFromInsideTorrentFilesList
  FTrackerFromInsideTorrentFilesList.Clear;
  with CheckListBoxTrackersList do
    if Count > 0 then
      for i := 0 to Count - 1 do
        if Checked[i] then
          FTrackerFromInsideTorrentFilesList.add(Items[i]);
end;

procedure TFormTrackerModify.LoadTrackersTextFileAddTrackers;
var
  i: integer;
begin
  //Called at the start of the program. Load a trackers list from file

  //if no file is found the use the default tracker list.
  if not ReadAddTrackerFileFromUser(ExtractFilePath(Application.ExeName) +
    ADD_TRACKERS_FILE_NAME) then
  begin
    MemoNewTrackers.Lines.BeginUpdate;
    for i := low(RECOMENDED_TRACKERS) to high(RECOMENDED_TRACKERS) do
    begin
      MemoNewTrackers.Lines.Add(RECOMENDED_TRACKERS[i]);
    end;
    MemoNewTrackers.Lines.EndUpdate;
  end;

  //Check for error in tracker list
  if not CopyUserInputNewTrackersToList then
  begin
    MemoNewTrackers.Lines.Clear;
  end;
end;

procedure TFormTrackerModify.LoadTrackersTextFileRemoveTrackers;
var
  filename: UTF8String;
begin
  filename := ExtractFilePath(Application.ExeName) + REMOVE_TRACKERS_FILE_NAME;
  try
    FFilePresentBanByUserList := FileExistsUTF8(fileName);
    if FFilePresentBanByUserList then
    begin
      FTrackerBanByUserList.LoadFromFile(fileName);
    end;
  except
    FFilePresentBanByUserList := False;
  end;
end;


procedure TFormTrackerModify.MenuOpenTorrentFileClick(Sender: TObject);
var
  StringList: TStringList;
begin
  ClearAllTorrentFilesNameAndTrackerInside;
  ViewUpdateBegin;

  //User what to select a torrent file. Show the user dialog.
  OpenDialog.Title := 'Select a torrent file';
  OpenDialog.Filter := 'torrent|*.torrent';
  if OpenDialog.Execute then
  begin
    ShowHourGlassCursor(True);
    StringList := TStringList.Create;
    try
      StringList.Add(UTF8Trim(OpenDialog.FileName));
      AddTorrentFileList(StringList);
    finally
      StringList.Free;
      ShowHourGlassCursor(False);
    end;
  end;
  ViewUpdateEnd;

end;

procedure TFormTrackerModify.MenuTrackersAllTorrentArePublicPrivateClick(
  Sender: TObject);
var
  i: integer;
begin
  //Warn user about torrent Hash.
  if Application.MessageBox(
    'Warning: Changing the public/private torrent flag will change the info hash.',
    'Are you sure!', MB_ICONWARNING + MB_OKCANCEL) <> idOk then
    exit;

  //Set all the trackers publick/private checkbox ON or OFF
  with CheckListBoxPublicPrivateTorrent do
    if Count > 0 then
      for i := 0 to Count - 1 do
        Checked[i] := TMenuItem(Sender).Tag = 1;
end;


procedure TFormTrackerModify.MenuFileOpenTrackerListClick(Sender: TObject);
begin
  //Clear the present list
  MemoNewTrackers.Lines.Clear;
  //User what to select a tracker file. Show the user dialog.

  OpenDialog.Title := 'Select a tracker list file';
  OpenDialog.Filter := 'tracker text file|*.txt';
  if OpenDialog.Execute then
  begin
    ReadAddTrackerFileFromUser(OpenDialog.FileName);
  end;
end;

procedure TFormTrackerModify.MenuHelpReportingIssueClick(Sender: TObject);
begin
  OpenURL('http://code.google.com/p/bittorrent-tracker-editor/issues');
end;


function TFormTrackerModify.ReadAddTrackerFileFromUser(
  const FileName: UTF8String): boolean;
var
  TrackerFileList: TStringList;
begin
  //read the file and show it to the user.
  TrackerFileList := TStringList.Create;
  try
    TrackerFileList.LoadFromFile(FileName);
    MemoNewTrackers.Text := UTF8Trim(TrackerFileList.Text);
    Result := True;
  except
    Result := False;
    //suppres all error in reading the file.
  end;
  TrackerFileList.Free;

  // It can be simpler, but does this suport UTF8?
  //  MemoNewTrackers.Lines.LoadFromFile(FileName);
end;

procedure TFormTrackerModify.MenuTrackersKeepOrDeleteAllTrackersClick(Sender: TObject);
begin
  CheckedOnOffAllTrackers(TMenuItem(Sender).Tag = 1);
end;


function TFormTrackerModify.LoadTorrentViaDir(const Dir: UTF8String): boolean;
var
  Info: TSearchRec;
  TorrentFilesNameStringList: TStringList;
begin
  //place all the torrent file name in TorrentFilesNameStringList
  TorrentFilesNameStringList := TStringList.Create;
  try
    if FindFirstUTF8(dir + PathDelim + '*.torrent', faAnyFile, Info) = 0 then
    begin
      //Read all the torrent files inside this dir.
      repeat
        TorrentFilesNameStringList.Add(UTF8Trim(dir + PathDelim + Info.Name));
      until FindNextUTF8(info) <> 0;
    end;
    FindCloseUTF8(Info);

    //add the torrent file name to AddTorrentFileList()
    Result := AddTorrentFileList(TorrentFilesNameStringList);

  finally
    //Free all the list we temporary created.
    TorrentFilesNameStringList.Free;
  end;
end;


procedure TFormTrackerModify.FormDropFiles(Sender: TObject;
  const FileNames: array of UTF8String);
var
  Count: integer;
  TorrentFileNameStringList, //for the torrent files
  TrackerFileNameStringList //for the trackers files
  : TStringList;
  TorrentFileSelectionDetected, ViewUpdateBeginActiveOneTimeOnly
  //ViewUpdateBegin must be called one time. Keep track of it.
  : boolean;
  FileNameOrDirStr: UTF8String;
begin
  //Drag and drop a folder or files?

  //Change cursor
  ShowHourGlassCursor(True);

  // Always clear the previeus torrent files selection.
  // keep track if torrent file is detected in drag/drop
  // need this to call ClearAllTorrentFilesNameAndTrackerInside()
  //    this will clear the previeuse torrent loaded.
  TorrentFileSelectionDetected := False;




  ViewUpdateBeginActiveOneTimeOnly := False;

  //Remember every file names from drag and drop.
  //It can be mix *.torrent + trackers.txt files
  TorrentFileNameStringList := TStringList.Create;
  TrackerFileNameStringList := TStringList.Create;

  try

    //process all the files and/or directory that is drop by user.
    for Count := low(FileNames) to High(FileNames) do
    begin
      FileNameOrDirStr := UTF8Trim(FileNames[Count]);


      //if '.torrent' then add to TorrentFileNameStringList
      if ExtractFileExt(FileNameOrDirStr) = '.torrent' then
      begin

        //if first time a torrent detected then ClearAllTorrentFilesNameAndTrackerInside
        if not TorrentFileSelectionDetected then
        begin
          TorrentFileSelectionDetected := True;
          ClearAllTorrentFilesNameAndTrackerInside;
        end;

        TorrentFileNameStringList.Add(FileNameOrDirStr);
      end;

      //if '.txt' then it must be a tracker list.
      if ExtractFileExt(FileNameOrDirStr) = '.txt' then
      begin
        try
          TrackerFileNameStringList.LoadFromFile(FileNameOrDirStr);
          MemoNewTrackers.Append(UTF8Trim(TrackerFileNameStringList.Text));
        except
          //supress any error in loading the file
        end;
      end;

      //if there is no file extention. It must be a torrent folder.
      if ExtractFileExt(FileNameOrDirStr) = '' then
      begin

        //if first time a torrent detected then ClearAllTorrentFilesNameAndTrackerInside
        if not TorrentFileSelectionDetected then
        begin
          TorrentFileSelectionDetected := True;
          ClearAllTorrentFilesNameAndTrackerInside;
        end;

        if not ViewUpdateBeginActiveOneTimeOnly then
        begin
          ViewUpdateBeginActiveOneTimeOnly := True;
          ViewUpdateBegin;
        end;

        LoadTorrentViaDir(FileNameOrDirStr);

      end;

    end;//for


    //Check for error in tracker list
    if not CopyUserInputNewTrackersToList then
    begin //When error clear tracker list.
      MemoNewTrackers.Lines.Clear;
    end;

    //the torrent files we have collected here must be add to AddTorrentFileList()
    if TorrentFileNameStringList.Count > 0 then
    begin

      if not ViewUpdateBeginActiveOneTimeOnly then
      begin
        ViewUpdateBeginActiveOneTimeOnly := True;
        ViewUpdateBegin;
      end;

      AddTorrentFileList(TorrentFileNameStringList);

    end;

  finally
    //Free all the list we temporary created.
    TorrentFileNameStringList.Free;
    TrackerFileNameStringList.Free;
    ShowHourGlassCursor(False);
  end;




  //if ViewUpdateBegin is called then ViewUpdateEnd must also be called.
  if ViewUpdateBeginActiveOneTimeOnly then
    ViewUpdateEnd;

end;

procedure TFormTrackerModify.FormShow(Sender: TObject);
begin
  //In console mode do not show the program.
  if FConcoleMode then
    Visible := False;
end;


function TFormTrackerModify.AddTorrentFileList(TorrentFileNameStringList:
  TStringList): boolean;
  //This called from 'add folder' or 'drag and drop'
var
  Count: integer;
  TorrentFileNameStr: UTF8String;
begin
{ Every torrent file must be decoded for the tracker list inside.
  This torrent tracker list is add to FTrackerFromInsideTorrentFilesList.
  All the torrent files name are added to FTorrentFileNameList.

  Called when user do drag and drop, File open torrent file/dir
}
  if TorrentFileNameStringList.Count > 0 then
  begin
    for Count := 0 to TorrentFileNameStringList.Count - 1 do
    begin
      //process one torrent file name for each loop.
      TorrentFileNameStr := TorrentFileNameStringList[Count];

      if DecodeTorrentFile(TorrentFileNameStr) then
      begin
        //This torrent have announce list(trackers) decoded.
        //Now add all this torrent trackers to the 'general' list of trackers.
        UpdateTorrentTrackerList;
        //Add this torrent file to the 'general' list of torrent file names
        FTorrentFileNameList.Add(TorrentFileNameStr);
      end
      else
      begin
        //Someting is wrong. Can not decode torrent tracker item.
        //Cancel everything.
        FTorrentFileNameList.Clear;
        FTrackerFromInsideTorrentFilesList.Clear;
        if FConcoleMode then
        begin
          FLogStringList.Add('Error: Can not read torrent. ' + TorrentFileNameStr);
        end
        else
        begin
          Application.MessageBox(PChar(@TorrentFileNameStr[1]),
            'Error: Can not read torrent.', MB_ICONERROR);
        end;
        Result := False;
        exit;
      end;
    end;
  end;
  Result := True;
end;


procedure TFormTrackerModify.ReloadAllTorrentAndRefreshView;
var
  TorrentFileStr: UTF8String;
begin
{
  This is called after updating the torrent.
  We want to re-read the all torrent files.
  And show that everything is updated and OK
}

  ViewUpdateBegin;
  //Copy all the trackers in inside the torrent files to FTrackerFromInsideTorrentFilesList
  FTrackerFromInsideTorrentFilesList.Clear;
  for TorrentFileStr in FTorrentFileNameList do
  begin
    if DecodeTorrentFile(TorrentFileStr) then
    begin
      UpdateTorrentTrackerList;
    end;
  end;

  //refresh the view
  ViewUpdateEnd;

end;

procedure TFormTrackerModify.ClearAllTorrentFilesNameAndTrackerInside;
begin
  FTorrentFileNameList.Clear;
  FTrackerFromInsideTorrentFilesList.Clear;
  //  Caption := FORM_CAPTION;
  //  ShowTorrentFilesAfterBeingLoaded;
end;


procedure TFormTrackerModify.ViewUpdateBegin(ClearView: boolean);
begin
  //Called before loading torrent file.
  FTotalFileInsideTorrent := 0;
  FTotalFileSizeInsideTorrent := 0;

  //Do not show being updating till finish updating data.
  StringGridTorrentData.BeginUpdate;
  TreeViewFileContents.BeginUpdate;
  CheckListBoxPublicPrivateTorrent.Items.BeginUpdate;

  if ClearView then
  begin
    //Clear all the user data 'View' elements. This will be filled with new data.
    TreeViewFileContents.Items.Clear;
    CheckListBoxPublicPrivateTorrent.Clear; //Use in update torrent!
    StringGridTorrentData.Clear;
    FControlerGridTorrentData.ClearAllImageIndex;
    //RowCount is 0 after Clear. But must be 1 to make it work.
    StringGridTorrentData.RowCount := 1;
  end;

  //root is 'Torrent Files'
  FTreeNodeRoot := TreeViewFileContents.Items.Add(nil, 'Torrent Files');

end;

procedure TFormTrackerModify.ViewUpdateOneTorrentFileDecoded;
var
  RowIndex, CountFiles: integer;
  TorrentFileNameStr, TrackerStr, DateTimeStr, PrivateStr: UTF8String;
  TreeNodeTorrent, TreeNodeFiles, TreeNodeTrackers, TreeNodeInfo: TTreeNode;
begin
  //Called after loading torrent file.


  TorrentFileNameStr := ExtractFileName(FDecodePresentTorrent.FilenameTorrent);

  //---------------------   Add it to the checklist box Public/private torrent
  RowIndex := CheckListBoxPublicPrivateTorrent.Items.Add(TorrentFileNameStr);
  //Check it for public/private flag
  CheckListBoxPublicPrivateTorrent.Checked[RowIndex] :=
    not FDecodePresentTorrent.PrivateTorrent;


  //---------------------  Fill the Grid Torrent Data/Info

  //date time in iso format
  if FDecodePresentTorrent.CreatedDate <> 0 then
    DateTimeToString(DateTimeStr, 'yyyy-MM-dd hh:nn:ss',
      FDecodePresentTorrent.CreatedDate)
  else //some torrent does not have CreatedDate
    DateTimeStr := '';

  //private or public torrent
  if FDecodePresentTorrent.PrivateTorrent then
    PrivateStr := 'yes'
  else
    PrivateStr := 'no';

  //Copy all the torrent info to the grid column.
  FControlerGridTorrentData.TorrentFile := TorrentFileNameStr;
  FControlerGridTorrentData.InfoFileName := FDecodePresentTorrent.Name;
  FControlerGridTorrentData.InfoHash := FDecodePresentTorrent.InfoHash;
  FControlerGridTorrentData.CreatedOn := DateTimeStr;
  FControlerGridTorrentData.CreatedBy := FDecodePresentTorrent.CreatedBy;
  FControlerGridTorrentData.Comment := FDecodePresentTorrent.Comment;
  FControlerGridTorrentData.PrivateTorrent := PrivateStr;
  FControlerGridTorrentData.PieceLength :=
    format('%6d', [FDecodePresentTorrent.PieceLenght div 1024]); //Show as KiBytes
  FControlerGridTorrentData.TotaSize :=
    format('%9d', [FDecodePresentTorrent.TotalFileSize div 1024]); //Show as KiBytes
  FControlerGridTorrentData.IndexOrder :=
    format('%6d', [StringGridTorrentData.RowCount - 1]);
  //Must keep track of order when sorted back

  //All the string data are filed. Copy it now to the grid
  FControlerGridTorrentData.AppendRow;

  //---------------------  Fill the treeview with torrent files

  //Add the torrent file name + size of all the files combined.
  TorrentFileNameStr := TorrentFileNameStr + '     SIZE: ' +
    ByteSizeToBiggerSizeFormatStr(FDecodePresentTorrent.TotalFileSize);



  TreeNodeTorrent := TreeViewFileContents.Items.AddChild(FTreeNodeRoot,
    //FTorrentFileNameList[RowIndex]); //With directory path
    TorrentFileNameStr);  //Without directory  path

  TreeNodeFiles := TreeViewFileContents.Items.AddChild(TreeNodeTorrent, 'Files');
  TreeNodeTrackers := TreeViewFileContents.Items.AddChild(TreeNodeTorrent,
    'Trackers');
  TreeNodeInfo := TreeViewFileContents.Items.AddChild(TreeNodeTorrent, 'Info');

  //Show all the files inside the torrent
  if FDecodePresentTorrent.InfoFilesCount > 0 then
  begin
    for CountFiles := 0 to FDecodePresentTorrent.InfoFilesCount - 1 do
    begin
      TreeViewFileContents.Items.AddChild(TreeNodeFiles,
        FDecodePresentTorrent.InfoFilesNameIndex(CountFiles) +
        '     SIZE: ' + ByteSizeToBiggerSizeFormatStr(
        FDecodePresentTorrent.InfoFilesLengthIndex(CountFiles)));
    end;
  end;

  //Show a how many files are there
  TreeNodeFiles.Text := TreeNodeFiles.Text + ' (' + IntToStr(TreeNodeFiles.Count) + ')';


  //Show all the trackers inside the torrent
  for TrackerStr in FDecodePresentTorrent.TrackerList do
  begin
    TreeViewFileContents.Items.AddChild(TreeNodeTrackers, TrackerStr);
  end;

  //Show a how many trackers are there
  TreeNodeTrackers.Text := TreeNodeTrackers.Text + ' (' +
    IntToStr(TreeNodeTrackers.Count) + ')';


  //Show all the info of torrent
  TreeViewFileContents.Items.AddChild(TreeNodeInfo, 'Name: ' +
    FDecodePresentTorrent.Name);
  TreeViewFileContents.Items.AddChild(TreeNodeInfo, 'Comment: ' +
    FDecodePresentTorrent.Comment);
  TreeViewFileContents.Items.AddChild(TreeNodeInfo, 'Info Hash: ' +
    FDecodePresentTorrent.InfoHash);
  TreeViewFileContents.Items.AddChild(TreeNodeInfo, 'Created On: ' + DateTimeStr);
  TreeViewFileContents.Items.AddChild(TreeNodeInfo, 'Created By: ' +
    FDecodePresentTorrent.CreatedBy);
  TreeViewFileContents.Items.AddChild(TreeNodeInfo, 'Piece Lenght: ' +
    IntToStr(FDecodePresentTorrent.PieceLenght div 1024) + ' KiB');
  if FDecodePresentTorrent.PrivateTorrent then
  begin
    TreeViewFileContents.Items.AddChild(TreeNodeInfo, 'Private: yes');
  end
  else
  begin
    TreeViewFileContents.Items.AddChild(TreeNodeInfo, 'Private: no');
  end;


  //All the files count inside the torrent must be added to FTotalFileInsideTorrent
  Inc(FTotalFileInsideTorrent, FDecodePresentTorrent.InfoFilesCount);

  //The file size of all files inside the torrent must be added to FTotalFileSizeInsideTorrent
  Inc(FTotalFileSizeInsideTorrent, FDecodePresentTorrent.TotalFileSize);

end;



procedure TFormTrackerModify.ViewUpdateEnd;
begin

  //Called after loading torrent file
  //Sync the popup menu with show/hide items.
  MenuItemTorrentFilesTreeSyncWithPopupMenu;


  //Show what we have updated.
  TreeViewFileContents.EndUpdate;
  StringGridTorrentData.EndUpdate;
  CheckListBoxPublicPrivateTorrent.Items.EndUpdate;


  //Show the size of all the files inside the torrent
  //http://en.wikipedia.org/wiki/Gigabyte
  GroupBoxTorrentContents.Caption :=
    TORRENT_FILES_CONTENTS_FORM_CAPTION + ' (Files count: ' +
    IntToStr(FTotalFileInsideTorrent) + ') Files sizes: ' +
    ByteSizeToBiggerSizeFormatStr(FTotalFileSizeInsideTorrent) + '';


  GroupBoxPresentTracker.Caption :=
    'Present trackers in all torrent files.' +
    ' Select the one that you want to keep. (List count: ' +
    IntToStr(FTrackerFromInsideTorrentFilesList.Count) + ' )';



  //Show all the tracker inside the torrent files.
  ShowTrackerInsideFileList;
  //Mark all trackers as selected
  CheckedOnOffAllTrackers(True);
  //Some tracker must be removed. Console and windows mode.
  UpdateViewRemoveTracker;


  //Show user how many files are loaded
  ViewUpdateFormCaption;

end;

procedure TFormTrackerModify.ViewUpdateFormCaption;
//var
  //ProcessTimeStr: string;
//  Hour, Minute, Second, MilliSecond: word;
begin
  //Called when user load the torrent + update the torrent.

{ //for performance debugging.
  DecodeTime(FProcessTimeTotal, Hour, Minute, Second, MilliSecond);
  ProcessTimeStr := IntToStr((Second * 1000) + MilliSecond) + ' mSec';
}

  //Show user how many files are loaded
  Caption := FORM_CAPTION + '( Torrent files: ' +
    IntToStr(FTorrentFileNameList.Count) + ' )';
  //  + ' (Process Time: ' +  ProcessTimeStr + ' )'; //for debug purpose.
end;

procedure TFormTrackerModify.ShowHourGlassCursor(HourGlass: boolean);
begin
  if HourGlass then
  begin
    screen.Cursor := crHourGlass;
    FProcessTimeStart := now;
  end
  else
  begin
    screen.Cursor := crDefault;
    FProcessTimeTotal := now - FProcessTimeStart;
  end;




end;



end.
