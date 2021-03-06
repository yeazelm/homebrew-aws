#   Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.

# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Ec2MacosInit < Formula
  desc "EC2 macOS Init"
  homepage "https://github.com/aws/ec2-macos-init"
  url "https://aws-homebrew.s3-us-west-2.amazonaws.com/ec2-macos-init-1.4.0.tar.gz"
  sha256 "e7f807382bfd73d4a0fd4af7f428cca183615eee7191fea6ec68352c31a151f8"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["CGO_ENABLED"] = "0"

    # Turn off module style for go 1.16 until we get module support enabled
    system "go", "env", "-w", "GO111MODULE=off"

    # Install dependencies
    system "go", "get", "github.com/BurntSushi/toml"
    system "go", "get", "github.com/google/go-cmp/cmp"
    system "go", "get", "github.com/digineo/go-ping"

    commit_date = File.read("configuration/commitdate.txt").strip

    # Go build
    mkdir_p buildpath/"src/github.com/aws/"
    ln_s buildpath, buildpath/"src/github.com/aws/ec2-macos-init"

    system "go",
           "build",
           "-o",
           "ec2-macos-init",
           "-trimpath",
           "-ldflags",
           "-s -w -X 'main.CommitDate=#{commit_date}' -X 'main.Version=#{version}'"
    bin.install "ec2-macos-init"
    libexec.install "configuration/init.toml" => "init.toml"
    libexec.install "Library/LaunchDaemons/com.amazon.ec2.macos-init.plist"
  end

  def caveats
    <<~EOS
      #{name} must be configured to start on boot. 

        To enable #{name} for running at boot:

          sudo cp #{libexec}/com.amazon.ec2.macos-init.plist /Library/LaunchDaemons/com.amazon.ec2.macos-init.plist
          sudo launchctl load /Library/LaunchDaemons/com.amazon.ec2.macos-init.plist

        To disable running #{name} on boot (not recommended):

          sudo launchctl unload /Library/LaunchDaemons/com.amazon.ec2.macos-init.plist
          sudo rm -f /Library/LaunchDaemons/com.amazon.ec2.macos-init.plist

        Note that the init.toml may need to be updated, to take the package's default, run:

          sudo cp #{libexec}/init.toml /usr/local/aws/ec2-macos-init/init.toml

    EOS
  end

  test do
    system "false"
  end
end
