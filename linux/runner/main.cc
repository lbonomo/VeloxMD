#include "my_application.h"
#include <webview_cef/webview_cef_plugin.h>

#include <unistd.h>

#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

int main(int argc, char** argv) {
  // Give every browser process its own CEF profile. Without this all
  // instances share the default profile, so a second instance hits the
  // profile singleton lock and CEF opens a Chromium window instead of
  // rendering offscreen. CEF child processes (--type=...) inherit the switch.
  std::vector<char*> args(argv, argv + argc);
  std::string profile_arg;
  std::string profile_dir;
  bool has_user_data_dir = false;
  bool is_child = false;
  for (int i = 1; i < argc; i++) {
    if (strncmp(argv[i], "--type=", 7) == 0) is_child = true;
    if (strncmp(argv[i], "--user-data-dir=", 16) == 0) has_user_data_dir = true;
  }
  if (!is_child && !has_user_data_dir) {
    profile_dir = std::string(g_get_tmp_dir()) + "/veloxmd-cef-" +
                  std::to_string(getpid());
    profile_arg = "--user-data-dir=" + profile_dir;
    args.push_back(const_cast<char*>(profile_arg.c_str()));
  }
  args.push_back(nullptr);
  int new_argc = static_cast<int>(args.size()) - 1;

  int exit_code = initCEFProcesses(new_argc, args.data());
  if (exit_code >= 0) {
    return exit_code;
  }
  int result;
  {
  int exit_code = initCEFProcesses(argc, argv);
  if (exit_code >= 0) {
    return exit_code;
  }
    g_autoptr(MyApplication) app = my_application_new();
    result = g_application_run(G_APPLICATION(app), new_argc, args.data());
  }
  if (!profile_dir.empty()) {
    std::string cmd = "rm -rf '" + profile_dir + "'";
    if (system(cmd.c_str()) != 0) {
      // Best-effort cleanup only.
    }
  }
  return result;
}
