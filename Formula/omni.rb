class Omni < Formula
  desc "One local gateway for chat, decide, embeddings, speech and video"
  homepage "https://github.com/nvkudva/omni-api"
  url "https://github.com/nvkudva/omni-api/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "2dc61d9722374714cb94abf144c73d44f6792187b7682bd1939b9a83fa72b1a7"
  license "MIT"
  head "https://github.com/nvkudva/omni-api.git", branch: "main"

  # MLX ships arm64-only wheels, so the media roles need Apple Silicon.
  depends_on :macos
  depends_on arch: :arm64
  depends_on "python@3.12"
  depends_on "uv"
  # Rust wheels inside the venv carry @rpath dylib IDs without header padding;
  # Homebrew's relocation would try to rewrite them and fail mid-keg.
  preserve_rpath

  def install
    python = Formula["python@3.12"].opt_bin/"python3.12"
    venv = libexec/"venv"
    system python, "-m", "venv", venv
    # uv reads the project's [tool.uv.sources]: the git-pinned diffusers and ltx
    # packages and the spaCy wheel URL live there, not on PyPI.
    system "uv", "pip", "install", "--python", venv/"bin"/"python",
                  "--no-cache", "--quiet", "#{buildpath}[media]"
    bin.install_symlink venv/"bin"/"omni"
  end

  def caveats
    <<~EOS
      Models are not downloaded at install time:
        omni init     # install Ollama and pull the chat, decide and embed models
        omni up       # start the gateway on http://127.0.0.1:10000/
    EOS
  end

  test do
    assert_match "omni #{version}", shell_output("#{bin}/omni --version")
    assert_match "init", shell_output("#{bin}/omni --help")
  end
end
