# Bring Back Window
画面外にあるウィンドウをマウスカーソルのあるディスプレイに移動するPowerShellスクリプト
## Motivation
マルチディスプレイの一方のディスプレイを別な入力ソースで使用している場合、そのディスプレイに表示されているウィンドウを表示中の領域に持ってくるために作成しました
## Environment
* Windows 10
* PowerShell 5.1
## Installation
1. 任意のディレクトリに`git clone`
2. デスクトップにショートカットキーを新規作成
3. リンク先を`powershell -ExecutionPolicy RemoteSigned -Command bring_back_window.ps1へのパス`とする
4. [optional] ショートカット作成後、ショートカットキーを設定
## Usage
デスクトップのアイコンをダブルクリック、または設定したショートカットキーを押す

PowerShellウィンドウが表示され、画面外にあったウィンドウがマウスカーソルのあるディスプレイの左上に移動します
## Remarks
PowerShell 6(pwsh.exe)では現時点でWindows GUI ライブラリがサポートされていないので動きません
