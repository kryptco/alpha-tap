class Kr < Formula
  desc "Krypton command-line client, daemon, and SSH integration"
  homepage "https://krypt.co"

  stable do
	  url "https://github.com/kryptco/kr.git", :tag => "2.4.3"
  end

  bottle do
    rebuild 2
    root_url "https://github.com/kryptco/bottles/raw/master"
    cellar :any_skip_relocation
    sha256 "520571681e4e43db4801d6930baa45a95a18cb8ff1edab5378dc692c3408aa0d" => :el_capitan
    sha256 "6279d4bdb59457e6db2feb89f39e8e6579c426e0f4993eaf7775e8fd7789cdd9" => :sierra
    sha256 "c8ea79ad0c69291483a27e29f8667fe62187e6b62c139a75430cfb6ad0ee9e97" => :high_sierra
  end

  head do
    url "https://github.com/kryptco/kr.git"
  end

  option "with-no-ssh-config", "DEPRECATED -- export KR_SKIP_SSH_CONFIG=1 to prevent kr from changing ~/.ssh/config"

  depends_on "rust" => :build
  depends_on "rustup" => :build
  depends_on "go" => :build
  depends_on "pkg-config" => :build
  depends_on "emscripten" => :build
  depends_on "binaryen" => :build
  depends_on "libsodium" => :build
  depends_on "rsync" => :build
  depends_on :xcode => :build if MacOS.version >= "10.12"

  def install
    ENV["GOPATH"] = buildpath
    ENV["GOOS"] = "darwin"
    ENV["GOARCH"] = MacOS.prefer_64_bit? ? "amd64" : "386"

    dir = buildpath/"src/github.com/kryptco/kr"
    dir.install buildpath.children

	system "mkdir", "-p", ENV["HOME"]

        system "emcc" # run emcc to create ~/.emscripten
	system "sed", "-i", "-e", "s/^BINARYEN_ROOT.*/BINARYEN_ROOT = \\'\\/usr\\/local\\/opt\\/binaryen\\'/", ENV["HOME"] + "/.emscripten"
	system "sed", "-i", "", "/^LLVM_ROOT/d", ENV["HOME"] + "/.emscripten"
	system "sh", "-c", "echo LLVM_ROOT = \\'/usr/local/opt/emscripten/libexec/llvm/bin\\' >> #{ENV["HOME"]}/.emscripten"
	system "sed", "-i", "-e", "s/^NODE_JS.*/NODE_JS = \\'\\/usr\\/local\\/bin\\/node\\'/", ENV["HOME"] + "/.emscripten"

	ENV["PATH"] = ENV["HOME"] + "/.cargo/bin" + ":" + ENV["PATH"]

	system "rustup-init", "-y"
	system "rustup", "target", "add", "wasm32-unknown-emscripten"

	system "cargo", "install", "--debug", "--version=0.6.10", "cargo-web"

    cd "src/github.com/kryptco/kr" do
      old_prefix = ENV["PREFIX"]
      ENV["PREFIX"] = prefix
      system "make", "install"
      ENV["PREFIX"] = old_prefix
    end
  end

  def caveats
    "kr is now installed! Run `kr pair` to pair with the Krypton app."
  end

  test do
    system "which kr && which krd"
  end
end
