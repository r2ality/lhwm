// LHWM — Lightweight HolyWM
// A compact X11 window manager written in HolyC for holyc-lang.
// The implementation intentionally keeps policy and configuration small.
#include "x11.HH"

#define MAX_CLIENTS 128
#define MAX_BINDS 64
#define WORKSPACE_COUNT 9
#define MODE_TILING 0
#define MODE_FLOATING 1
#define LAYOUT_MASTER 0
#define LAYOUT_COLUMNS 1
#define LAYOUT_MONOCLE 2
#define MAX_RULES 32
#define RULE_FLOAT 1
#define RULE_TILE 2
#define RULE_WORKSPACE 3

class Client
{
  U64 win;
  I32 x;
  I32 y;
  I32 w;
  I32 h;
  I32 workspace;
  I32 mapped;
  I32 ignore_unmap;
  I32 floating;
  I32 pad;
};
class Binding
{
  U32 keycode;
  U32 mods;
  U8 combo[48];
  U8 action[32];
  U8 command[256];
};
class WinRule
{
  U8 name[64];
  I32 action;
  I32 arg;
};

U8 *dpy;
U64 root;
I32 screen_no;
I32 screen_w;
I32 screen_h;
U64 wm_protocols;
U64 wm_delete_window;
U64 net_active_window;
U64 net_supporting_wm_check;
U64 net_wm_name;
U64 utf8_string;
U64 support_window;
U64 net_wm_window_type;
U64 wtype_dialog;
U64 wtype_utility;
U64 wtype_splash;
U64 wtype_toolbar;
U64 cmap;
U64 focus_pixel;
U64 normal_pixel;
U64 bar_window;
U64 bar_gc;
U64 bar_font;
U64 bar_bg_pixel;
U64 bar_fg_pixel;
U64 bar_accent_pixel;
U64 bar_border_pixel;
U64 workspace_border_pixel;
U64 workspace_active_border_pixel;
U64 workspace_active_bg_pixel;
U64 workspace_fg_pixel;
U64 workspace_active_fg_pixel;
I64 other_wm;
I64 running;
I64 mode;
I64 layout;
I64 gap;
I64 border_width;
I64 bar_enabled;
I64 bar_height;
I64 bar_font_warned;
I64 clock_enabled;
I64 clock_update_interval;
I64 next_clock_tick;
I64 bar_border_width;
I64 master_ratio;
I64 nclients;
I64 selected;
I64 current_workspace;
I64 nbinds;
I64 nrules;
I64 focus_follows;
I64 drag_mode;
I64 drag_client;
I32 drag_start_x;
I32 drag_start_y;
I32 drag_orig_x;
I32 drag_orig_y;
I32 drag_orig_w;
I32 drag_orig_h;
U8 focus_color[64];
U8 normal_color[64];
U8 bar_bg[64];
U8 bar_fg[64];
U8 bar_accent[64];
U8 bar_border_color[64];
U8 workspace_border_color[64];
U8 workspace_active_border[64];
U8 workspace_active_bg[64];
U8 workspace_fg[64];
U8 workspace_active_fg[64];
U8 bar_font_name[96];
U8 clock_format[128];
U8 clock_text[128];
Client clients[MAX_CLIENTS];
Binding binds[MAX_BINDS];
WinRule rules[MAX_RULES];
U8 cfg_line[700];

I32 xerror(U8 *display, XErrorEvent *event);
U0 defaults();
U0 load_config();
U0 arrange();
U0 grab_keys();
U0 manage(U64 win);
U0 unmanage(U64 win);
I64 client_index(U64 win);
U0 focus_client(I64 index);
U0 focus_client_ex(I64 index, I64 raise);
U0 set_mode(I64 next_mode);
U0 close_focused();
U0 run_command(U8 *command);
U0 run_action(Binding *binding);
U0 add_binding(U8 *combo, U8 *action, U8 *command);
U0 load_color_pixels();
U0 configure_bar();
U0 draw_bar();
I64 update_bar_clock();
I64 text_equal(U8 *a, U8 *b);
I64 workspace_start_x();
U0 set_workspace(I64 workspace);
U0 move_focused_to_workspace(I64 workspace);
I64 visible_count();
I64 visible_client_at(I64 position);
I64 workspace_hitbox(I32 x, I32 y);
U0 load_bar_font();
I64 bar_font_available(U8 *name);
I64 bar_offset();

public I32 xerror(U8 *display, XErrorEvent *event)
{
  if (event && event->error_code == BadAccess) other_wm = 1;
  return 0;
}

U8 *trim(U8 *s)
{
  I64 n;
  while (*s == ' ' || *s == '\t') s++;
  n = StrLen(s);
  while (n > 0 && (s[n - 1] == '\n' || s[n - 1] == '\r' ||
      s[n - 1] == ' ' || s[n - 1] == '\t')) {
    s[n - 1] = 0;
    n--;
  }
  return s;
}

U0 copystr(U8 *dst, I64 size, U8 *src)
{
  I64 i = 0;
  if (!size) return;
  if (!src) src = "";
  while (src[i] && i < size - 1) {
    dst[i] = src[i];
    i++;
  }
  dst[i] = 0;
}

I64 wordcopy(U8 *src, U8 *dst, I64 size)
{
  I64 i = 0;
  src = trim(src);
  while (src[i] && src[i] != ' ' && src[i] != '\t' && i < size - 1) {
    dst[i] = src[i];
    i++;
  }
  dst[i] = 0;
  return i;
}

I64 to_int(U8 *s)
{
  I64 v = 0;
  I64 sign = 1;
  s = trim(s);
  if (*s == '-') { sign = -1; s++; }
  while (*s >= '0' && *s <= '9') {
    v = (v * 10) + (*s - '0');
    s++;
  }
  return v * sign;
}

I64 parse_bool(U8 *value, I64 fallback)
{
  if (!strcasecmp(value, "true") || !strcasecmp(value, "yes") || !strcasecmp(value, "on") || !strcasecmp(value, "1")) return 1;
  if (!strcasecmp(value, "false") || !strcasecmp(value, "no") || !strcasecmp(value, "off") || !strcasecmp(value, "0")) return 0;
  return fallback;
}

U0 defaults()
{
  gap = 8;
  border_width = 2;
  master_ratio = 60;
  bar_enabled = 1;
  bar_height = 28;
  clock_enabled = 1;
  clock_update_interval = 1;
  bar_border_width = 1;
  layout = LAYOUT_MASTER;
  copystr(focus_color, 64, "#89b4fa");
  copystr(normal_color, 64, "#45475a");
  copystr(bar_bg, 64, "#1e1e2e");
  copystr(bar_fg, 64, "#cdd6f4");
  copystr(bar_accent, 64, "#d8ad4a");
  copystr(bar_border_color, 64, "#45475a");
  copystr(workspace_border_color, 64, "#45475a");
  copystr(workspace_active_border, 64, "#d8ad4a");
  copystr(workspace_active_bg, 64, "#3b3528");
  copystr(workspace_fg, 64, "#a6adc8");
  copystr(workspace_active_fg, 64, "#ffffff");
  copystr(bar_font_name, 96, "fixed");
  copystr(clock_format, 128, "%a %d %b  %H:%M");
  copystr(clock_text, 128, "--- -- ---  --:--");
  focus_follows = 1;
  current_workspace = 1;
  nbinds = 0;
  nrules = 0;
  add_binding("Mod4+Return", "spawn", "alacritty");
  add_binding("Mod4+q", "kill", "");
  add_binding("Mod4+d", "spawn", "dmenu_run");
  add_binding("Mod4+Shift+q", "quit", "");
  add_binding("Mod4+r", "reload", "");
  add_binding("Mod4+m", "mode", "");
  add_binding("Mod4+j", "focus_next", "");
  add_binding("Mod4+k", "focus_prev", "");
  add_binding("Mod4+Tab", "layout_next", "");
  add_binding("Mod4+1", "workspace", "1");
  add_binding("Mod4+2", "workspace", "2");
  add_binding("Mod4+3", "workspace", "3");
  add_binding("Mod4+4", "workspace", "4");
  add_binding("Mod4+5", "workspace", "5");
  add_binding("Mod4+6", "workspace", "6");
  add_binding("Mod4+7", "workspace", "7");
  add_binding("Mod4+8", "workspace", "8");
  add_binding("Mod4+9", "workspace", "9");
  add_binding("Mod4+Shift+1", "move_workspace", "1");
  add_binding("Mod4+Shift+2", "move_workspace", "2");
  add_binding("Mod4+Shift+3", "move_workspace", "3");
  add_binding("Mod4+Shift+4", "move_workspace", "4");
  add_binding("Mod4+Shift+5", "move_workspace", "5");
  add_binding("Mod4+Shift+6", "move_workspace", "6");
  add_binding("Mod4+Shift+7", "move_workspace", "7");
  add_binding("Mod4+Shift+8", "move_workspace", "8");
  add_binding("Mod4+Shift+9", "move_workspace", "9");
}

U0 add_binding(U8 *combo, U8 *action, U8 *command)
{
  U8 work[96];
  U8 part[48];
  U8 *p;
  U8 *plus;
  U64 sym = 0;
  U32 mods = 0;
  I64 i;
  I64 keycode;
  Binding *b;
  copystr(work, 96, combo);
  p = work;
  while (*p) {
    plus = strchr(p, '+');
    if (plus) *plus = 0;
    copystr(part, 48, trim(p));
    if (!strcasecmp(part, "Mod4") || !strcasecmp(part, "Super")) mods |= Mod4Mask;
    else if (!strcasecmp(part, "Shift")) mods |= ShiftMask;
    else if (!strcasecmp(part, "Control") || !strcasecmp(part, "Ctrl")) mods |= ControlMask;
    else if (!strcasecmp(part, "Alt") || !strcasecmp(part, "Mod1")) mods |= Mod1Mask;
    else sym = XStringToKeysym(part);
    if (!plus) break;
    p = plus + 1;
  }
  if (!sym) return;
  keycode = XKeysymToKeycode(dpy, sym);
  if (!keycode) return;
  for (i = 0; i < nbinds; i++) {
    if (binds[i].keycode == keycode && binds[i].mods == mods) {
      b = &binds[i];
      copystr(b->combo, 48, combo);
      copystr(b->action, 32, action);
      copystr(b->command, 256, command);
      return;
    }
  }
  if (nbinds >= MAX_BINDS) return;
  b = &binds[nbinds];
  b->keycode = keycode;
  b->mods = mods;
  copystr(b->combo, 48, combo);
  copystr(b->action, 32, action);
  copystr(b->command, 256, command);
  nbinds++;
}

U0 parse_bind(U8 *line)
{
  U8 value[448];
  U8 combo[64];
  U8 action[32];
  U8 *eq = strchr(line, '=');
  U8 *p;
  I64 n;
  if (!eq) return;
  copystr(value, 448, trim(eq + 1));
  p = trim(value);
  n = wordcopy(p, combo, 64);
  p = trim(p + n);
  n = wordcopy(p, action, 32);
  p = trim(p + n);
  if (combo[0] && action[0]) add_binding(combo, action, p);
}

// Settings are matched with case, underscores and dashes ignored, so the
// config.HC spelling "BarBg" and the legacy lhwm.conf spelling "bar_bg" are
// the same key.  apply_setting returns 0 when the key is unknown.
U0 normalize_key(U8 *key, U8 *out, I64 size)
{
  I64 n = 0;
  while (*key && n < size - 1) {
    if (*key != '_' && *key != '-' && *key != ' ') {
      out[n] = *key;
      n++;
    }
    key++;
  }
  out[n] = 0;
}

I64 apply_setting(U8 *raw_key, U8 *value)
{
  U8 key[64];
  normalize_key(trim(raw_key), key, 64);
  if (!strcasecmp(key, "gap")) gap = to_int(value);
  else if (!strcasecmp(key, "borderwidth")) border_width = to_int(value);
  else if (!strcasecmp(key, "masterratio")) master_ratio = to_int(value);
  else if (!strcasecmp(key, "layout")) {
    if (!strcasecmp(value, "columns")) layout = LAYOUT_COLUMNS;
    else if (!strcasecmp(value, "monocle")) layout = LAYOUT_MONOCLE;
    else layout = LAYOUT_MASTER;
  }
  else if (!strcasecmp(key, "focusfollowsmouse")) focus_follows = parse_bool(value, focus_follows);
  else if (!strcasecmp(key, "borderfocus")) copystr(focus_color, 64, value);
  else if (!strcasecmp(key, "bordernormal")) copystr(normal_color, 64, value);
  else if (!strcasecmp(key, "barenabled")) bar_enabled = parse_bool(value, bar_enabled);
  else if (!strcasecmp(key, "barheight")) bar_height = to_int(value);
  else if (!strcasecmp(key, "clockenabled")) clock_enabled = parse_bool(value, clock_enabled);
  else if (!strcasecmp(key, "clockformat")) copystr(clock_format, 128, value);
  else if (!strcasecmp(key, "clockupdateinterval")) clock_update_interval = to_int(value);
  else if (!strcasecmp(key, "barborderwidth")) bar_border_width = to_int(value);
  else if (!strcasecmp(key, "barbg")) copystr(bar_bg, 64, value);
  else if (!strcasecmp(key, "barfg")) copystr(bar_fg, 64, value);
  else if (!strcasecmp(key, "baraccent")) copystr(bar_accent, 64, value);
  else if (!strcasecmp(key, "barbordercolor")) copystr(bar_border_color, 64, value);
  else if (!strcasecmp(key, "barfont")) copystr(bar_font_name, 96, value);
  else if (!strcasecmp(key, "workspacebordercolor")) copystr(workspace_border_color, 64, value);
  else if (!strcasecmp(key, "workspaceactiveborder")) copystr(workspace_active_border, 64, value);
  else if (!strcasecmp(key, "workspaceactivebg")) copystr(workspace_active_bg, 64, value);
  else if (!strcasecmp(key, "workspacefg")) copystr(workspace_fg, 64, value);
  else if (!strcasecmp(key, "workspaceactivefg")) copystr(workspace_active_fg, 64, value);
  else return 0;
  return 1;
}

// Legacy lhwm.conf line: key = value
U0 parse_scalar(U8 *line)
{
  U8 key[64];
  U8 value[256];
  U8 *eq = strchr(line, '=');
  I64 n;
  if (!eq) return;
  n = eq - line;
  if (n > 63) n = 63;
  MemCpy(key, line, n);
  key[n] = 0;
  copystr(value, 256, trim(eq + 1));
  apply_setting(key, value);
}

U0 add_rule(U8 *name, U8 *action, U8 *arg)
{
  WinRule *r;
  I64 code = 0;
  I64 workspace = 0;
  if (nrules >= MAX_RULES || !name || !*name) return;
  if (!strcasecmp(action, "float")) code = RULE_FLOAT;
  else if (!strcasecmp(action, "tile")) code = RULE_TILE;
  else if (!strcasecmp(action, "workspace")) {
    code = RULE_WORKSPACE;
    workspace = to_int(arg);
    if (workspace < 1 || workspace > WORKSPACE_COUNT) return;
  }
  if (!code) return;
  r = &rules[nrules];
  copystr(r->name, 64, name);
  r->action = code;
  r->arg = workspace;
  nrules++;
}

// Reads one argument of a config.HC statement: either a "quoted string" (with
// \" and \\ escapes) or a bare token.  Returns the position of the delimiter
// that ended it.
U8 *read_arg(U8 *p, U8 *out, I64 size)
{
  I64 n = 0;
  while (*p == ' ' || *p == '\t') p++;
  if (*p == '"') {
    p++;
    while (*p && *p != '"') {
      if (*p == '\\' && p[1]) p++;
      if (n < size - 1) {
        out[n] = *p;
        n++;
      }
      p++;
    }
    if (*p == '"') p++;
    out[n] = 0;
  } else {
    while (*p && *p != ',' && *p != ')' && *p != ';') {
      if (n < size - 1) {
        out[n] = *p;
        n++;
      }
      p++;
    }
    while (n > 0 && (out[n - 1] == ' ' || out[n - 1] == '\t')) n--;
    out[n] = 0;
  }
  while (*p && *p != ',' && *p != ')' && *p != ';') p++;
  return p;
}

// One config.HC statement per line:
//   Setting = value;
//   Bind("Mod4+Return", "spawn", "alacritty");
//   Rule("Thunar", "workspace", 9);
U0 parse_hc_line(U8 *line)
{
  U8 a0[256];
  U8 a1[256];
  U8 a2[256];
  U8 name[64];
  U8 *p;
  U8 *paren;
  U8 *eq;
  I64 in_quote = 0;
  I64 n;
  // Strip // comments, but never inside a quoted string.
  p = line;
  while (*p) {
    if (in_quote && *p == '\\' && p[1]) {
      p += 2;
      continue;
    }
    if (*p == '"') in_quote = !in_quote;
    else if (!in_quote && *p == '/' && p[1] == '/') {
      *p = 0;
      break;
    }
    p++;
  }
  p = trim(line);
  if (!*p) return;
  paren = strchr(p, '(');
  eq = strchr(p, '=');
  a0[0] = 0;
  a1[0] = 0;
  a2[0] = 0;
  if (paren && (!eq || paren < eq)) {
    n = paren - p;
    if (n > 63) n = 63;
    MemCpy(name, p, n);
    name[n] = 0;
    p = read_arg(paren + 1, a0, 256);
    if (*p == ',') p = read_arg(p + 1, a1, 256);
    if (*p == ',') p = read_arg(p + 1, a2, 256);
    if (!strcasecmp(trim(name), "Bind")) {
      if (a0[0] && a1[0]) add_binding(a0, a1, a2);
    } else if (!strcasecmp(trim(name), "Rule")) {
      add_rule(a0, a1, a2);
    } else {
      "lhwm: config: unknown statement %s\n", trim(name);
    }
  } else if (eq) {
    n = eq - p;
    if (n > 63) n = 63;
    MemCpy(name, p, n);
    name[n] = 0;
    read_arg(eq + 1, a0, 256);
    if (!apply_setting(name, a0)) "lhwm: config: unknown setting %s\n", trim(name);
  }
}

I64 is_hc_path(U8 *path)
{
  I64 n = StrLen(path);
  if (n < 3) return 0;
  return !strcasecmp(path + n - 3, ".HC");
}

U0 read_config_file(U8 *path)
{
  U8 *file = fopen(path, "r");
  U8 line[1024];
  U8 *p;
  I64 hc;
  if (!file) return;
  hc = is_hc_path(path);
  while (fgets(line, 1024, file)) {
    if (hc) {
      parse_hc_line(line);
      continue;
    }
    p = trim(line);
    if (!*p || *p == '#') continue;
    if (!strncasecmp(p, "bind", 4)) parse_bind(p);
    else parse_scalar(p);
  }
  fclose(file);
}

// --- Generating the default config.HC --------------------------------------

U0 cat_to(U8 *dst, I64 size, U8 *src)
{
  I64 n = StrLen(dst);
  if (n >= size - 1) return;
  copystr(dst + n, size - n, src);
}

U0 cat_escaped(U8 *dst, I64 size, U8 *src)
{
  I64 n = StrLen(dst);
  while (*src && n < size - 3) {
    if (*src == '"' || *src == '\\') {
      dst[n] = '\\';
      n++;
    }
    dst[n] = *src;
    n++;
    src++;
  }
  dst[n] = 0;
}

U0 int_to_text(I64 v, U8 *out)
{
  U8 tmp[24];
  I64 n = 0;
  I64 i = 0;
  if (v == 0) {
    out[0] = '0';
    out[1] = 0;
    return;
  }
  if (v < 0) {
    out[i] = '-';
    i++;
    v = -v;
  }
  while (v > 0) {
    tmp[n] = '0' + (v % 10);
    n++;
    v = v / 10;
  }
  while (n > 0) {
    n--;
    out[i] = tmp[n];
    i++;
  }
  out[i] = 0;
}

U0 emit_text(U8 *f, U8 *key, U8 *value)
{
  cfg_line[0] = 0;
  cat_to(cfg_line, 700, key);
  cat_to(cfg_line, 700, " = \"");
  cat_escaped(cfg_line, 700, value);
  cat_to(cfg_line, 700, "\";\n");
  fputs(cfg_line, f);
}

U0 emit_int(U8 *f, U8 *key, I64 value)
{
  U8 number[24];
  int_to_text(value, number);
  cfg_line[0] = 0;
  cat_to(cfg_line, 700, key);
  cat_to(cfg_line, 700, " = ");
  cat_to(cfg_line, 700, number);
  cat_to(cfg_line, 700, ";\n");
  fputs(cfg_line, f);
}

U0 emit_bool(U8 *f, U8 *key, I64 value)
{
  cfg_line[0] = 0;
  cat_to(cfg_line, 700, key);
  if (value) cat_to(cfg_line, 700, " = TRUE;\n");
  else cat_to(cfg_line, 700, " = FALSE;\n");
  fputs(cfg_line, f);
}

U0 emit_bind(U8 *f, Binding *b)
{
  cfg_line[0] = 0;
  cat_to(cfg_line, 700, "Bind(\"");
  cat_escaped(cfg_line, 700, b->combo);
  cat_to(cfg_line, 700, "\", \"");
  cat_escaped(cfg_line, 700, b->action);
  cat_to(cfg_line, 700, "\", \"");
  cat_escaped(cfg_line, 700, b->command);
  cat_to(cfg_line, 700, "\");\n");
  fputs(cfg_line, f);
}

// Writes the settings that are currently loaded (built-in defaults plus any
// older lhwm.conf) so an existing setup carries over unchanged.
U0 write_default_config(U8 *path)
{
  U8 *f = fopen(path, "w");
  I64 i;
  if (!f) return;
  fputs("// LHWM config.HC\n", f);
  fputs("// Edit this file, then press Mod4+r. Every change below is applied\n", f);
  fputs("// instantly: nothing is recompiled and the window manager keeps running.\n", f);
  fputs("//\n", f);
  fputs("// One statement per line, ending with a semicolon. // starts a comment.\n", f);
  fputs("//   Setting = value;                    number, TRUE/FALSE or \"text\"\n", f);
  fputs("//   Bind(\"Mod4+Key\", \"action\", \"command\");    add or replace a keybind\n", f);
  fputs("//   Rule(\"WM_CLASS\", \"action\", argument);     per-application window rule\n", f);
  fputs("// Colors are X color names or hex values such as \"#1e1e2e\".\n", f);
  fputs("\n// ---- Layout -----------------------------------------------------------\n", f);
  fputs("// Layout: \"master-stack\", \"columns\" or \"monocle\" (Mod4+Tab cycles them).\n", f);
  if (layout == LAYOUT_COLUMNS) emit_text(f, "Layout", "columns");
  else if (layout == LAYOUT_MONOCLE) emit_text(f, "Layout", "monocle");
  else emit_text(f, "Layout", "master-stack");
  emit_int(f, "Gap", gap);
  emit_int(f, "BorderWidth", border_width);
  fputs("// Percentage of the screen width given to the master window.\n", f);
  emit_int(f, "MasterRatio", master_ratio);
  emit_text(f, "BorderFocus", focus_color);
  emit_text(f, "BorderNormal", normal_color);
  fputs("\n// ---- Focus ------------------------------------------------------------\n", f);
  fputs("// TRUE focuses a window as soon as the mouse enters it. Hovering never raises.\n", f);
  emit_bool(f, "FocusFollowsMouse", focus_follows);
  fputs("\n// ---- Top bar ----------------------------------------------------------\n", f);
  emit_bool(f, "BarEnabled", bar_enabled);
  emit_int(f, "BarHeight", bar_height);
  emit_int(f, "BarBorderWidth", bar_border_width);
  emit_text(f, "BarBorderColor", bar_border_color);
  emit_text(f, "BarBg", bar_bg);
  emit_text(f, "BarFg", bar_fg);
  emit_text(f, "BarAccent", bar_accent);
  fputs("// An X11 core font name; \"fixed\" and \"6x13\" are tried if it is missing.\n", f);
  emit_text(f, "BarFont", bar_font_name);
  fputs("\n// ---- Clock ------------------------------------------------------------\n", f);
  emit_bool(f, "ClockEnabled", clock_enabled);
  fputs("// strftime format, for example \"%H:%M\" or \"%a %d %b  %H:%M\".\n", f);
  emit_text(f, "ClockFormat", clock_format);
  fputs("// Seconds between clock refreshes.\n", f);
  emit_int(f, "ClockUpdateInterval", clock_update_interval);
  fputs("\n// ---- Workspace squares ------------------------------------------------\n", f);
  emit_text(f, "WorkspaceBorderColor", workspace_border_color);
  emit_text(f, "WorkspaceActiveBorder", workspace_active_border);
  emit_text(f, "WorkspaceActiveBg", workspace_active_bg);
  emit_text(f, "WorkspaceFg", workspace_fg);
  emit_text(f, "WorkspaceActiveFg", workspace_active_fg);
  fputs("\n// ---- Keybinds ---------------------------------------------------------\n", f);
  fputs("// Modifiers: Mod4 (Super), Shift, Ctrl, Alt.\n", f);
  fputs("// Actions: spawn COMMAND, kill, quit, reload, mode, focus_next, focus_prev,\n", f);
  fputs("//          layout_next, workspace N, move_workspace N, none (unbinds a key).\n", f);
  for (i = 0; i < nbinds; i++) emit_bind(f, &binds[i]);
  fputs("\n// ---- Window rules -----------------------------------------------------\n", f);
  fputs("// Dialogs, pop-ups and other transient windows float automatically instead of\n", f);
  fputs("// being tiled. A rule matches a window's WM_CLASS (see: xprop WM_CLASS).\n", f);
  fputs("// Actions: \"float\", \"tile\", \"workspace\" (opens it silently on that workspace,\n", f);
  fputs("// without switching to it or taking focus). Rules apply to windows opened\n", f);
  fputs("// after the reload. Examples:\n", f);
  fputs("// Rule(\"Thunar\", \"workspace\", 9);\n", f);
  fputs("// Rule(\"pcmanfm\", \"float\", 0);\n", f);
  fputs("// Rule(\"Pavucontrol\", \"float\", 0);\n", f);
  fclose(f);
}

I64 file_exists(U8 *path)
{
  U8 *f = fopen(path, "r");
  if (!f) return 0;
  fclose(f);
  return 1;
}

I64 user_config_dir(U8 *out, I64 size)
{
  U8 *xdg = getenv("XDG_CONFIG_HOME");
  U8 *home = getenv("HOME");
  if (xdg && *xdg) {
    copystr(out, size, xdg);
    cat_to(out, size, "/lhwm");
    return 1;
  }
  if (home && *home) {
    copystr(out, size, home);
    cat_to(out, size, "/.config/lhwm");
    return 1;
  }
  return 0;
}

// Creates ~/.config and ~/.config/lhwm (or $XDG_CONFIG_HOME/lhwm).
U0 make_config_dir()
{
  U8 *xdg = getenv("XDG_CONFIG_HOME");
  U8 *home = getenv("HOME");
  U8 path[512];
  if (xdg && *xdg) {
    mkdir(xdg, 493);
    copystr(path, 512, xdg);
  } else if (home && *home) {
    copystr(path, 512, home);
    cat_to(path, 512, "/.config");
    mkdir(path, 493);
  } else return;
  cat_to(path, 512, "/lhwm");
  mkdir(path, 493);
}

U0 load_config()
{
  U8 *default_config;
  U8 *custom;
  U8 dir[480];
  U8 legacy[512];
  U8 path[512];
  I64 previous_workspace = current_workspace;
  defaults();
  if (previous_workspace >= 1 && previous_workspace <= WORKSPACE_COUNT)
    current_workspace = previous_workspace;
  read_config_file("/etc/lhwm/lhwm.conf");
  default_config = getenv("LHWM_DEFAULT_CONFIG");
  if (default_config && *default_config) read_config_file(default_config);
  custom = getenv("LHWM_CONFIG");
  if (custom && *custom) {
    read_config_file(custom);
  } else if (user_config_dir(dir, 480)) {
    copystr(legacy, 512, dir);
    cat_to(legacy, 512, "/lhwm.conf");
    copystr(path, 512, dir);
    cat_to(path, 512, "/config.HC");
    // An older lhwm.conf is honored once and carried into the new file.
    read_config_file(legacy);
    if (!file_exists(path)) {
      make_config_dir();
      write_default_config(path);
    }
    read_config_file(path);
  } else {
    read_config_file("./lhwm.conf");
    read_config_file("./config.HC");
  }
  if (gap < 0) gap = 0;
  if (gap > 96) gap = 96;
  if (border_width < 0) border_width = 0;
  if (border_width > 12) border_width = 12;
  if (master_ratio < 35) master_ratio = 35;
  if (master_ratio > 80) master_ratio = 80;
  if (bar_height < 24) bar_height = 24;
  if (bar_height > 48) bar_height = 48;
  if (clock_update_interval < 1) clock_update_interval = 1;
  if (clock_update_interval > 60) clock_update_interval = 60;
  next_clock_tick = time(NULL) + clock_update_interval;
  if (bar_border_width < 0) bar_border_width = 0;
  if (bar_border_width > 4) bar_border_width = 4;
}

// Returns the pixel for a color name, or the fallback when it cannot be
// allocated.  Success is judged by the return value and never by the pixel
// number, because black legitimately has pixel 0 on TrueColor visuals.
U64 alloc_pixel(U8 *name, U64 fallback)
{
  XColor c1;
  XColor c2;
  if (XAllocNamedColor(dpy, cmap, name, &c1, &c2)) return c1.pixel;
  return fallback;
}

// Colors are not freed on reload: on TrueColor visuals XFreeColors is a
// no-op, and freeing shared fallback pixels twice could release cells that
// are still in use.
U0 load_color_pixels()
{
  focus_pixel = alloc_pixel(focus_color, 0);
  normal_pixel = alloc_pixel(normal_color, 0);
  bar_bg_pixel = alloc_pixel(bar_bg, normal_pixel);
  bar_fg_pixel = alloc_pixel(bar_fg, focus_pixel);
  bar_accent_pixel = alloc_pixel(bar_accent, focus_pixel);
  bar_border_pixel = alloc_pixel(bar_border_color, normal_pixel);
  workspace_border_pixel = alloc_pixel(workspace_border_color, normal_pixel);
  workspace_active_border_pixel = alloc_pixel(workspace_active_border, bar_accent_pixel);
  workspace_active_bg_pixel = alloc_pixel(workspace_active_bg, bar_accent_pixel);
  workspace_fg_pixel = alloc_pixel(workspace_fg, bar_fg_pixel);
  workspace_active_fg_pixel = alloc_pixel(workspace_active_fg, bar_fg_pixel);
}

I64 bar_offset()
{
  if (bar_enabled) return bar_height;
  return 0;
}

I64 workspace_start_x()
{
  I64 x = 18;
  if (clock_enabled && clock_text[0]) x += (StrLen(clock_text) * 8) + 18;
  if (x < 24) x = 24;
  return x;
}

I64 workspace_hitbox(I32 x, I32 y)
{
  I64 start = workspace_start_x();
  I64 step = 27;
  I64 size = 22;
  I64 i;
  I64 top = (bar_height - size) / 2;
  if (y < top || y >= top + size) return 0;
  for (i = 0; i < WORKSPACE_COUNT; i++) {
    if (x >= start + (i * step) && x < start + (i * step) + size)
      return i + 1;
  }
  return 0;
}

I64 text_equal(U8 *a, U8 *b)
{
  while (*a && *b && *a == *b) { a++; b++; }
  return *a == *b;
}

// Native equivalent of Qtile's Clock(InLoopPollText): format local time,
// compare it with the previous text, and let the bar redraw only on change.
I64 update_bar_clock()
{
  I64 now;
  U8 *time_info;
  U8 formatted[128];
  if (!clock_enabled) formatted[0] = 0;
  else {
    now = time(NULL);
    time_info = localtime(&now);
    if (!time_info || !strftime(formatted, 128, clock_format, time_info))
      copystr(formatted, 128, "--:--");
  }
  if (!text_equal(clock_text, formatted)) {
    copystr(clock_text, 128, formatted);
    return 1;
  }
  return 0;
}

I64 bar_font_available(U8 *name)
{
  I32 count = 0;
  U8 **names = XListFonts(dpy, name, 1, &count);
  if (names) XFreeFontNames(names);
  if (count > 0) return 1;
  return 0;
}

U0 load_bar_font()
{
  if (bar_font) {
    XUnloadFont(dpy, bar_font);
    bar_font = 0;
  }
  // Core X fonts are intentionally used to avoid pulling Xft/GTK into LHWM.
  // Check with XListFonts first because XLoadFont is asynchronous and does
  // not reliably report a missing font by returning zero.
  if (bar_font_name[0] && bar_font_available(bar_font_name))
    bar_font = XLoadFont(dpy, bar_font_name);
  if (!bar_font && bar_font_available("fixed")) bar_font = XLoadFont(dpy, "fixed");
  if (!bar_font && bar_font_available("6x13")) bar_font = XLoadFont(dpy, "6x13");
  if (!bar_font && bar_font_available("7x14")) bar_font = XLoadFont(dpy, "7x14");
  if (!bar_font && !bar_font_warned) {
    "lhwm: no X core font found; install the X11 misc bitmap fonts\n";
    bar_font_warned = 1;
  }
  if (bar_gc && bar_font) XSetFont(dpy, bar_gc, bar_font);
}

U0 draw_bar()
{
  I64 baseline;
  I64 ws_start;
  I64 ws_top;
  I64 ws_x;
  I64 i;
  U8 ws_label[2];
  if (!bar_enabled || !bar_window || !bar_gc) return;
  XSetWindowBackground(dpy, bar_window, bar_bg_pixel);
  XClearWindow(dpy, bar_window);
  if (!bar_font) { XFlush(dpy); return; }
  baseline = (bar_height / 2) + 5;
  XSetForeground(dpy, bar_gc, bar_fg_pixel);
  if (clock_enabled && clock_text[0]) XDrawString(dpy, bar_window, bar_gc, 14, baseline, clock_text, StrLen(clock_text));
  // Nine compact, outlined workspace hitboxes sit immediately after the
  // date/clock.  Their positions are shared with workspace_hitbox().
  ws_start = workspace_start_x();
  ws_top = (bar_height - 22) / 2;
  ws_label[1] = 0;
  for (i = 0; i < WORKSPACE_COUNT; i++) {
    ws_x = ws_start + (i * 27);
    if (i + 1 == current_workspace) {
      XSetForeground(dpy, bar_gc, workspace_active_bg_pixel);
      XFillRectangle(dpy, bar_window, bar_gc, ws_x + 1, ws_top + 1, 20, 20);
      XSetForeground(dpy, bar_gc, workspace_active_border_pixel);
    } else {
      XSetForeground(dpy, bar_gc, workspace_border_pixel);
    }
    XDrawRectangle(dpy, bar_window, bar_gc, ws_x, ws_top, 21, 21);
    if (i + 1 == current_workspace) XSetForeground(dpy, bar_gc, workspace_active_fg_pixel);
    else XSetForeground(dpy, bar_gc, workspace_fg_pixel);
    ws_label[0] = '1' + i;
    XDrawString(dpy, bar_window, bar_gc, ws_x + 8, baseline, ws_label, 1);
  }
  if (bar_border_width > 0) {
    XSetForeground(dpy, bar_gc, bar_border_pixel);
    XSetLineAttributes(dpy, bar_gc, bar_border_width, LineSolid, CapButt, JoinMiter);
    XDrawRectangle(dpy, bar_window, bar_gc, 0, 0, screen_w - 1, bar_height - 1);
    XSetLineAttributes(dpy, bar_gc, 1, LineSolid, CapButt, JoinMiter);
  }
  XFlush(dpy);
}

U0 destroy_bar()
{
  if (bar_gc) XFreeGC(dpy, bar_gc);
  if (bar_font) XUnloadFont(dpy, bar_font);
  if (bar_window) XDestroyWindow(dpy, bar_window);
  bar_gc = 0;
  bar_font = 0;
  bar_font_warned = 0;
  bar_window = 0;
}

U0 configure_bar()
{
  XSetWindowAttributes attrs;
  if (!bar_enabled) {
    destroy_bar();
    return;
  }
  if (!bar_window) {
    MemSet(&attrs, 0, sizeof(XSetWindowAttributes));
    attrs.override_redirect = True;
    bar_window = XCreateSimpleWindow(dpy, root, 0, 0, screen_w, bar_height, 0, bar_bg_pixel, bar_bg_pixel);
    if (!bar_window) return;
    XChangeWindowAttributes(dpy, bar_window, CWOverrideRedirect, &attrs);
    XSelectInput(dpy, bar_window, ExposureMask | ButtonPressMask);
    bar_gc = XCreateGC(dpy, bar_window, 0, NULL);
    load_bar_font();
    if (!bar_gc) "lhwm: could not create the topbar drawing context\n";
    XMapRaised(dpy, bar_window);
    XSync(dpy, False);
    update_bar_clock();
    draw_bar();
  } else {
    if (bar_gc && !bar_font) load_bar_font();
    XMoveResizeWindow(dpy, bar_window, 0, 0, screen_w, bar_height);
    XSetWindowBackground(dpy, bar_window, bar_bg_pixel);
    XMapRaised(dpy, bar_window);
    draw_bar();
  }
}

// Keep color selection in a helper instead of a ternary expression inside an
// Xlib call; some hcc parser versions mis-parse that argument form.
I64 border_pixel_for(I64 index)
{
  if (index == selected) return focus_pixel;
  return normal_pixel;
}

I64 client_index(U64 win)
{
  I64 i;
  for (i = 0; i < nclients; i++) if (clients[i].win == win) return i;
  return -1;
}

I64 visible_count()
{
  I64 i;
  I64 count = 0;
  for (i = 0; i < nclients; i++)
    if (clients[i].workspace == current_workspace) count++;
  return count;
}

I64 visible_client_at(I64 position)
{
  I64 i;
  I64 count = 0;
  for (i = 0; i < nclients; i++) {
    if (clients[i].workspace != current_workspace) continue;
    if (count == position) return i;
    count++;
  }
  return -1;
}

U0 focus_client(I64 index)
{
  focus_client_ex(index, 1);
}

// Hover focus passes raise = 0 so merely moving the pointer never reshuffles
// overlapping floating windows.
U0 focus_client_ex(I64 index, I64 raise)
{
  I64 i;
  U8 *active_data;
  if (index < 0 || index >= nclients) return;
  selected = index;
  for (i = 0; i < nclients; i++) {
    XSetWindowBorder(dpy, clients[i].win, border_pixel_for(i));
  }
  XSetInputFocus(dpy, clients[selected].win, RevertToPointerRoot, CurrentTime);
  if (raise && (mode == MODE_FLOATING || layout == LAYOUT_MONOCLE)) XRaiseWindow(dpy, clients[selected].win);
  if (bar_enabled && bar_window) XRaiseWindow(dpy, bar_window);
  active_data = &clients[selected].win;
  XChangeProperty(dpy, root, net_active_window, XA_WINDOW, 32, PropModeReplace,
      active_data, 1);
  XFlush(dpy);
}

U0 set_client_geometry(I64 i, I32 x, I32 y, I32 w, I32 h)
{
  if (i < 0 || i >= nclients) return;
  if (w < 80) w = 80;
  if (h < 60) h = 60;
  clients[i].x = x;
  clients[i].y = y;
  clients[i].w = w;
  clients[i].h = h;
  XMoveResizeWindow(dpy, clients[i].win, x, y, w, h);
}

I64 tiled_count()
{
  I64 i;
  I64 count = 0;
  for (i = 0; i < nclients; i++)
    if (clients[i].workspace == current_workspace && !clients[i].floating) count++;
  return count;
}

I64 tiled_client_at(I64 position)
{
  I64 i;
  I64 count = 0;
  for (i = 0; i < nclients; i++) {
    if (clients[i].workspace != current_workspace || clients[i].floating) continue;
    if (count == position) return i;
    count++;
  }
  return -1;
}

// Floating clients (dialogs and rule matches) sit above the tiled windows.
U0 raise_floating_clients()
{
  I64 i;
  for (i = 0; i < nclients; i++)
    if (clients[i].workspace == current_workspace && clients[i].floating && clients[i].mapped)
      XRaiseWindow(dpy, clients[i].win);
}

U0 arrange()
{
  I64 pos;
  I64 index;
  I64 count = tiled_count();
  I64 total = visible_count();
  I64 usable_w;
  I64 usable_h;
  I64 master_w;
  I64 stack_w;
  I64 count_stack;
  I64 base_h;
  I64 extra_h;
  I64 y;
  I64 col_w;
  I64 x;
  I64 top = bar_offset();
  if (total <= 0) {
    selected = -1;
    if (bar_window) XRaiseWindow(dpy, bar_window);
    XFlush(dpy);
    return;
  }
  if (mode == MODE_FLOATING) {
    for (pos = 0; pos < total; pos++) {
      index = visible_client_at(pos);
      XSetWindowBorderWidth(dpy, clients[index].win, border_width);
      XSetWindowBorder(dpy, clients[index].win, border_pixel_for(index));
    }
    if (selected >= 0 && selected < nclients && clients[selected].workspace == current_workspace)
      XRaiseWindow(dpy, clients[selected].win);
    if (bar_window) XRaiseWindow(dpy, bar_window);
    XFlush(dpy);
    return;
  }
  if (count > 0) {
    usable_w = screen_w - (2 * gap);
    usable_h = screen_h - top - (2 * gap);
    if (usable_w < 100) usable_w = 100;
    if (usable_h < 80) usable_h = 80;
    if (layout == LAYOUT_MONOCLE) {
      for (pos = 0; pos < count; pos++) {
        index = tiled_client_at(pos);
        XSetWindowBorderWidth(dpy, clients[index].win, border_width);
        XSetWindowBorder(dpy, clients[index].win, border_pixel_for(index));
        set_client_geometry(index, gap, top + gap,
            usable_w - 2 * border_width, usable_h - 2 * border_width);
        if (index == selected) XRaiseWindow(dpy, clients[index].win);
      }
    } else if (layout == LAYOUT_COLUMNS) {
      col_w = usable_w / count;
      x = gap;
      for (pos = 0; pos < count; pos++) {
        I64 this_w = col_w;
        index = tiled_client_at(pos);
        if (pos == count - 1) this_w = screen_w - gap - x;
        XSetWindowBorderWidth(dpy, clients[index].win, border_width);
        XSetWindowBorder(dpy, clients[index].win, border_pixel_for(index));
        set_client_geometry(index, x, top + gap,
            this_w - 2 * border_width, usable_h - 2 * border_width);
        x += col_w;
      }
    } else if (count == 1) {
      index = tiled_client_at(0);
      XSetWindowBorderWidth(dpy, clients[index].win, border_width);
      XSetWindowBorder(dpy, clients[index].win, focus_pixel);
      set_client_geometry(index, gap, top + gap,
          usable_w - 2 * border_width, usable_h - 2 * border_width);
    } else {
      master_w = ((usable_w - gap) * master_ratio) / 100;
      stack_w = usable_w - master_w - gap;
      if (master_w < 160) master_w = 160;
      if (stack_w < 120) stack_w = 120;
      count_stack = count - 1;
      base_h = (usable_h - ((count_stack - 1) * gap)) / count_stack;
      extra_h = (usable_h - ((count_stack - 1) * gap)) - (base_h * count_stack);
      index = tiled_client_at(0);
      XSetWindowBorderWidth(dpy, clients[index].win, border_width);
      XSetWindowBorder(dpy, clients[index].win, border_pixel_for(index));
      set_client_geometry(index, gap, top + gap,
          master_w - 2 * border_width, usable_h - 2 * border_width);
      y = top + gap;
      for (pos = 1; pos < count; pos++) {
        I64 this_h = base_h;
        index = tiled_client_at(pos);
        if (pos == count - 1) this_h += extra_h;
        XSetWindowBorderWidth(dpy, clients[index].win, border_width);
        XSetWindowBorder(dpy, clients[index].win, border_pixel_for(index));
        set_client_geometry(index, gap + master_w + gap, y,
            stack_w - 2 * border_width, this_h - 2 * border_width);
        y += this_h + gap;
      }
    }
  }
  if (selected >= 0 && selected < nclients && clients[selected].workspace == current_workspace && layout != LAYOUT_MONOCLE)
    XRaiseWindow(dpy, clients[selected].win);
  raise_floating_clients();
  if (bar_window) XRaiseWindow(dpy, bar_window);
  XFlush(dpy);
}

U0 grab_keys()
{
  // owner_events=False forces grabbed key presses back to the root window,
  // even when the focused application also selects KeyPress events.
  I64 i;
  I64 code;
  XUngrabKey(dpy, AnyKey, AnyModifier, root);
  for (i = 0; i < nbinds; i++) {
    code = binds[i].keycode;
    if (!code) continue;
    // Action "none" unbinds a key: leave it ungrabbed so applications get it.
    if (!strcasecmp(binds[i].action, "none")) continue;
    XGrabKey(dpy, code, binds[i].mods, root, False, GrabModeAsync, GrabModeAsync);
    XGrabKey(dpy, code, binds[i].mods | LockMask, root, False, GrabModeAsync, GrabModeAsync);
    XGrabKey(dpy, code, binds[i].mods | Mod2Mask, root, False, GrabModeAsync, GrabModeAsync);
    XGrabKey(dpy, code, binds[i].mods | LockMask | Mod2Mask, root, False, GrabModeAsync, GrabModeAsync);
  }
}

U0 focus_next(I64 direction)
{
  I64 count = visible_count();
  I64 pos = -1;
  I64 i;
  if (count < 1) return;
  for (i = 0; i < count; i++) if (visible_client_at(i) == selected) pos = i;
  if (pos < 0) pos = 0;
  else {
    pos += direction;
    if (pos < 0) pos = count - 1;
    if (pos >= count) pos = 0;
  }
  selected = visible_client_at(pos);
  focus_client(selected);
  if (mode == MODE_TILING) arrange();
}

U0 set_workspace(I64 workspace)
{
  I64 i;
  if (workspace < 1 || workspace > WORKSPACE_COUNT || workspace == current_workspace) return;
  // Hide the old workspace.  The matching UnmapNotify is tagged so it is
  // treated as our visibility change, not as an application closing itself.
  for (i = 0; i < nclients; i++) {
    if (clients[i].workspace == current_workspace && clients[i].mapped) {
      clients[i].ignore_unmap = 1;
      XUnmapWindow(dpy, clients[i].win);
      clients[i].mapped = 0;
    }
  }
  current_workspace = workspace;
  selected = -1;
  for (i = 0; i < nclients; i++) {
    if (clients[i].workspace == current_workspace) {
      if (!clients[i].mapped) {
        XMapWindow(dpy, clients[i].win);
        clients[i].mapped = 1;
      }
      if (selected < 0) selected = i;
    }
  }
  arrange();
  if (selected >= 0) focus_client(selected);
  else {
    XDeleteProperty(dpy, root, net_active_window);
    XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
  }
  draw_bar();
  XFlush(dpy);
}

U0 move_focused_to_workspace(I64 workspace)
{
  I64 old_workspace;
  I64 i;
  if (workspace < 1 || workspace > WORKSPACE_COUNT) return;
  if (selected < 0 || selected >= nclients) return;
  if (clients[selected].workspace != current_workspace || workspace == current_workspace) return;
  old_workspace = current_workspace;
  clients[selected].workspace = workspace;
  if (clients[selected].mapped) {
    clients[selected].ignore_unmap = 1;
    XUnmapWindow(dpy, clients[selected].win);
    clients[selected].mapped = 0;
  }
  selected = -1;
  for (i = 0; i < nclients; i++) {
    if (clients[i].workspace == old_workspace) {
      selected = i;
      break;
    }
  }
  arrange();
  if (selected >= 0) focus_client(selected);
  else {
    XDeleteProperty(dpy, root, net_active_window);
    XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
  }
  draw_bar();
  XFlush(dpy);
}

U0 set_mode(I64 next_mode)
{
  I64 i;
  if (next_mode == mode) return;
  mode = next_mode;
  if (mode == MODE_FLOATING) {
    for (i = 0; i < nclients; i++) {
      if (clients[i].w <= 0 || clients[i].h <= 0) {
        clients[i].w = screen_w * 70 / 100;
        clients[i].h = screen_h * 70 / 100;
        clients[i].x = (screen_w - clients[i].w) / 2;
        clients[i].y = bar_offset() + (screen_h - bar_offset() - clients[i].h) / 2;
      }
    }
  }
  arrange();
  if (selected >= 0 && selected < nclients) focus_client(selected);
}

U0 close_focused()
{
  U8 *protocol_raw = NULL;
  U64 *protocols;
  I32 count = 0;
  I64 i;
  I64 supports_delete = 0;
  XEvent ev;
  U64 win;
  if (selected < 0 || selected >= nclients) return;
  win = clients[selected].win;
  if (XGetWMProtocols(dpy, win, &protocol_raw, &count)) {
    protocols = protocol_raw(U64 *);
    for (i = 0; i < count; i++) if (protocols[i] == wm_delete_window) supports_delete = 1;
    if (protocol_raw) XFree(protocol_raw);
  }
  if (supports_delete) {
    MemSet(&ev, 0, sizeof(XEvent));
    ev.xclient.type = 33;
    ev.xclient.window = win;
    ev.xclient.message_type = wm_protocols;
    ev.xclient.format = 32;
    ev.xclient.l[0] = wm_delete_window;
    ev.xclient.l[1] = CurrentTime;
    XSendEvent(dpy, win, False, 0, &ev);
  } else {
    XKillClient(dpy, win);
  }
}

U0 run_command(U8 *command)
{
  I64 pid;
  U8 *argv[4];
  if (!command || !*command) return;
  pid = fork();
  if (pid == 0) {
    setsid();
    signal(SIGCHLD, SIG_DFL(U8 *));
    argv[0] = "/bin/sh";
    argv[1] = "-c";
    argv[2] = command;
    argv[3] = NULL;
    execvp("/bin/sh", argv);
    _exit(127);
  }
}

U0 run_action(Binding *binding)
{
  if (!strcasecmp(binding->action, "spawn")) run_command(binding->command);
  else if (!strcasecmp(binding->action, "kill")) close_focused();
  else if (!strcasecmp(binding->action, "quit")) running = 0;
  else if (!strcasecmp(binding->action, "reload")) {
    load_config();
    load_color_pixels();
    if (bar_gc) load_bar_font();
    configure_bar();
    update_bar_clock();
    draw_bar();
    grab_keys();
    arrange();
  }
  else if (!strcasecmp(binding->action, "mode")) {
    if (mode == MODE_TILING) set_mode(MODE_FLOATING);
    else set_mode(MODE_TILING);
  }
  else if (!strcasecmp(binding->action, "focus_next")) focus_next(1);
  else if (!strcasecmp(binding->action, "focus_prev")) focus_next(-1);
  else if (!strcasecmp(binding->action, "workspace")) set_workspace(to_int(binding->command));
  else if (!strcasecmp(binding->action, "move_workspace")) move_focused_to_workspace(to_int(binding->command));
  else if (!strcasecmp(binding->action, "layout_next")) {
    layout++;
    if (layout > LAYOUT_MONOCLE) layout = LAYOUT_MASTER;
    arrange();
  }
}

// Grab Mod4+Button1/3 for move and resize.  The Caps Lock and Num Lock
// variants are grabbed too, otherwise dragging dies when either is on.
U0 grab_window_buttons(U64 win)
{
  U32 locks[4];
  I64 i;
  locks[0] = 0;
  locks[1] = LockMask;
  locks[2] = Mod2Mask;
  locks[3] = LockMask | Mod2Mask;
  for (i = 0; i < 4; i++) {
    XGrabButton(dpy, Button1, Mod4Mask | locks[i], win, False,
        ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
        GrabModeAsync, GrabModeAsync, None, None);
    XGrabButton(dpy, Button3, Mod4Mask | locks[i], win, False,
        ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
        GrabModeAsync, GrabModeAsync, None, None);
  }
}

// Dialogs, utility windows and splash screens should appear next to the
// tiled layout, not become a tile themselves.  Transient windows (file
// choosers, rename boxes, "save as" and similar) are the usual case.
I64 window_wants_float(U64 win)
{
  U64 parent = 0;
  U64 actual_type = 0;
  I32 actual_format = 0;
  U64 nitems = 0;
  U64 bytes_after = 0;
  U8 *data = NULL;
  U64 *atoms;
  I64 j;
  I64 result = 0;
  if (XGetTransientForHint(dpy, win, &parent) && parent) result = 1;
  if (XGetWindowProperty(dpy, win, net_wm_window_type, 0, 8, False, XA_ATOM,
      &actual_type, &actual_format, &nitems, &bytes_after, &data) == 0 && data) {
    if (actual_format == 32) {
      atoms = data(U64 *);
      for (j = 0; j < nitems; j++) {
        if (atoms[j] == wtype_dialog || atoms[j] == wtype_utility ||
            atoms[j] == wtype_splash || atoms[j] == wtype_toolbar) result = 1;
      }
    }
    XFree(data);
  }
  return result;
}

I64 rule_matches(WinRule *rule, U8 *name, U8 *cls)
{
  if (!strcasecmp(rule->name, name)) return 1;
  if (!strcasecmp(rule->name, cls)) return 1;
  return 0;
}

// Centers a floating window on the usable screen area, keeping the size the
// application asked for.
U0 place_floating(I64 i)
{
  I64 top = bar_offset();
  I32 w = clients[i].w;
  I32 h = clients[i].h;
  I32 x;
  I32 y;
  if (w <= 1 || h <= 1) {
    w = screen_w * 50 / 100;
    h = (screen_h - top) * 50 / 100;
  }
  if (w > screen_w - (2 * border_width)) w = screen_w - (2 * border_width);
  if (h > screen_h - top - (2 * border_width)) h = screen_h - top - (2 * border_width);
  x = (screen_w - w) / 2;
  y = top + ((screen_h - top - h) / 2);
  if (x < 0) x = 0;
  if (y < top) y = top;
  set_client_geometry(i, x, y, w, h);
}

U0 manage(U64 win)
{
  XWindowAttributes wa;
  XClassHint hint;
  U8 cname[64];
  U8 cclass[64];
  I64 i;
  I64 j;
  I64 target;
  if (client_index(win) >= 0 || nclients >= MAX_CLIENTS) return;
  if (!XGetWindowAttributes(dpy, win, &wa) || wa.override_redirect) return;
  if (wa.map_state == IsViewable && wa.width <= 1 && wa.height <= 1) return;
  cname[0] = 0;
  cclass[0] = 0;
  hint.res_name = NULL;
  hint.res_class = NULL;
  if (XGetClassHint(dpy, win, &hint)) {
    copystr(cname, 64, hint.res_name);
    copystr(cclass, 64, hint.res_class);
    if (hint.res_name) XFree(hint.res_name);
    if (hint.res_class) XFree(hint.res_class);
  }
  i = nclients;
  clients[i].win = win;
  clients[i].x = wa.x;
  clients[i].y = wa.y;
  clients[i].w = wa.width;
  clients[i].h = wa.height;
  clients[i].mapped = 1;
  clients[i].ignore_unmap = 0;
  clients[i].floating = window_wants_float(win);
  target = current_workspace;
  for (j = 0; j < nrules; j++) {
    if (!rule_matches(&rules[j], cname, cclass)) continue;
    if (rules[j].action == RULE_FLOAT) clients[i].floating = 1;
    else if (rules[j].action == RULE_TILE) clients[i].floating = 0;
    else if (rules[j].action == RULE_WORKSPACE) target = rules[j].arg;
  }
  clients[i].workspace = target;
  nclients++;
  // ButtonPressMask is exclusive: if the application already selected it, the
  // whole request fails with BadAccess and EnterWindowMask would be lost too.
  // Mod4 clicks reach us through the passive grabs below instead.
  XSelectInput(dpy, win, StructureNotifyMask | EnterWindowMask);
  grab_window_buttons(win);
  XSetWindowBorderWidth(dpy, win, border_width);
  if (clients[i].floating) {
    place_floating(i);
  } else if (mode == MODE_FLOATING) {
    I64 offset = (i % 7) * 24;
    I32 w = screen_w * 70 / 100;
    I32 h = screen_h * 70 / 100;
    clients[i].x = (screen_w - w) / 2 + offset;
    clients[i].y = bar_offset() + (screen_h - bar_offset() - h) / 2 + offset;
    clients[i].w = w;
    clients[i].h = h;
    XMoveResizeWindow(dpy, win, clients[i].x, clients[i].y, w, h);
  }
  if (target != current_workspace) {
    // A rule sent this window to another workspace: keep it hidden and leave
    // the current focus alone so nothing pops up in front of the user.
    clients[i].mapped = 0;
    if (wa.map_state == IsViewable) {
      clients[i].ignore_unmap = 1;
      XUnmapWindow(dpy, win);
    }
    return;
  }
  XMapWindow(dpy, win);
  selected = i;
  arrange();
  focus_client(selected);
}

U0 unmanage(U64 win)
{
  I64 i = client_index(win);
  I64 j;
  I64 old_selected = selected;
  if (i < 0) return;
  if (drag_mode && drag_client == i) {
    XUngrabPointer(dpy, CurrentTime);
    drag_mode = 0;
    drag_client = -1;
  }
  for (j = i; j < nclients - 1; j++) clients[j] = clients[j + 1];
  nclients--;
  if (old_selected > i) selected = old_selected - 1;
  else if (old_selected == i) selected = -1;
  else selected = old_selected;
  // The client array contains all workspaces, so the old global index may
  // now point at a hidden client.  Always recover focus from the visible set.
  if (selected < 0 || selected >= nclients || clients[selected].workspace != current_workspace) {
    selected = -1;
    for (j = 0; j < nclients; j++) {
      if (clients[j].workspace == current_workspace) {
        selected = j;
        break;
      }
    }
  }
  arrange();
  if (selected >= 0 && selected < nclients) focus_client(selected);
  else {
    XDeleteProperty(dpy, root, net_active_window);
    XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
  }
}

U0 scan_existing()
{
  U8 *raw = NULL;
  U64 *children;
  U64 parent;
  U64 root_return;
  U32 count = 0;
  I64 i;
  if (!XQueryTree(dpy, root, &root_return, &parent, &raw, &count)) return;
  children = raw(U64 *);
  for (i = 0; i < count; i++) {
    XWindowAttributes wa;
    if (XGetWindowAttributes(dpy, children[i], &wa) &&
        wa.map_state == IsViewable && !wa.override_redirect) manage(children[i]);
  }
  if (raw) XFree(raw);
}

U0 init_atoms()
{
  U64 supported[4];
  U8 *support_data;
  U8 *supported_data;
  wm_protocols = XInternAtom(dpy, "WM_PROTOCOLS", False);
  wm_delete_window = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
  net_active_window = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", False);
  net_supporting_wm_check = XInternAtom(dpy, "_NET_SUPPORTING_WM_CHECK", False);
  net_wm_name = XInternAtom(dpy, "_NET_WM_NAME", False);
  utf8_string = XInternAtom(dpy, "UTF8_STRING", False);
  net_wm_window_type = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE", False);
  wtype_dialog = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DIALOG", False);
  wtype_utility = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_UTILITY", False);
  wtype_splash = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_SPLASH", False);
  wtype_toolbar = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_TOOLBAR", False);
  support_window = XCreateSimpleWindow(dpy, root, -1, -1, 1, 1, 0, 0, 0);
  support_data = &support_window;
  supported_data = supported;
  XChangeProperty(dpy, root, net_supporting_wm_check, XA_WINDOW, 32, PropModeReplace, support_data, 1);
  XChangeProperty(dpy, support_window, net_supporting_wm_check, XA_WINDOW, 32, PropModeReplace, support_data, 1);
  XChangeProperty(dpy, support_window, net_wm_name, utf8_string, 8, PropModeReplace, "LHWM", 4);
  supported[0] = net_active_window;
  supported[1] = net_supporting_wm_check;
  supported[2] = net_wm_name;
  supported[3] = 0;
  XChangeProperty(dpy, root, XInternAtom(dpy, "_NET_SUPPORTED", False), XA_ATOM, 32, PropModeReplace, supported_data, 3);
}

U0 handle_key(XKeyEvent *key)
{
  // Match the physical keycode grabbed by XGrabKey. This avoids shifted
  // keysym differences (for example q versus Q) and works with non-US maps.
  U32 mods = key->state & (ShiftMask | ControlMask | Mod1Mask | Mod4Mask);
  I64 i;
  for (i = 0; i < nbinds; i++) {
    if (binds[i].keycode == key->keycode && binds[i].mods == mods) {
      run_action(&binds[i]);
      return;
    }
  }
}

U0 handle_button(XButtonEvent *button)
{
  I64 i = client_index(button->window);
  I64 workspace;
  if (button->window == bar_window) {
    if (button->button == Button1) {
      workspace = workspace_hitbox(button->x, button->y);
      if (workspace > 0) set_workspace(workspace);
    }
    return;
  }
  if (i < 0) return;
  focus_client(i);
  if (mode != MODE_FLOATING || !(button->state & Mod4Mask)) return;
  drag_client = i;
  drag_start_x = button->x_root;
  drag_start_y = button->y_root;
  drag_orig_x = clients[i].x;
  drag_orig_y = clients[i].y;
  drag_orig_w = clients[i].w;
  drag_orig_h = clients[i].h;
  if (button->button == Button1) drag_mode = 1;
  else if (button->button == Button3) drag_mode = 2;
  if (drag_mode) XGrabPointer(dpy, root, False,
      PointerMotionMask | ButtonReleaseMask, GrabModeAsync, GrabModeAsync,
      None, None, CurrentTime);
}

// Focus follows the mouse: entering a client window focuses it, no click.
U0 handle_enter(XCrossingEvent *crossing)
{
  I64 i;
  if (!focus_follows || drag_mode) return;
  if (crossing->mode != NotifyNormal || crossing->detail == NotifyInferior) return;
  i = client_index(crossing->window);
  if (i < 0 || i == selected) return;
  if (clients[i].workspace != current_workspace) return;
  focus_client_ex(i, 0);
}

U0 handle_motion(XMotionEvent *motion)
{
  I32 dx;
  I32 dy;
  I32 nx;
  I32 ny;
  I32 nw;
  I32 nh;
  if (!drag_mode || drag_client < 0 || drag_client >= nclients) return;
  dx = motion->x_root - drag_start_x;
  dy = motion->y_root - drag_start_y;
  if (drag_mode == 1) {
    nx = drag_orig_x + dx;
    ny = drag_orig_y + dy;
    if (nx < 0) nx = 0;
    if (ny < bar_offset()) ny = bar_offset();
    if (nx + drag_orig_w > screen_w) nx = screen_w - drag_orig_w;
    if (ny + drag_orig_h > screen_h) ny = screen_h - drag_orig_h;
    set_client_geometry(drag_client, nx, ny, drag_orig_w, drag_orig_h);
  } else {
    nw = drag_orig_w + dx;
    nh = drag_orig_h + dy;
    if (nw < 100) nw = 100;
    if (nh < 80) nh = 80;
    if (drag_orig_x + nw > screen_w) nw = screen_w - drag_orig_x;
    if (drag_orig_y + nh > screen_h) nh = screen_h - drag_orig_y;
    set_client_geometry(drag_client, drag_orig_x, drag_orig_y, nw, nh);
  }
}

U0 dispatch(XEvent *event)
{
  I64 i;
  XWindowChanges changes;
  switch (event->type) {
    case KeyPress:
      handle_key(&event->xkey);
      break;
    case Expose:
      if (event->xexpose.window == bar_window && event->xexpose.count == 0) draw_bar();
      break;
    case MapRequest:
      i = client_index(event->xmaprequest.window);
      if (i < 0) manage(event->xmaprequest.window);
      else if (clients[i].workspace == current_workspace && !clients[i].mapped) {
        XMapWindow(dpy, clients[i].win);
        clients[i].mapped = 1;
        arrange();
      }
      break;
    case DestroyNotify:
      // We select StructureNotify on clients and SubstructureNotify on root;
      // only process the root copy to avoid handling duplicate notifications.
      if (event->xdestroywindow.event == root) unmanage(event->xdestroywindow.window);
      break;
    case UnmapNotify:
      if (event->xunmap.event == root) {
        i = client_index(event->xunmap.window);
        if (i >= 0 && clients[i].ignore_unmap) clients[i].ignore_unmap = 0;
        else if (i >= 0) {
          clients[i].mapped = 0;
          unmanage(event->xunmap.window);
        }
      }
      break;
    case ConfigureNotify:
      if (event->xconfigure.window == root) {
        screen_w = XDisplayWidth(dpy, screen_no);
        screen_h = XDisplayHeight(dpy, screen_no);
        configure_bar();
        arrange();
      }
      break;
    case ConfigureRequest:
      i = client_index(event->xconfigurerequest.window);
      if (i >= 0 && mode == MODE_TILING && !clients[i].floating) arrange();
      else {
        changes.x = event->xconfigurerequest.x;
        changes.y = event->xconfigurerequest.y;
        changes.width = event->xconfigurerequest.width;
        changes.height = event->xconfigurerequest.height;
        changes.border_width = event->xconfigurerequest.border_width;
        changes.sibling = event->xconfigurerequest.above;
        changes.stack_mode = event->xconfigurerequest.detail;
        XConfigureWindow(dpy, event->xconfigurerequest.window,
            event->xconfigurerequest.value_mask, &changes);
        if (i >= 0) {
          XWindowAttributes refreshed;
          if (XGetWindowAttributes(dpy, event->xconfigurerequest.window, &refreshed)) {
            clients[i].x = refreshed.x;
            clients[i].y = refreshed.y;
            clients[i].w = refreshed.width;
            clients[i].h = refreshed.height;
          }
        }
      }
      if (bar_window) XRaiseWindow(dpy, bar_window);
      break;
    case ButtonPress:
      handle_button(&event->xbutton);
      break;
    case EnterNotify:
      handle_enter(&event->xcrossing);
      break;
    case MotionNotify:
      handle_motion(&event->xmotion);
      break;
    case ButtonRelease:
      if (drag_mode) XUngrabPointer(dpy, CurrentTime);
      drag_mode = 0;
      drag_client = -1;
      break;
  }
}

U0 main()
{
  XEvent event;
  PollFD x_poll;
  I64 now;
  I32 wait_ms;
  other_wm = 0;
  running = 1;
  selected = -1;
  drag_client = -1;
  mode = MODE_TILING;
  dpy = XOpenDisplay(NULL);
  if (!dpy) {
    "lhwm: cannot open X display\n";
    return;
  }
  screen_no = XDefaultScreen(dpy);
  root = XRootWindow(dpy, screen_no);
  screen_w = XDisplayWidth(dpy, screen_no);
  screen_h = XDisplayHeight(dpy, screen_no);
  cmap = XDefaultColormap(dpy, screen_no);
  signal(SIGCHLD, SIG_IGN(U8 *));
  XSetErrorHandler((&xerror)(U8 *));
  XSelectInput(dpy, root, SubstructureRedirectMask | SubstructureNotifyMask |
      StructureNotifyMask);
  XSync(dpy, False);
  if (other_wm) {
    "lhwm: another window manager is already running\n";
    XCloseDisplay(dpy);
    return;
  }
  load_config();
  load_color_pixels();
  init_atoms();
  configure_bar();
  grab_keys();
  scan_existing();
  arrange();
  XFlush(dpy);
  x_poll.fd = XConnectionNumber(dpy);
  x_poll.events = POLLIN;
  x_poll.revents = 0;
  update_bar_clock();
  draw_bar();
  next_clock_tick = time(NULL) + clock_update_interval;
  while (running) {
    // Wait for either X activity or the next scheduled clock tick. The
    // deadline is retained while X events arrive, so a busy event stream
    // does not cause repeated strftime calls or shift the clock's cadence.
    now = time(NULL);
    wait_ms = (next_clock_tick - now) * 1000;
    if (wait_ms < 0) wait_ms = 0;
    if (XPending(dpy) == 0) {
      x_poll.revents = 0;
      poll(&x_poll, 1, wait_ms);
    }
    while (running && XPending(dpy) > 0) {
      XNextEvent(dpy, &event);
      dispatch(&event);
    }
    now = time(NULL);
    if (running && now >= next_clock_tick) {
      if (update_bar_clock()) draw_bar();
      next_clock_tick = now + clock_update_interval;
    }
  }
  XUngrabKey(dpy, AnyKey, AnyModifier, root);
  XUngrabPointer(dpy, CurrentTime);
  destroy_bar();
  XCloseDisplay(dpy);
}

main;
