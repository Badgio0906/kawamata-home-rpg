# 河俣さんのおうち帰れるかな

Godot 4.7.2 と GDScript で制作した短編コメディ RPG。職場から自宅まで、食べ物の誘惑と向き合いながら帰ります。

## Play

GitHub Pages: https://badgio0906.github.io/kawamata-home-rpg/

## Controls

PC: 矢印キーまたは WASD で移動。戦闘中は `1` 戦う、`2` 食べる、`3` 誰かを呼ぶ。画面上のボタンはマウスでも操作できます。

Mobile: 画面左下の方向ボタンと戦闘コマンドをタップ。横向き推奨。

道中には一度だけ休めるベンチが3か所あります。食べるとHPとやる気が回復し、戦って勝つと経験値を得られます。レベルを上げると、一部のベンチでやる気も回復します。

## Development

- Godot 4.7.2 stable / Compatibility renderer / single-threaded Web export
- GDScript
- `tools/generate_assets.py` でオリジナルのドット絵と音声を生成（実行時に Python は不要）
- 日本語フォント: Noto Sans JP (SIL Open Font License、`assets/fonts/OFL.txt`)

Godot エディターで `project.godot` を開いて実行できます。Web 書き出しは `export_presets.cfg` の Web preset を使用します。
