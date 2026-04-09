# ==============================================================================
# Teams-Presence-Manager : Teamsのステータス維持ユーティリティ（ランチャー）
# ==============================================================================

$configPath = Join-Path $env:USERPROFILE ".teams-config.json"

# 💡 1. 必須ファイル(JSON)の存在チェックとフェイルファスト（自爆ポップアップ）
if (-not (Test-Path $configPath)) {
    Add-Type -AssemblyName System.Windows.Forms
    $errorMessage = "必須の設定ファイル (.teams-config.json) が見つかりません。`n安全のため通信を行わず、システムを即時終了します。`n`n確認パス: $configPath"
    $errorTitle   = "Soliton-AutoPilot - 起動エラー"
    
    [System.Windows.Forms.MessageBox]::Show(
        $errorMessage, 
        $errorTitle, 
        [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    
    # PowerShellのプロセスをここで強制終了（後続のPAT読み込みや通信は一切行わない）
    exit
}

# ==============================================================================
# 2. メイン処理（JSON読み込み ＆ 本体スクリプト群のダウンロード）
# ==============================================================================
try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    if ($config.GitHubPAT -and $config.MainScriptUrl) {
        
        $headers = @{
            Authorization = "Bearer $($config.GitHubPAT)"
            Accept        = "application/vnd.github.v3.raw"
        }

        $workDir = Join-Path $env:TEMP "TeamsPresenceWork"
        
        if (Test-Path $workDir) {
            Remove-Item -Path (Join-Path $workDir "*") -Force -Recurse -ErrorAction SilentlyContinue
        } else {
            New-Item -ItemType Directory -Path $workDir | Out-Null
        }

        $baseUrl = $config.MainScriptUrl.Substring(0, $config.MainScriptUrl.LastIndexOf('/'))

        $downloadList = @(
            @{ Remote="Main-Controller.ps1"; Local="Main-Controller.ps1" },
            @{ Remote="Modules/Logger-Provider.ps1"; Local="Logger-Provider.ps1" },
            @{ Remote="Modules/Login-Handler.ps1"; Local="Login-Handler.ps1" },
            @{ Remote="Modules/KeepAlive-Engine.ps1"; Local="KeepAlive-Engine.ps1" }
        )

        foreach ($item in $downloadList) {
            $fileUrl = "$baseUrl/$($item.Remote)"
            $savePath = Join-Path $workDir $item.Local
            
            # ダウンロードした中身を「BOM付きUTF-8」としてローカルに保存し直す
            $scriptText = Invoke-RestMethod -Uri $fileUrl -Headers $headers
            $scriptText | Out-File -FilePath $savePath -Encoding UTF8
        }

        $mainPath = Join-Path $workDir "Main-Controller.ps1"
        if (Test-Path $mainPath) {
            & $mainPath
        }
    }
}
catch {
    exit
}
