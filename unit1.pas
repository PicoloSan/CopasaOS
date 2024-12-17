unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids, StdCtrls,
  Buttons, DateTimePicker, Unit2, DB;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    DataSource1: TDataSource;
    DateTimePicker1: TDateTimePicker;
    DBGrid1: TDBGrid;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    OpenDialog1: TOpenDialog;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    function CDate(umaData: String) : TDateTime;
    function CBool(umBoleano: String) : integer;
    function CFloat(umFloat: String) : Double;
    procedure LoadToDatabase(CSVValues: array of string);
    procedure RegistrarLog(Conteudo: String);
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Ativar a conexão
  try
    DM.ZConnection1.Connect; // Conectar ao banco de dados
    // ShowMessage('Banco de dados conectado com sucesso!');
    DM.TB_OS_Medicao.Open;
  except
    on E: Exception do
      ShowMessage('Erro ao conectar ao banco de dados: ' + E.Message);
  end;

  {
  ShowMessage('Data 11/12/2024 - ' + DateTimeToStr(CDate('11/12/2024')));
  ShowMessage('Data 11/12/2024 11:14:30 - ' + DateTimeToStr(CDate('11/12/2024 11:14:30')));
  ShowMessage('Boleano True : ' + BoolToStr(CBool('VERDADEIRO')));
  ShowMessage('Boleano False : ' + BoolToStr(CBool('FALSO')));
  }

end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

  // Desconectar do banco de dados, se estiver ativo
  if DM.ZConnection1.Connected then
  begin
    try
      DM.TB_OS_Medicao.Close;
      DM.ZConnection1.Disconnect; // Desconecta do banco de dados
      // ShowMessage('Banco de dados desconectado com sucesso.');
    except
      on E: Exception do
        ShowMessage('Erro ao desconectar do banco de dados: ' + E.Message);
    end;
  end;

  // Certifique-se de fechar o dataset aqui para liberar os recursos
  if DM.CSV_OS_Medicao.Active then
    DM.CSV_OS_Medicao.Active := False; // Fecha o dataset se estiver ativo

  // Defina a ação de fechamento - pode ser caFree ou caClose
  CloseAction := caFree; // Libera o formulário da memória
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Edit1.Text := OpenDialog1.FileName;
  end;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
var
  CSVArray : array of String;
  I : integer;
begin
  if Edit1.Text <> '' then // Exibe o diálogo para abrir arquivo
  begin
    DM.CSV_OS_Medicao.FileName := Edit1.Text;

    DM.CSV_OS_Medicao.CSVOptions.FirstLineAsFieldNames := True;
    DM.CSV_OS_Medicao.CSVOptions.QuoteChar := '"';

    DM.CSV_OS_Medicao.Active := True;

    // Configura o tamanho do Vetor Array
    SetLength(CSVArray, DM.CSV_OS_Medicao.FieldCount);

    DM.CSV_OS_Medicao.First;
    while not DM.CSV_OS_Medicao.EOF do
    begin
      for I := 0 to DM.CSV_OS_Medicao.FieldCount - 1 do
      begin
        CSVArray[I] := DM.CSV_OS_Medicao.Fields[I].AsString;
      end;

      LoadToDatabase(CSVArray);

      DM.CSV_OS_Medicao.Next;
    end;

    DM.TB_OS_Medicao.Refresh;
    ShowMessage('Importação executada com sucesso! Verifique o Log para maiores informações.');

    {
    for I := 0 to DBGrid1.Columns.Count - 1 do
    begin
      DBGrid1.Columns[I].Width := 50;
    end;
    }

  end;
end;

function TForm1.CDate(umaData: String) : TDateTime;
var
  DateTimeValue: TDateTime;
  FormatSettings: TFormatSettings;
begin
  FormatSettings.DateSeparator := '/';
  FormatSettings.TimeSeparator := ':';

  FormatSettings.ShortDateFormat := 'dd/mm/yyyy';
  FormatSettings.ShortTimeFormat := 'hh:mm:ss';
  try
    DateTimeValue := StrToDateTime(umaData, FormatSettings);
  except
    on E: EConvertError do
    begin
      // Não consegui converter, trate a exceção conforme necessário
      RegistrarLog('Erro ao converter a data: ' + E.Message);
      Exit; // Saia da procedure ou método, se necessário
    end;
  end;

  // Retorna a data convertida
  Result := DateTimeValue;
end;

function TForm1.CBool(umBoleano: String): integer;
begin
  if umBoleano = 'VERDADEIRO' then
    Result := -1
  else
    Result := 0;
end;

procedure TForm1.LoadToDatabase(CSVValues: array of string);
var
  dataPlanilha: TDateTime;
  varSQL : TStringList;
begin
  varSQL := TStringList.Create;
  dataPlanilha := DateTimePicker1.DateTime;

  try
    varSQL.Append('INSERT INTO "OS_Medicao" ');
    varSQL.Append('("OS_numero", "Data_Planilha", "Valor_Medicao", "Escritorio", ');
    varSQL.Append('"Status", "Desc_Servico", "Data_Limite", "Data_Execucao", ');
    varSQL.Append('"Em_dia", "Matricula", "Responsavel", "Resultado", "Ocorrencia") ');
    varSQL.Append('VALUES (:OS_Numero, :Data_Planilha, :Valor_Medicao, ');
    varSQL.Append(':Escritorio, :Status, :Desc_Servico, :Data_Limite, ');
    varSQL.Append(':Data_Execucao, :Em_dia, :Matricula, :Responsavel, ');
    varSQL.Append(':Resultado, :Ocorrencia);');

    DM.ZConnection1.StartTransaction;

    DM.ZQuery1.SQL.Text := varSQL.Text;

    with DM.ZQuery1.Params do
    begin
      ParamByName('OS_numero').AsInt64 := StrToInt64(CSVValues[2]);
      ParamByName('Data_Planilha').AsDate := dataPlanilha;
      ParamByName('Valor_Medicao').AsFloat := CFloat(CSVValues[3]);
      ParamByName('Escritorio').AsString := CSVValues[0];
      ParamByName('Status').AsString := CSVValues[1];
      ParamByName('Desc_Servico').AsString := CSVValues[4];
      ParamByName('Data_Limite').AsDate := CDate(CSVValues[5]);
      ParamByName('Data_Execucao').AsDate := CDate(CSVValues[6]);
      ParamByName('Em_dia').AsInteger := CBool(CSVValues[7]);
      ParamByName('Matricula').AsInt64 := StrToInt64(CSVValues[8]);
      ParamByName('Responsavel').AsString := CSVValues[9];
      ParamByName('Resultado').AsString := CSVValues[10];
      ParamByName('Ocorrencia').AsString := CSVValues[11];
    end;

    DM.ZQuery1.ExecSQL;
    DM.ZConnection1.Commit;
    varSQL.Free;
  except
    on E: Exception do
    begin
      RegistrarLog('Erro ao inserir dados: ' + E.Message);
      DM.ZConnection1.Rollback;
    end;
  end;
end;

procedure TForm1.RegistrarLog(Conteudo: String);
var
  Arquivo: TextFile;
  NomeArquivo: String;
begin
  NomeArquivo := IncludeTrailingPathDelimiter(GetCurrentDir) + 'aplicacao.log';
  AssignFile(Arquivo, NomeArquivo);

  try
    Append(arquivo);
    Writeln(arquivo, Conteudo);
  except
    Rewrite(arquivo);
    Writeln(arquivo, Conteudo);
  end;

  CloseFile(arquivo);
end;

function TForm1.CFloat(umFloat: String) : Double;
var
  umaString: String;
begin
  if umFloat = '' then
  begin
    result := StrToFloat('0,0');
  end
  else
  begin
    umaString := StringReplace(umFloat, 'R$ ', '', [rfReplaceAll]);
    // umaString := StringReplace(umaString, '.', '', [rfReplaceAll]);
    // umaString := StringReplace(umaString, ',', '.', [rfReplaceAll]);
    umaString := StringReplace(umaString, ' ', '', [rfReplaceAll]);
    result := StrToFloat(umaString);
  end;
end;

end.

