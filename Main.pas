unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, REST.Types,
  FMX.Controls.Presentation, FMX.StdCtrls, FMXTee.Engine, FMXTee.Series,
  FMXTee.Procs, FMXTee.Chart, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, REST.Response.Adapter, REST.Client, Data.Bind.Components,
  Data.Bind.ObjectScope, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  System.Net.URLClient, System.Net.HttpClient, System.Net.HttpClientComponent, json, System.Threading;

    const
    NOT_BUSY = 0;
    BUSY = 1;

type
  TForm1 = class(TForm)
    Button1: TButton;
    NetHTTPClient1: TNetHTTPClient;
    ToolBar1: TToolBar;
    Label1: TLabel;
    StatusLabel: TLabel;
    Chart1: TChart;
    Series1: TLineSeries;
    ProgressBar1: TProgressBar;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}


// Функция преобразует MemoryStream в строку (текст)
function StreamToString(aStream: TStream): string;
var
  SS: TStringStream;
begin
  if aStream <> nil then
  begin
    SS := TStringStream.Create('');
    try
      SS.CopyFrom(aStream, 0);
      Result := SS.DataString;
    finally
      SS.Free;
    end;
  end else
  begin
    Result := '';
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var s:string; JSON: TJSONObject;
    JSONValues: TJSONArray;
begin
  if NetHTTPClient1.Tag=NOT_BUSY then
    begin
        NetHTTPClient1.Tag := BUSY;

      TTask.Run(procedure var LResponse: TMemoryStream;
      var i:integer;
      begin

              TThread.Synchronize(nil, procedure
              begin
                StatusLabel.Text:='Waiting for answer...';
                Exit;
              end);

        LResponse := TMemoryStream.Create;

        try
              // Посылаем GET запрос на сервер api.blockchain.info
              NetHTTPClient1.Get('https://api.blockchain.info/charts/transactions-per-second',LResponse);

              TThread.Synchronize(nil, procedure
              begin
                Chart1.Series[0].Clear;
                Exit;
              end);

              TThread.Synchronize(nil, procedure
              begin
                StatusLabel.Text:='Working...';
                Exit;
              end);

              s:=StreamToString(LResponse);

              // Инициализируем обьекты для работы с JSON
              JSON := TJSONObject.ParseJSONValue(s) as TJSONObject;
              JSONValues:=TJSONArray(JSON.Get('values').JsonValue);

              ProgressBar1.Max:=JSONValues.Size-1;
              ProgressBar1.Value:=0;

            // Парсим полученный ответ и достаем из него информацию
            for i:=0 to JSONValues.Size-1 do
            begin
              TThread.Synchronize(nil, procedure
              begin
                 Chart1.Series[0].AddXY((TJSONPair(TJSONObject(JSONValues.Get(i)).Get('x')).JsonValue.Value).ToDouble(),(TJSONPair(TJSONObject(JSONValues.Get(i)).Get('y')).JsonValue.Value).ToDouble());
                 Exit;
              end);

              TThread.Synchronize(nil, procedure
              begin
                ProgressBar1.Value:=i;
                Exit;
              end);
            end;

        finally

          LResponse.Free;

              TThread.Synchronize(nil, procedure
              begin
                StatusLabel.Text:='Ready';
                Exit;
              end);

          NetHTTPClient1.Tag := NOT_BUSY;

        end;
      end);
    end;
end;


end.
