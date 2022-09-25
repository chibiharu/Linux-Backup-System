@echo off

REM +--------------------------------------------------------------------+
REM | <スクリプトの説明>
REM | WindowsSystemBackupを取得する
REM |
REM | <更新日>
REM | 作成日：20211004
REM | 最終更新日：20211004
REM |
REM | <使用時における注意事項>
REM | ・本スクリプトの文字コードは「ANSI(SJIS)」を指定すること
REM | ・本スクリプトは<<<管理者権限>>>で実行すること
REM |
REM | <コメント>
REM | ・使用時の設定箇所 ⇒ [%drive%] [%BK_PATH%] [%LOG_PATH%] [%count%]
REM |   ※必要に応じて ⇒ [%username%] [%password%] [%dirlabel%]
REM +--------------------------------------------------------------------+


REM +--------------------------------------------------------------------+
REM | 事前準備
REM +--------------------------------------------------------------------+

REM +-- 管理者権限で実行しているか判定する --+
net session >nul 2>&1
if %ERRORLEVEL% equ 0 (
  echo バックアップ処理を実行中です...
) else (
  echo ##### エラー!!! #####
  echo 管理者権限で実行していません。
  echo 処理を中断します。
  echo 管理者権限で再度実行してください
  pause
  exit
)

REM +-- 現在の日付を取得(yyyy, mm, dd)を取得 --+
set YYYY=%date:~0,4%
set MM=%date:~5,2%
set dd=%date:~8,2%

REM +-- スクリプトの開始時刻を取得 --+
set time_tmp=%time: =0%
set now=%date:/=%%time_tmp:~0,2%%time_tmp:~3,2%%time_tmp:~6,2%



REM +--------------------------------------------------------------------+
REM | パラメータ設定
REM +--------------------------------------------------------------------+

REM
REM >>>>> [設定開始]
REM

REM +-- バックアップ先ドライブがローカルドライブの場合は<local>と指定する --+
REM +-- バックアップ先ドライブがネットワークドライブの場合は<network>と指定する --+
set drive=local

REM +-- バックアップ先ドライブが"ネットワークドライブ"の場合にユーザ名とパスワードを指定する --+
REM +-- ローカルの場合はデフォルト値で問題無い --+
set username=user
set password=passwd
set dirlabel=r

REM +-- バックアップイメージの出力先ドライブ(デフォルトではDドライブを指定) --+
REM +-- ネットワークドライブを指定する場合は[set BK_PATH=\\192.168.xx.xx\<ストレージ名>(\<ディレクトリ名>)]と指定する --+
set BK_PATH=d:

REM +-- 実行ログ保管ディレクトリ(デフォルトでは以下カレントディレクトリを指定) --+
set LOG_PATH=%CD%\

REM +-- バックアップ保存世代数 --+
REM +-- ※当日分を含めた過去分バックアップを保存する世代数 --+
REM +-- ※過去分バックアップを保存しない場合は1を指定する --+
set count=2

REM
REM <<<<< [設定終了]
REM

REM +-- ログディレクトリ名(yyyy) --+
set yyyy_DIR=%YYYY%\

REM +-- ログディレクトリ名(mm) --+
set mm_DIR=%MM%\

REM +-- ログファイル名 --+
set LOG_NAME=Windows10_SystemBackup_%YYYY%%MM%%dd%.log

REM +-- ログファイルフルパス --+
set LOG_FILE=%LOG_PATH%%yyyy_DIR%%mm_DIR%%LOG_NAME%

REM +-- バックアップイメージ出力先フルパス --+
set BK_DATA_before=%BK_PATH%\WindowsImageBackup

REM +-- バックアップイメージ移動後フルパス --+
set BK_DATA_after=%BK_PATH%\%COMPUTERNAME%\WindowsImageBackup_%YYYY%%MM%%dd%

REM +-- バックアップイメージ保管ディレクトリ --+
set backupdir=%BK_PATH%\%COMPUTERNAME%

REM +-- カレントディレクトリのパス --+
set cur=%CD%



REM +--------------------------------------------------------------------+
REM | 必要リソースの生成
REM +--------------------------------------------------------------------+

REM +-- ログディレクトリ(yyyy)を作成 --+
REM +-- チェック対象のディレクトリを指定 --+
set Check_yyyy_DIR=%LOG_PATH%%yyyy_DIR%
REM +-- ディレクトリが存在するかチェックする --+
if exist %Check_yyyy_DIR% goto CODE_OK_1
if not exist %Check_yyyy_DIR% goto Create_yyyy_DIR
:Create_yyyy_DIR
mkdir %Check_yyyy_DIR%
:CODE_OK_1
REM 処理無し

REM +-- ログディレクトリ(mm)を作成 --+
REM +-- チェック対象のディレクトリを指定 --+
set Check_mm_DIR=%LOG_PATH%%yyyy_DIR%%mm_DIR%
REM +-- ディレクトリが存在するかチェックする --+
if exist %Check_mm_DIR% goto CODE_OK_2
if not exist %Check_mm_DIR% goto Create_mm_DIR
:Create_mm_DIR
mkdir %Check_mm_DIR%
:CODE_OK_2
REM 処理無し



REM +--------------------------------------------------------------------+
REM | 実行前処理
REM +--------------------------------------------------------------------+

REM +-- バックアップ先ドライブが"ローカル"か"ネットワーク"かを判定する
if %drive% == network (
  REM "ネットワーク"の場合、ネットワークドライブへ接続する
  net use %dirlabel%: %BK_PATH% /user:%username% %password% > nul
) else if %drive% == local (
  REM 処理無し
) else (
  echo ##### エラー!!! #####
  echo %%drive%%の指定に誤りがあります
  echo 処理を中断します
  echo %%drive%%を"local"か"network"で再指定してください
  pause
  exit
)

REM +-- ログ見出し（開始時刻）出力 --+
Echo **************  Windows10_SystemBackup.bat %now% Start  ************** >> %LOG_FILE%



REM +--------------------------------------------------------------------+
REM | バックアップ処理
REM +--------------------------------------------------------------------+

REM +-- システムバックアップを取得する ⇒ 実行ログをログファイルへ出力する --+
wbadmin start backup -backupTarget:%BK_PATH% -allCritical -vssCopy -quiet >> %LOG_FILE%
REM mkdir %BK_PATH%\WindowsImageBackup



REM +--------------------------------------------------------------------+
REM | 世代管理
REM +--------------------------------------------------------------------+

REM +-- バックアップ先ドライブに合わせ、世代管理処理を実行する
if %drive% == local (
  REM +-- バックアップイメージを移動する --+
  move %BK_DATA_before% %BK_DATA_after%
  REM +-- 不要イメージの削除 --+
  for /f "skip=%count%" %%a in ('dir "%backupdir%" /B /O-N') do (
    rmdir /S /Q %backupdir%\%%a
  )
) else if %drive% == network (
  REM +-- ドライブ移動 --+
  %dirlabel%:
  REM +-- バックアップイメージを移動する --+
  move %BK_DATA_before% %BK_DATA_before%_%YYYY%%MM%%dd%
  REM +-- 不要イメージの削除 --+
  for /f "skip=%count%" %%a in ('dir "%BK_PATH%" /B /O-N') do (
    rmdir /S /Q %BK_PATH%\%%a
  )
  REM +-- ドライブ移動 --+
  cd /d %cur%
  REM +-- NWドライブを切断 --+
  net use %dirlabel%: /delete > nul
)



REM +--------------------------------------------------------------------+
REM | 実行後処理
REM +--------------------------------------------------------------------+

REM +-- ログ見出し（終了時刻）出力 --+
set time_tmp=%time: =0%
set end=%date:/=%%time_tmp:~0,2%%time_tmp:~3,2%%time_tmp:~6,2%
Echo **************  Windows10_SystemBackup.bat %end% End  ************** >> %LOG_FILE%

Pause