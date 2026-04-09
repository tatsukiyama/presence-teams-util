# ==============================================================================
# Teams-Presence-Manager : Teamsのステータス維持ユーティリティ（ランチャー）
# ==============================================================================

# 1. ローカルの設定ファイル（JSON）のパス
$configPath = Join-Path $env:USERPROFILE ".teams-config.json"

try {
    # 2. 設定ファイルが存在するか確認（なければ何もせず終了）
    if (-not (Test-Path $configPath)) {
        exit
    }

    # 3. JSONの中身を読み込む
    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    # 4. JSONの中に「合鍵(PAT)」と「本体のURL」があれば処理を進める
    if ($config.GitHubPAT -and $config.MainScriptUrl) {
        
        # 5. 合鍵を使って通信の準備をする
        $headers = @{
            Authorization = "Bearer $($config.GitHubPAT)"
            Accept        = "application/vnd.github.v3.raw"
        }

        # 6. プライベートリポジトリから本体コードをメモリ上にダウンロードして実行
        $script = Invoke-RestMethod -Uri $config.MainScriptUrl -Headers $headers -ErrorAction Stop
        Invoke-Expression $script
    }
}
catch {
    # 万が一エラーが起きても、黒い画面に何も表示させずに静かに終了する
    exit
}
