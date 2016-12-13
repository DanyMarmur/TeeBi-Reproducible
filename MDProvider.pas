unit MDProvider;

interface

uses
  System.SysUtils,
  System.Types,
  Data.DB,
  //IB_Components,
  //Datasnap.DBClient,
  BI.Data,
  BI.Dataset,

  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.StorageBin, FireDAC.Comp.DataSet, FireDAC.Comp.Client  ;

type
  TFLBIDataSet = class helper for TBIDataSet
    type
      RBIDataSetRefreshInfo = record
        WasActive: Boolean;
        PreviousPosition: TBookmark;
        NumRec: Integer;
      end;
    procedure DoRefresh(aRefreshProc: TProc; const aActivate: Boolean = true);
  private
    procedure BeginUpdate(var aBIDataSetRefreshInfo: RBIDataSetRefreshInfo);
    procedure EndUpdate(const aBIDataSetRefreshInfo: RBIDataSetRefreshInfo);
  end;

  TIBCursorProvider = class(TDataProvider)
  private
    FMasterParent: TDataItem;
    FMasterParamValues: TStringDynArray;


    FLoadingDataItem: TDataItem;

    //FSavedEventAfterRowFetch: TIB_DatasetEvent;
    //FSavedEventAfterFetchEof: TIB_DatasetEvent;

    FDMemTableAfterGetRecord: TDatasetNotifyEvent;
    FDMemTableAfterGetRecords: TFDDatasetEvent;

    FClientDS: TFDMemTable;
    //FIB_Cursor: TIB_Cursor;
    procedure SetIB_Cursor(const Value: TFDMemTable);

    procedure ClientDataSetAfterGetRecord(DataSet: TDataSet);
    procedure ClientDataSetAfterGetRecords(DataSet: TFDDataSet);

  protected
    procedure Load(const AData:TDataItem; const Children:Boolean); override;

  public
    property IB_Cursor: TFDMemTable read FClientDS write SetIB_Cursor;
    property MasterParent: TDataItem read FMasterParent write FMasterParent;
    property MasterParamValues: TStringDynArray read FMasterParamValues write FMasterParamValues;
  end;

implementation

uses
  //IBODataset,
  BI.Data.DataSet;

{ TIBCursorProvider }

procedure TIBCursorProvider.ClientDataSetAfterGetRecords(DataSet: TFDDataSet);
begin
    // Original Event Handler
  if Assigned( FDMemTableAfterGetRecords )  then
    FDMemTableAfterGetRecords(DataSet);
end;

procedure TIBCursorProvider.ClientDataSetAfterGetRecord(DataSet: TDataset);
var
  I: Integer;
begin
    // Implement Delta!
  FLoadingDataItem.Resize(Dataset.RecNo);

  for I := 0 to Dataset.FieldCount - 1 do
  begin
    if Dataset.Fields[I].IsBlob then // No-op for now
    else if Dataset.Fields[I].IsNull then
      FLoadingDataItem[I].Missing[Dataset.RecNo-1] := true
    else
    begin
      case FLoadingDataItem[I].Kind of
        dkInt32:    FLoadingDataItem[I].Int32Data[Dataset.RecNo-1]    := Dataset.Fields[I].AsInteger;
        dkInt64:    FLoadingDataItem[I].Int64Data[Dataset.RecNo-1]    := Dataset.Fields[I].AsLargeInt;
        dkSingle:   FLoadingDataItem[I].SingleData[Dataset.RecNo-1]   := Dataset.Fields[I].AsSingle;
        dkDouble:   FLoadingDataItem[I].DoubleData[Dataset.RecNo-1]   := Dataset.Fields[I].AsFloat;
        dkExtended: FLoadingDataItem[I].ExtendedData[Dataset.RecNo-1] := Dataset.Fields[I].AsExtended;
        dkText:     FLoadingDataItem[I].TextData[Dataset.RecNo-1]     := Dataset.Fields[I].AsString;
        dkDateTime: FLoadingDataItem[I].DateTimeData[Dataset.RecNo-1] := Dataset.Fields[I].AsDateTime;
        dkBoolean:  FLoadingDataItem[I].BooleanData[Dataset.RecNo-1]  := Dataset.Fields[I].AsBoolean;
      else
        //raise Exception.Create('Unknown field: ' + IB_Dataset.Fields[I].FullFieldName);
      end;
    end;
  end;

    // Original Event Handler
  if Assigned( FDMemTableAfterGetRecord ) then
    FDMemTableAfterGetRecord(DataSet);
end;

procedure TIBCursorProvider.Load(const AData: TDataItem; const Children: Boolean);
var
  I: Integer;

  NewDataType: TFieldType;
  NewDataSize: integer;
  NewDataPrecision: integer;
  BoolList: boolean;

  lDataItem: TDataItem;
begin
  FLoadingDataItem := AData;
  FLoadingDataItem.Clear;
  FLoadingDataItem.AsTable := true;

  //if not FClientDS.Prepared then
  //  FClientDS.Prepare;

    // Params was stored for this request
  //for I := 0 to IB_Cursor.ParamCount - 1 do
  //  if I < Length(FMasterParamValues) then
  //    IB_Cursor.Params[I].AsString := FMasterParamValues[I];

    // If our source is prepared (just cleared out the items)
  //if IB_Cursor.Prepared {and (FLoadingDataItem.Items.Count = 0)} then
    for I := 0 to FClientDS.FieldCount - 1 do
    begin
      //GetDataTypeAndSize( IB_Cursor.Fields[I],
      //                    NewDataType,
      //                    NewDataSize,
      //                    NewDataPrecision,
      //                    BoolList);

      lDataItem :=
        FLoadingDataItem.Items.Add(
          FClientDS.Fields[I].FieldName,
          TBIDataSetSource.FieldKind(FClientDS.Fields[I].DataType));

      //if FClientDS.Fields[I].IsPrimary then
      //begin
      //  lDataItem.Primary :=
      //    IB_Cursor.Fields[I].IsPrimary;
      //end;

        // Needs to know where its master is...
        // Hardcoded for testing
      //if (IB_Cursor.Name = 'ibcurContactsContacts') and
      //   (IB_Cursor.Fields[I].FieldName = 'CONTACT_AT_ID') and
      //   (FMasterParent <> nil) then
      //  lDataItem.Master := FMasterParent.Items.Find('CONTACT_ID');

        // Fails for me at TDataItem.SetMaster last line
        // I have this working in the "real" sample
        // I have no idea how i managed that.
        // Tried a TDataItem having both dataitems added to

        // When we connect fields using the masters actual object,
        // could it not be stored? I could also write "event" code
        // to find the master for BI.Data (at all times).
      if (IB_Cursor.Name = 'FDMemTable2') and
         (FClientDS.Fields[I].FieldName = 'OrderID') and
         (FMasterParent <> nil) then
        lDataItem.Master := FMasterParent.Items.Find('OrderID');
    end;

    // Get the data too,
    // this will fire the Cursors fetch events
  //if FClientDS.Prepared then
    //if FClientDS.Active then
      //FClientDS.Refresh else
      //FClientDS.Open;

    // "Simulation" of IBObjects cursor that "drives" the fetching
    // (very effishient - not this, but above).
  FClientDS.First;
  while not FClientDS.Eof do
  begin
    FClientDS.Next;
  end;

  SetLength(FMasterParamValues, 0);
end;

procedure TIBCursorProvider.SetIB_Cursor(const Value: TFDMemTable);
begin
  if FClientDS <> Value then
  begin
      // Restore events from previous Cursor
    if FClientDS <> nil then
    begin
      FClientDS.AfterScroll := FDMemTableAfterGetRecord;
      FClientDS.AfterGetRecords := FDMemTableAfterGetRecords;

      FDMemTableAfterGetRecord := nil;
      FDMemTableAfterGetRecords := nil;
    end;

      // Add events to the new Cursor
    if (Value <> nil) then
    begin
      FDMemTableAfterGetRecord := Value.AfterScroll; // FetchRow;
      FDMemTableAfterGetRecords := Value.AfterGetRecords; // FetchEof;

      Value.AfterScroll := ClientDataSetAfterGetRecord;
      Value.AfterGetRecords := ClientDataSetAfterGetRecords;

        // Settings - maybe we should not be so intrusive
      //Value.AutoFetchAll := true;
    end;

      // Remember me!
    FClientDS := Value;
  end;
end;

{ TFLBIDataSet }

  // Something i did to be able to update / refresh w/o corruption of data,
  // inspired by TBIDatasetSource.LoadData.
  // This will hopefully not be needed
procedure TFLBIDataSet.BeginUpdate(var aBIDataSetRefreshInfo: RBIDataSetRefreshInfo);
begin
  aBIDataSetRefreshInfo.WasActive := Active;
  aBIDataSetRefreshInfo.PreviousPosition := GetBookMark;

  DisableControls;

    // Will be used for better resizing l8er..
  //aBIDataSetRefreshInfo.NumRec := RecordCount; // Starts the fetching (only with FDMemDataTable)

  if Active then
    Active := false;
end;

procedure TFLBIDataSet.DoRefresh(aRefreshProc: TProc; const aActivate: Boolean = true);
var
  lFLBIDataSetRefreshInfo: RBIDataSetRefreshInfo;
begin
  BeginUpdate(lFLBIDataSetRefreshInfo);
  try
    aRefreshProc;
  finally
    if aActivate then
      lFLBIDataSetRefreshInfo.WasActive := true;

    EndUpdate(lFLBIDataSetRefreshInfo);
  end;
end;

procedure TFLBIDataSet.EndUpdate(const aBIDataSetRefreshInfo: RBIDataSetRefreshInfo);
begin
  if Active <> aBIDataSetRefreshInfo.WasActive then
    Active := aBIDataSetRefreshInfo.WasActive;

  if Assigned( aBIDataSetRefreshInfo.PreviousPosition ) then begin
    GotoBookmark(aBIDataSetRefreshInfo.PreviousPosition);
    FreeBookmark(aBIDataSetRefreshInfo.PreviousPosition);
  end;

  EnableControls;
end;

end.
