unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Datasnap.DBClient, BI.Data, BI.Dataset, MDProvider, Vcl.StdCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.StorageBin, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  BI.VCL.DataControl, BI.VCL.Grid;

type
  TMDPMain = class(TForm)
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    BIDataset1: TBIDataset;
    BIDataset2: TBIDataset;
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    Button1: TButton;
    BIDataset3: TBIDataset;
    BIDataset4: TBIDataset;
    FDMemTable1: TFDMemTable;
    FDMemTable2: TFDMemTable;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    FDataItem1: TDataItem;
    FDataItem2: TDataItem;
    IBCursorProvider1: TIBCursorProvider;
    IBCursorProvider2: TIBCursorProvider;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MDPMain: TMDPMain;

implementation

{$R *.dfm}

procedure TMDPMain.Button1Click(Sender: TObject);
begin
  BIDataset1.Active := true;
  BIDataset2.Active := true;
end;

procedure TMDPMain.Button2Click(Sender: TObject);
var
  lPosition: TBookmark;
begin
  lPosition := BIDataset1.GetBookmark;
  BIDataset1.DisableControls;
  BIDataset1.Active := false;

  try
    BIDataset1.Data.UnLoadData(true);
    BIDataset1.Data.Load(true);
  finally
    BIDataset1.Active := true;
    BIDataset1.GotoBookmark(lPosition);
    BIDataset1.EnableControls;
  end;
end;

procedure TMDPMain.Button3Click(Sender: TObject);
var
  lPosition: TBookmark;
begin
  lPosition := BIDataset1.GetBookmark;
  BIDataset2.DisableControls;
  BIDataset2.Active := false;

  try
    BIDataset2.Data.UnLoadData(true);
    BIDataset2.Data.Load(true);
  finally
    BIDataset2.Active := true;
    BIDataset2.GotoBookmark(lPosition);
    BIDataset2.EnableControls;
  end;
end;

procedure TMDPMain.Button4Click(Sender: TObject);
begin
  BIDataset1.Active := false;
  BIDataset2.Active := false;
end;

procedure TMDPMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FDataItem1.Free;
  FDataItem2.Free;
end;

procedure TMDPMain.FormCreate(Sender: TObject);
begin
  BIDataset2.Master := BIDataset1;

    // Will look better using the collection
  IBCursorProvider1 := TIBCursorProvider.Create(Self);
  IBCursorProvider1.IB_Cursor := FDMemTable1;

  FDataItem1 := IBCursorProvider1.NewData;
  FDataItem1.Name := IBCursorProvider1.IB_Cursor.Name;

  BIDataset1.Data := FDataItem1;

  IBCursorProvider2 := TIBCursorProvider.Create(Self);
  IBCursorProvider2.IB_Cursor := FDMemTable2;
  IBCursorProvider2.MasterParent := FDataItem1;

  FDataItem2 := IBCursorProvider2.NewData;
  FDataItem2.Name := IBCursorProvider2.IB_Cursor.Name;

  BIDataset2.Data := FDataItem2;
  BIDataset2.MasterDataLinkClass := TBIDataset.TBIMasterDataLink;
end;

end.
