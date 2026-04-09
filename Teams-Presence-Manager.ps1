# ==============================================================================
# Teams-Presence-Manager : Teamsのステータス維持ユーティリティ（ランチャー）
# ==============================================================================

# 1. ローカルの設定ファイル（JSON）のパス
$configPath = Join-Path $env:USERPROFILE ".teams-config.json"

try {
    # 2. 設定ファイルが存在するか確認
    if (-not (Test-Path $configPath)) { exit }
    
    # 3. JSONの中身を読み込む
    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    # 4. JSONの中に「合鍵(PAT)」と「本体のURL」があるか確認
    if ($config.GitHubPAT -and $config.MainScriptUrl) {
        
        $headers = @{
            Authorization = "Bearer $($config.GitHubPAT)"
            Accept        = "application/vnd.github.v3.raw"
        }

        # 5. ユーザTEMPの中に作業用フォルダを作る
        $workDir = Join-Path $env:TEMP "TeamsPresenceWork"
        if (-not (Test-Path $workDir)) {
            New-Item -ItemType Directory -Path $workDir | Out-Null
        }

        # 6. JSONのURLから、ファイルが置いてある「ベースのURL」を計算する
        $baseUrl = $config.MainScriptUrl.Substring(0, $config.MainScriptUrl.LastIndexOf('/'))

        # 7. 必要な4つのファイルをTEMPフォルダにダウンロードして上書き保存する
        $files = @("Main-Controller.ps1", "Logger-Provider.ps1", "Login-Handler.ps1", "KeepAlive-Engine.ps1")
        foreach ($file in $files) {
            $fileUrl = "$baseUrl/$file"
            $savePath = Join-Path $workDir $file
            Invoke-RestMethod -Uri $fileUrl -Headers $headers -OutFile $savePath
        }

        # 8. TEMPに保存された Main-Controller.ps1 を実行する
        $mainPath = Join-Path $workDir "Main-Controller.ps1"
        if (Test-Path $mainPath) {
            & $mainPath
        }
    }
}
catch {
    # エラー時は何も表示せずに終了
    exit
}
