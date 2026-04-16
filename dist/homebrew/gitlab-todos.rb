cask "gitlab-todos" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/vapor-pawelw/gitlab-todos/releases/download/v#{version}/GitLabTodos.dmg"
  name "GitLab To-Dos"
  desc "Menu-bar app that surfaces your GitLab to-do inbox via the glab CLI"
  homepage "https://github.com/vapor-pawelw/gitlab-todos"

  depends_on formula: "glab"
  depends_on macos: ">= :sonoma"

  app "GitLabTodos.app"

  preflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{staged_path}/GitLabTodos.app"]
  end

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/GitLabTodos.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Caches/com.vaporpw.GitLabTodos",
    "~/Library/Preferences/com.vaporpw.GitLabTodos.plist",
  ]
end
