unit uExemploJWTTimer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  REST.Client, REST.Types, System.JSON, uCmSpiThreadTimer;

type
  TfrmExemploJWT = class(TForm)
    Panel1: TPanel;
    btnIniciar: TButton;
    btnParar: TButton;
    btnObterToken: TButton;
    btnForcarRenovacao: TButton;
    Panel2: TPanel;
    memoLog: TMemo;
    Label1: TLabel;
    Panel3: TPanel;
    lblStatus: TLabel;
    lblTokenInfo: TLabel;
    lblUltimaRenovacao: TLabel;
    btnLimparLog: TButton;
    GroupBox1: TGroupBox;
    chkLogHabilitado: TCheckBox;
    cmbNivelLog: TComboBox;
    Label2: TLabel;
    edtIntervalo: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnIniciarClick(Sender: TObject);
    procedure btnPararClick(Sender: TObject);
    procedure btnObterTokenClick(Sender: TObject);
    procedure btnForcarRenovacaoClick(Sender: TObject);
    procedure btnLimparLogClick(Sender: TObject);
    procedure chkLogHabilitadoClick(Sender: TObject);
    procedure cmbNivelLogChange(Sender: TObject);
  private
    FJWTTimer: TJWTTimerThread;
    
    // Simula uma requisição REST para obter JWT
    function ExecutarRequisicaoJWT: string;
    
    // Event handlers
    procedure OnTokenAtualizado(const ANewToken: string; ASuccess: Boolean);
    procedure OnLogRecebido(const ALevel: TLogLevel; const AMessage: string; const ADateTime: TDateTime);
    
    // Métodos auxiliares
    procedure AtualizarInterface;
    procedure AdicionarLogInterface(const ALevel: TLogLevel; const AMessage: string);
    function GetLogLevelString(const ALevel: TLogLevel): string;
    function StringToLogLevel(const AStr: string): TLogLevel;
  public
    
  end;

var
  frmExemploJWT: TfrmExemploJWT;

implementation

{$R *.dfm}

procedure TfrmExemploJWT.FormCreate(Sender: TObject);
begin
  FJWTTimer := nil;
  
  // Configurar combo de nível de log
  cmbNivelLog.Items.Clear;
  cmbNivelLog.Items.Add('DEBUG');
  cmbNivelLog.Items.Add('INFO');
  cmbNivelLog.Items.Add('WARNING');
  cmbNivelLog.Items.Add('ERROR');
  cmbNivelLog.Items.Add('CRITICAL');
  cmbNivelLog.ItemIndex := 1; // INFO por padrão
  
  edtIntervalo.Text := '2'; // 2 minutos para teste
  chkLogHabilitado.Checked := True;
  
  AtualizarInterface;
  
  memoLog.Lines.Add('=== Exemplo JWT Timer Thread ===');
  memoLog.Lines.Add('Aplicação iniciada em: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
  memoLog.Lines.Add('');
end;

procedure TfrmExemploJWT.FormDestroy(Sender: TObject);
begin
  if Assigned(FJWTTimer) then
  begin
    FJWTTimer.StopTimer;
    FreeAndNil(FJWTTimer);
  end;
end;

procedure TfrmExemploJWT.btnIniciarClick(Sender: TObject);
var
  LIntervalo: Integer;
begin
  if Assigned(FJWTTimer) then
  begin
    ShowMessage('Timer já está rodando!');
    Exit;
  end;
  
  // Validar intervalo
  if not TryStrToInt(edtIntervalo.Text, LIntervalo) or (LIntervalo < 1) then
  begin
    ShowMessage('Digite um intervalo válido (mínimo 1 minuto)');
    edtIntervalo.SetFocus;
    Exit;
  end;
  
  try
    // Criar a thread timer
    FJWTTimer := TJWTTimerThread.Create(LIntervalo, ExecutarRequisicaoJWT);
    
    // Configurar eventos
    FJWTTimer.OnTokenUpdated := OnTokenAtualizado;
    FJWTTimer.OnLog := OnLogRecebido;
    
    // Configurar log se habilitado
    if chkLogHabilitado.Checked then
    begin
      FJWTTimer.EnableLog(True, '', StringToLogLevel(cmbNivelLog.Text));
    end;
    
    AtualizarInterface;
    memoLog.Lines.Add(Format('[APP] Timer iniciado com intervalo de %d minuto(s)', [LIntervalo]));
    
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao iniciar timer: ' + E.Message);
    end;
  end;
end;

procedure TfrmExemploJWT.btnPararClick(Sender: TObject);
begin
  if not Assigned(FJWTTimer) then
  begin
    ShowMessage('Timer não está rodando!');
    Exit;
  end;
  
  try
    memoLog.Lines.Add('[APP] Parando timer...');
    FJWTTimer.StopTimer;
    FreeAndNil(FJWTTimer);
    
    AtualizarInterface;
    memoLog.Lines.Add('[APP] Timer parado com sucesso');
    
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao parar timer: ' + E.Message);
    end;
  end;
end;

procedure TfrmExemploJWT.btnObterTokenClick(Sender: TObject);
var
  LToken: string;
begin
  if not Assigned(FJWTTimer) then
  begin
    ShowMessage('Timer não está rodando!');
    Exit;
  end;
  
  if FJWTTimer.IsTokenValid then
  begin
    LToken := FJWTTimer.CurrentToken;
    memoLog.Lines.Add(Format('[APP] Token atual obtido: %s...', [Copy(LToken, 1, 30)]));
    ShowMessage(Format('Token válido obtido!'#13#10'Tamanho: %d caracteres'#13#10'Início: %s...', 
      [Length(LToken), Copy(LToken, 1, 50)]));
  end
  else
  begin
    memoLog.Lines.Add('[APP] Token não está válido ou disponível');
    
    // Aguardar por token válido
    memoLog.Lines.Add('[APP] Aguardando token válido...');
    if FJWTTimer.WaitForToken(10000) then // 10 segundos
    begin
      LToken := FJWTTimer.CurrentToken;
      memoLog.Lines.Add('[APP] Token válido obtido após aguardar');
      ShowMessage('Token obtido após aguardar!');
    end
    else
    begin
      memoLog.Lines.Add('[APP] Timeout ao aguardar token válido');
      ShowMessage('Timeout: Token não foi obtido');
    end;
  end;
end;

procedure TfrmExemploJWT.btnForcarRenovacaoClick(Sender: TObject);
begin
  if not Assigned(FJWTTimer) then
  begin
    ShowMessage('Timer não está rodando!');
    Exit;
  end;
  
  memoLog.Lines.Add('[APP] Forçando renovação do token...');
  FJWTTimer.ForceTokenRefresh;
end;

procedure TfrmExemploJWT.btnLimparLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmExemploJWT.chkLogHabilitadoClick(Sender: TObject);
begin
  if Assigned(FJWTTimer) then
  begin
    if chkLogHabilitado.Checked then
      FJWTTimer.EnableLog(True, '', StringToLogLevel(cmbNivelLog.Text))
    else
      FJWTTimer.DisableLog;
  end;
end;

procedure TfrmExemploJWT.cmbNivelLogChange(Sender: TObject);
begin
  if Assigned(FJWTTimer) and chkLogHabilitado.Checked then
  begin
    FJWTTimer.SetLogLevel(StringToLogLevel(cmbNivelLog.Text));
  end;
end;

function TfrmExemploJWT.ExecutarRequisicaoJWT: string;
var
  RESTClient: TRESTClient;
  RESTRequest: TRESTRequest;
  RESTResponse: TRESTResponse;
  JSONResponse: TJSONObject;
  LSimulatedDelay: Integer;
begin
  Result := '';
  
  // Para este exemplo, vamos simular uma requisição REST
  // Em produção, substitua por sua implementação real
  
  try
    // Simula tempo de requisição (500ms a 2s)
    LSimulatedDelay := Random(1500) + 500;
    Sleep(LSimulatedDelay);
    
    // Simula falha ocasional (10% de chance)
    if Random(10) = 0 then
      raise Exception.Create('Simulated network error');
    
    // Gera um token JWT simulado
    Result := Format('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlVzZXIlZCIsImlhdCI6JWQsImV4cCI6JWR9.signature_%d_%s',
      [Random(9999),
       DateTimeToUnix(Now),
       DateTimeToUnix(Now) + 3600, // Expira em 1 hora
       Random(999999),
       FormatDateTime('hhnnss', Now)]);
       
    // Exemplo de implementação real comentada:
    {
    RESTClient := TRESTClient.Create(nil);
    RESTRequest := TRESTRequest.Create(nil);
    RESTResponse := TRESTResponse.Create(nil);
    
    try
      RESTClient.BaseURL := 'https://seu-servidor.com/api';
      RESTRequest.Client := RESTClient;
      RESTRequest.Response := RESTResponse;
      RESTRequest.Resource := '/auth/token';
      RESTRequest.Method := rmPOST;
      
      // Adicionar credenciais
      RESTRequest.AddParameter('username', 'seu_usuario', pkREQUESTBODY);
      RESTRequest.AddParameter('password', 'sua_senha', pkREQUESTBODY);
      
      RESTRequest.Execute;
      
      if RESTResponse.StatusCode = 200 then
      begin
        JSONResponse := TJSONObject.ParseJSONValue(RESTResponse.Content) as TJSONObject;
        try
          if Assigned(JSONResponse) then
            Result := JSONResponse.GetValue('access_token').Value;
        finally
          JSONResponse.Free;
        end;
      end;
      
    finally
      RESTResponse.Free;
      RESTRequest.Free;
      RESTClient.Free;
    end;
    }
    
  except
    on E: Exception do
    begin
      // Re-lança a exceção para que a thread trate
      raise Exception.Create('Erro na requisição JWT: ' + E.Message);
    end;
  end;
end;

procedure TfrmExemploJWT.OnTokenAtualizado(const ANewToken: string; ASuccess: Boolean);
begin
  if ASuccess then
  begin
    AdicionarLogInterface(llInfo, Format('Token atualizado com sucesso (tamanho: %d)', [Length(ANewToken)]));
  end
  else
  begin
    AdicionarLogInterface(llError, 'Falha ao atualizar token');
  end;
  
  AtualizarInterface;
end;

procedure TfrmExemploJWT.OnLogRecebido(const ALevel: TLogLevel; const AMessage: string; const ADateTime: TDateTime);
begin
  AdicionarLogInterface(ALevel, AMessage);
end;

procedure TfrmExemploJWT.AtualizarInterface;
var
  LToken: string;
begin
  if Assigned(FJWTTimer) then
  begin
    // Status
    if FJWTTimer.IsRunning then
      lblStatus.Caption := 'Status: RODANDO'
    else
      lblStatus.Caption := 'Status: PARADO';
    
    lblStatus.Font.Color := IfThen(FJWTTimer.IsRunning, clGreen, clRed);
    
    // Token info
    if FJWTTimer.TokenAvailable then
    begin
      LToken := FJWTTimer.CurrentToken;
      lblTokenInfo.Caption := Format('Token: %s... (%d chars)', [Copy(LToken, 1, 20), Length(LToken)]);
      
      if FJWTTimer.IsTokenValid then
      begin
        lblTokenInfo.Font.Color := clGreen;
        lblUltimaRenovacao.Caption := 'Status: VÁLIDO';
      end
      else
      begin
        lblTokenInfo.Font.Color := clRed;
        lblUltimaRenovacao.Caption := 'Status: EXPIRADO';
      end;
    end
    else
    begin
      lblTokenInfo.Caption := 'Token: Não disponível';
      lblTokenInfo.Font.Color := clGray;
      lblUltimaRenovacao.Caption := 'Status: Aguardando...';
    end;
    
    // Botões
    btnIniciar.Enabled := not FJWTTimer.IsRunning;
    btnParar.Enabled := FJWTTimer.IsRunning;
    btnObterToken.Enabled := FJWTTimer.IsRunning;
    btnForcarRenovacao.Enabled := FJWTTimer.IsRunning;
  end
  else
  begin
    lblStatus.Caption := 'Status: NÃO INICIADO';
    lblStatus.Font.Color := clGray;
    lblTokenInfo.Caption := 'Token: N/A';
    lblTokenInfo.Font.Color := clGray;
    lblUltimaRenovacao.Caption := 'Status: N/A';
    
    btnIniciar.Enabled := True;
    btnParar.Enabled := False;
    btnObterToken.Enabled := False;
    btnForcarRenovacao.Enabled := False;
  end;
end;

procedure TfrmExemploJWT.AdicionarLogInterface(const ALevel: TLogLevel; const AMessage: string);
var
  LLogEntry: string;
begin
  LLogEntry := Format('[%s] [%s] %s', 
    [FormatDateTime('hh:nn:ss', Now), GetLogLevelString(ALevel), AMessage]);
  
  memoLog.Lines.Add(LLogEntry);
  
  // Auto-scroll para o final
  SendMessage(memoLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

function TfrmExemploJWT.GetLogLevelString(const ALevel: TLogLevel): string;
begin
  case ALevel of
    llDebug: Result := 'DEBUG';
    llInfo: Result := 'INFO';
    llWarning: Result := 'WARNING';
    llError: Result := 'ERROR';
    llCritical: Result := 'CRITICAL';
  else
    Result := 'UNKNOWN';
  end;
end;

function TfrmExemploJWT.StringToLogLevel(const AStr: string): TLogLevel;
begin
  if AStr = 'DEBUG' then Result := llDebug
  else if AStr = 'INFO' then Result := llInfo
  else if AStr = 'WARNING' then Result := llWarning
  else if AStr = 'ERROR' then Result := llError
  else if AStr = 'CRITICAL' then Result := llCritical
  else Result := llInfo;
end;

end.


{===============================================================================
  ARQUIVO .DFM CORRESPONDENTE (frmExemploJWT.dfm)
===============================================================================}

(*
object frmExemploJWT: TfrmExemploJWT
  Left = 0
  Top = 0
  Caption = 'Exemplo JWT Timer Thread'
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 120
    Align = alTop
    TabOrder = 0
    
    object Label3: TLabel
      Left = 16
      Top = 16
      Width = 43
      Height = 13
      Caption = 'Intervalo:'
    end
    
    object Label4: TLabel
      Left = 120
      Top = 16
      Width = 42
      Height = 13
      Caption = 'minutos'
    end
    
    object btnIniciar: TButton
      Left = 200
      Top = 12
      Width = 100
      Height = 25
      Caption = 'Iniciar Timer'
      TabOrder = 0
      OnClick = btnIniciarClick
    end
    
    object btnParar: TButton
      Left = 306
      Top = 12
      Width = 100
      Height = 25
      Caption = 'Parar Timer'
      TabOrder = 1
      OnClick = btnPararClick
    end
    
    object btnObterToken: TButton
      Left = 412
      Top = 12
      Width = 100
      Height = 25
      Caption = 'Obter Token'
      TabOrder = 2
      OnClick = btnObterTokenClick
    end
    
    object btnForcarRenovacao: TButton
      Left = 518
      Top = 12
      Width = 120
      Height = 25
      Caption = 'Forçar Renovação'
      TabOrder = 3
      OnClick = btnForcarRenovacaoClick
    end
    
    object edtIntervalo: TEdit
      Left = 65
      Top = 13
      Width = 49
      Height = 21
      TabOrder = 4
      Text = '2'
    end
    
    object GroupBox1: TGroupBox
      Left = 16
      Top = 48
      Width = 300
      Height = 60
      Caption = ' Configurações de Log '
      TabOrder = 5
      
      object Label2: TLabel
        Left = 150
        Top = 24
        Width = 29
        Height = 13
        Caption = 'Nível:'
      end
      
      object chkLogHabilitado: TCheckBox
        Left = 16
        Top = 24
        Width = 120
        Height = 17
        Caption = 'Log Habilitado'
        TabOrder = 0
        OnClick = chkLogHabilitadoClick
      end
      
      object cmbNivelLog: TComboBox
        Left = 185
        Top = 21
        Width = 100
        Height = 21
        Style = csDropDownList
        TabOrder = 1
        OnChange = cmbNivelLogChange
      end
    end
  end
  
  object Panel3: TPanel
    Left = 0
    Top = 120
    Width = 800
    Height = 80
    Align = alTop
    TabOrder = 1
    
    object lblStatus: TLabel
      Left = 16
      Top = 16
      Width = 88
      Height = 13
      Caption = 'Status: Não iniciado'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    
    object lblTokenInfo: TLabel
      Left = 16
      Top = 35
      Width = 55
      Height = 13
      Caption = 'Token: N/A'
    end
    
    object lblUltimaRenovacao: TLabel
      Left = 16
      Top = 54
      Width = 58
      Height = 13
      Caption = 'Status: N/A'
    end
  end
  
  object Panel2: TPanel
    Left = 0
    Top = 200
    Width = 800
    Height = 400
    Align = alClient
    TabOrder = 2
    
    object Label1: TLabel
      Left = 16
      Top = 8
      Width = 18
      Height = 13
      Caption = 'Log'
    end
    
    object btnLimparLog: TButton
      Left = 700
      Top = 4
      Width = 75
      Height = 25
      Caption = 'Limpar'
      TabOrder = 0
      OnClick = btnLimparLogClick
    end
    
    object memoLog: TMemo
      Left = 16
      Top = 32
      Width = 760
      Height = 350
      ScrollBars = ssVertical
      TabOrder = 1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
    end
  end
end
*)