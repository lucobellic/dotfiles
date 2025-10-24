{ pkgs, ... }:

{
  programs = {
    git = {
      enable = true;
      settings = {
        rebase = { autoStash = true; };
        rerere = { enabled = true; };
        pull = { rebase = true; };
        push = { autoSetupRemote = true; };
      };
    };

    delta = {
      enable = true;
      options = {
        features = "ayu-gloom";
        ayu-gloom = {
          dark = true;
          commit-style = "normal";
          commit-decoration-style = "ul";
          file-decoration-style = "box blue";
          file-style = "blue";
          file-modified-label = "";
          hunk-header-style = "omit";
          line-numbers = true;
          line-numbers-left-style = "#4D5566";
          line-numbers-minus-style = "red";
          line-numbers-plus-style = "green";
          line-numbers-right-style = "#4D5566";
          line-numbers-zero-style = "#4D5566";
          minus-emph-style = "black red";
          minus-style = "red";
          plus-emph-style = "black green";
          plus-style = "green";
          zero-style = "#4D5566";
          syntax-theme = "none";
          merge-conflict-begin-symbol = "-";
          merge-conflict-end-symbol = "─";
          merge-conflict-ours-diff-header-style = "purple";
          merge-conflict-ours-diff-header-decoration-style = "ul";
          merge-conflict-theirs-diff-header-style = "purple";
          merge-conflict-theirs-diff-header-decoration-style = "ul ol";
        };
        interactive = { keep-plus-minus-markers = false; };
      };
    };

    lazygit = {
      enable = true;
      settings = {
        git = {
          allBranchesLogCmds = [
            "git"
            "log"
            "--graph"
            "--all"
            "--color=always"
            "--abbrev-commit"
            "--decorate"
            "--date=relative"
            "--pretty=medium"
          ];
          autoForwardBranches = "none";
          autoFetch = true;
          disableForcePushing = true;
          log = {
            order =
              "topo-order"; # one of 'topo-order' | 'date-order' | 'author-date-order'
            showGraph = "always"; # one of 'never' | 'always' | ...
            showWholeGraph = false;
          };
          paging = {
            colorArg = "always";
            pager = "delta --hyperlinks --dark --paging=never";
          };
          overrideGpg = true;
        };
        gui = {
          skipUpdateNotification = true;
          border = "single"; # one of 'single' | 'double' | 'rounded
          commandLogSize = 8;
          commitLength = { show = true; };
          enlargedSideViewLocation = "top";
          expandFocusedSidePanel = false;
          language =
            "auto"; # one of 'auto' | 'en' | 'zh' | 'pl' | 'nl' | 'ja' | 'ko'
          localBranchSortOrder = "recency";
          mainPanelSplitMode =
            "flexible"; # one of 'horizontal' | 'flexible' | 'vertical'
          mouseEvents = true;
          nerdFontsVersion =
            "3"; # nerd fonts version to use ("2" or "3"); empty means don't show nerd font icons
          remoteBranchSortOrder = "recency";
          scrollHeight = 2; # how many lines you scroll by
          scrollPastBottom =
            true; # enable scrolling past the bottom  showBottomLine= true # for hiding the bottom information line (unless it has important information to tell you)  showCommandLog= false
          showFileTree = true; # for rendering changes files in a tree format
          showIcons = true;
          showListFooter =
            true; # for seeing the '5 of 20' message in list panels
          showRandomTip = true;
          sidePanelWidth = 0.3333; # number from 0 to 1
          skipRewordInEditorWarning =
            false; # for skipping the confirmation before
          skipStashWarning = false;
          splitDiff = "auto"; # one of 'auto' | 'always'
          theme = {
            inactiveBorderColor = [ "#1B2733" ];
            selectedLineBgColor = [ "#1b3a5a" "bold" ];
            timeFormat =
              ''"02 Jan 06 15=04 MST"''; # https=//pkg.go.dev/time#Time.Format
            windowSize =
              "normal"; # one of 'normal' | 'half' | 'full' default is 'normal'
          };
          useHunkModeInStagingView = true;
        };
        os = { editPreset = "nvim-remote"; };
        promptToReturnFromSubprocess =
          false; # display confirmation when subprocess terminates
        services = {
          "\"gitlab.easymile.com\"" = "gitlab=gitlab.easymile.com";
        };
        customCommands = [
          {
            key = "<c-j>";
            context = "localBranches";
            description = "Open Jira ticket";
            command = ''
              echo https=//easymile.atlassian.net/browse/{{.SelectedLocalBranch.Name}} | grep -o ".*/[A-Z]{2}-[0-9]*" | xargs xdg-open'';
          }
          {
            key = "G";
            command = "glab mr view -w {{.SelectedLocalBranch.UpstreamBranch}}";
            context = "localBranches";
            description = "Go to MR in gitlab";
            output = "log";
          }
          {
            key = "<c-n>";
            description = "Create worktree";
            context = "localBranches";
            command =
              "git worktree add ../rapidash-worktrees/{{.SelectedLocalBranch.Name}}/rapidash origin/{{.SelectedLocalBranch.Name}}";
          }
          {
            key = "<c-n>";
            description = "Create worktree";
            context = "remoteBranches";
            command =
              "git worktree add ../rapidash-worktrees/{{.SelectedRemoteBranch.Name}}/rapidash origin/{{.SelectedRemoteBranch.Name}}";
          }
          # Merge conflicts
          {
            key = "<c-o>";
            context = "mergeConflicts";
            command = "git restore --ours {{.SelectedFile.Name | quote}}";
            output = "terminal";
          }
          {
            key = "<c-t>";
            context = "mergeConflicts";
            command = "git restore --theirs {{.SelectedFile.Name | quote}}";
            output = "terminal";
          }
        ];
      };
    };
  };
}
