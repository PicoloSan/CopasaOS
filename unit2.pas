unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, csvdataset, DB, ZConnection, ZDataset;

type

  { TDM }

  TDM = class(TDataModule)
    CSV_OS_Medicao: TCSVDataset;
    ZConnection1: TZConnection;
    ZQuery1: TZQuery;
    TB_OS_Medicao: TZTable;
    ZTransaction1: TZTransaction;
    procedure ZConnection1BeforeConnect(Sender: TObject);
  private

  public

  end;

var
  DM: TDM;

implementation

{$R *.lfm}

{ TDM }

procedure TDM.ZConnection1BeforeConnect(Sender: TObject);
begin
  with ZConnection1 do
  begin
    LibraryLocation := IncludeTrailingPathDelimiter(GetCurrentDir) + 'database\fbembed.dll';
    Database := IncludeTrailingPathDelimiter(GetCurrentDir) + 'database\OS_COPASA.FDB';
    User := 'sysdba';
    Password := 'masterkey';
    Protocol := 'firebird';
  end;
end;

end.

