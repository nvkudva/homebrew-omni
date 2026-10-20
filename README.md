# homebrew-omni

Homebrew tap for [omni](https://github.com/nvkudva/omni-api): every local model your app needs, behind one port.

```sh
brew tap nvkudva/omni
brew install omni
```

Requires macOS on Apple Silicon (MLX has no Linux or Intel-Mac build).

Then:

```sh
omni init     # install Ollama if missing, pull the chat, decide and embed models
omni up       # gateway and workers in the background
omni status
```

The stt, tts, image and video models download on first use.

## What the formula does

It unpacks the release tarball, creates a virtualenv in the Cellar with `python@3.12`, and runs `uv pip install` against that source tree. uv is what applies `[tool.uv.sources]` from the project, which pins the git revisions of `diffusers` and the ltx packages plus the spaCy wheel URL. Those are not installable from PyPI, so a plain `resource`-stanza formula cannot express this package yet.

`omni init` is not run at install time — it pulls several GB of models.

## Updating for a new release

`script/release --push` in the omni-api checkout writes the new `url` and `sha256` here when this tap is at `../homebrew-omni`, then commits. Otherwise it prints the two lines to paste.

Manual path:

```sh
tag=v0.2.0
url="https://github.com/nvkudva/omni-api/archive/refs/tags/$tag.tar.gz"
sha=$(curl -fsSL "$url" | shasum -a 256 | cut -d' ' -f1)
```

Put both into `Formula/omni.rb`, then:

```sh
brew audit --strict --formula Formula/omni.rb
brew reinstall --build-from-source omni && brew test omni
```
