class Omni < Formula
  desc "One local gateway for chat, decide, embeddings, speech and video"
  homepage "https://github.com/nvkudva/omni-api"
  url "https://github.com/nvkudva/omni-api/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "3eb829b3c494f4924e3aa7fbbf21bce6cdfbd73ae25da48d3c11dedc963817a9"
  license "MIT"
  head "https://github.com/nvkudva/omni-api.git", branch: "main"

  # MLX ships arm64-only wheels, so the media roles need Apple Silicon.
  depends_on :macos
  depends_on arch: :arm64
  depends_on "python@3.12"
  depends_on "uv"

  def install
    venv = virtualenv_create(libexec, "python3.12")
    # uv reads the project's [tool.uv.sources]: the git-pinned diffusers and ltx
    # packages and the spaCy wheel URL live there, not on PyPI.
    system "uv", "pip", "install", "--python", venv.root/"bin"/"python",
                  "--no-cache", "--quiet", buildpath
    bin.install_symlink libexec/"bin"/"omni"
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
