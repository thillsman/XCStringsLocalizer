class XcstringsLocalizer < Formula
  desc "AI-powered localization tool for Xcode .xcstrings files"
  homepage "https://github.com/thillsman/XCStringsLocalizer"
  url "https://github.com/thillsman/XCStringsLocalizer/archive/refs/tags/v0.5.3.tar.gz"
  sha256 "cde446bb2bec3e2b7d29b00de9f769a7a0343392e9be23525c5b8a43660cfb8d"
  license "MIT"
  head "https://github.com/thillsman/XCStringsLocalizer.git", branch: "main"

  depends_on xcode: ["14.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/xcstrings-localizer"
  end

  test do
    assert_match "0.5.3", shell_output("#{bin}/xcstrings-localizer --version")
  end
end
