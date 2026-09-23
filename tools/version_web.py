"""Give Godot Web assets a release-specific URL so browsers fetch new builds."""
from pathlib import Path
import argparse
import re

parser = argparse.ArgumentParser()
parser.add_argument('--directory', type=Path, default=Path('web'))
parser.add_argument('--version', required=True)
args = parser.parse_args()

if not re.fullmatch(r'[0-9a-fA-F]{7,40}', args.version):
    parser.error('version must be a Git commit SHA')

prefix = 'game-' + args.version[:12].lower()
html_path = args.directory / 'index.html'
html = html_path.read_text(encoding='utf-8')
if '"executable":"index"' not in html:
    raise RuntimeError('Godot index.html format changed; check executable name')

assets = [p for p in args.directory.glob('index.*')
          if p.name != 'index.html' and not p.name.endswith('.import')]
if not any(p.name == 'index.pck' for p in assets) or not any(p.name == 'index.wasm' for p in assets):
    raise RuntimeError('Web export is missing index.pck or index.wasm')

for asset in assets:
    asset.rename(asset.with_name(asset.name.replace('index.', prefix + '.', 1)))

html = html.replace('index.', prefix + '.')
html = html.replace('"executable":"index"', f'"executable":"{prefix}"')
html_path.write_text(html, encoding='utf-8')
print(f'Versioned {len(assets)} assets as {prefix}.*')
