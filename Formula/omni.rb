class Omni < Formula
  desc "One local gateway for chat, decide, embeddings, speech and video"
  homepage "https://github.com/nvkudva/omni-api"
  url "https://github.com/nvkudva/omni-api/archive/refs/tags/v0.8.4.tar.gz"
  sha256 "0bc9f40688cdb4b663e16740cbd949e4e4af2577770648ba2beaa597510a7e5c"
  license "MIT"
  head "https://github.com/nvkudva/omni-api.git", branch: "main"

  # torch ships arm64-only Metal wheels, so the media roles need Apple Silicon.
  depends_on arch: :arm64
  depends_on :macos
  depends_on "python@3.12"
  depends_on "uv"
  # Rust wheels inside the venv carry @rpath dylib IDs without header padding;
  # Homebrew's relocation would try to rewrite them and fail mid-keg.
  preserve_rpath

  def install
    python = formula_opt_bin("python@3.12")/"python3.12"
    venv = libexec/"venv"
    system python, "-m", "venv", venv
    install_packages(venv)
    bin.install_symlink venv/"bin"/"omni"
  end

  # uv reads the project's [tool.uv.sources]: the git-pinned diffusers and the
  # spaCy wheel URL live there, not on PyPI.
  #
  # `system` hides a command's output in a log file, so a multi-GB install looks
  # frozen. Run uv ourselves and relay its step lines to the terminal instead.
  def install_packages(venv)
    # Wheels are cached under Homebrew's own cache dir (writable inside the build
    # sandbox), so a reinstall or upgrade skips the multi-GB download. On APFS uv
    # clones files out of the cache (copy-on-write), so Homebrew's relocation can
    # never edit a cached file in place.
    ENV["UV_CACHE_DIR"] = (HOMEBREW_CACHE/"uv").to_s
    # torch wheels are large; uv's 30s default read timeout fails on slow links.
    ENV["UV_HTTP_TIMEOUT"] = "120"

    ohai "Installing the media stack (torch, diffusers, ONNX Runtime, spaCy)"
    puts "  First install downloads several GB and takes a few minutes; reinstalls reuse #{ENV["UV_CACHE_DIR"]}."

    command = ["uv", "pip", "install", "--python", (venv/"bin"/"python").to_s, "#{buildpath}[media]"]
    output = []
    IO.popen([*command, { err: [:child, :out] }]) do |uv|
      uv.each_line do |line|
        output << line
        puts "  #{line}" unless line.start_with?(" + ")
      end
    end
    return if Process.last_status.success?

    odie "uv pip install failed:\n#{output.last(20).join}"
  end

  def caveats
    <<~EOS
      The omni command is installed. Models are not downloaded by Homebrew; run this once:
        omni init     # installs Ollama if missing, then downloads chat, decide, embed,
                      # speech-to-text and text-to-speech (several GB) and starts omni
      Image and video models are tens of GB: they download on first use, or `omni init --media`.
      Later: omni up / omni down / omni status, then open http://127.0.0.1:10000/
    EOS
  end

  test do
    assert_match "omni #{version}", shell_output("#{bin}/omni --version")
    assert_match "init", shell_output("#{bin}/omni --help")
  end
end
