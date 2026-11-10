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
};
class Binding
{
  U32 keycode;
  U32 mods;
  U8 action[32];
  U8 command[256];
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
  current_workspace = 1;
  nbinds = 0;
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
      copystr(b->action, 32, action);
      copystr(b->command, 256, command);
      return;
    }
  }
  if (nbinds >= MAX_BINDS) return;
  b = &binds[nbinds];
  b->keycode = keycode;
  b->mods = mods;
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
  if (!strcasecmp(trim(key), "gap")) gap = to_int(value);
  else if (!strcasecmp(trim(key), "border_width")) border_width = to_int(value);
  else if (!strcasecmp(trim(key), "master_ratio")) master_ratio = to_int(value);
  else if (!strcasecmp(trim(key), "layout")) {
    if (!strcasecmp(value, "columns")) layout = LAYOUT_COLUMNS;
    else if (!strcasecmp(value, "monocle")) layout = LAYOUT_MONOCLE;
    else layout = LAYOUT_MASTER;
  }
  else if (!strcasecmp(trim(key), "border_focus")) copystr(focus_color, 64, value);
  else if (!strcasecmp(trim(key), "border_normal")) copystr(normal_color, 64, value);
  else if (!strcasecmp(trim(key), "bar_enabled")) bar_enabled = parse_bool(value, bar_enabled);
  else if (!strcasecmp(trim(key), "bar_height")) bar_height = to_int(value);
  else if (!strcasecmp(trim(key), "clock_enabled")) clock_enabled = parse_bool(value, clock_enabled);
  else if (!strcasecmp(trim(key), "clock_format")) copystr(clock_format, 128, value);
  else if (!strcasecmp(trim(key), "clock_update_interval")) clock_update_interval = to_int(value);
  else if (!strcasecmp(trim(key), "bar_border_width")) bar_border_width = to_int(value);
  else if (!strcasecmp(trim(key), "bar_bg")) copystr(bar_bg, 64, value);
  else if (!strcasecmp(trim(key), "bar_fg")) copystr(bar_fg, 64, value);
  else if (!strcasecmp(trim(key), "bar_accent")) copystr(bar_accent, 64, value);
  else if (!strcasecmp(trim(key), "bar_border_color")) copystr(bar_border_color, 64, value);
  else if (!strcasecmp(trim(key), "bar_font")) copystr(bar_font_name, 96, value);
  else if (!strcasecmp(trim(key), "workspace_border_color")) copystr(workspace_border_color, 64, value);
  else if (!strcasecmp(trim(key), "workspace_active_border")) copystr(workspace_active_border, 64, value);
  else if (!strcasecmp(trim(key), "workspace_active_bg")) copystr(workspace_active_bg, 64, value);
  else if (!strcasecmp(trim(key), "workspace_fg")) copystr(workspace_fg, 64, value);
  else if (!strcasecmp(trim(key), "workspace_active_fg")) copystr(workspace_active_fg, 64, value);
}

U0 read_config_file(U8 *path)
{
  U8 *file = fopen(path, "r");
  U8 line[512];
  U8 *p;
  if (!file) return;
  while (fgets(line, 512, file)) {
    p = trim(line);
    if (!*p || *p == '#') continue;
    if (!strncasecmp(p, "bind", 4)) parse_bind(p);
    else parse_scalar(p);
  }
  fclose(file);
}

U0 load_config()
{
  U8 *home;
  U8 *xdg;
  U8 *custom;
  U8 *default_config;
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
  } else {
    xdg = getenv("XDG_CONFIG_HOME");
    home = getenv("HOME");
    if (xdg && *xdg) {
      copystr(path, 512, xdg);
      if (StrLen(path) < 500) StrCpy(path + StrLen(path), "/lhwm/lhwm.conf");
    } else if (home && *home) {
      copystr(path, 512, home);
      if (StrLen(path) < 500) StrCpy(path + StrLen(path), "/.config/lhwm/lhwm.conf");
    } else {
      copystr(path, 512, "./lhwm.conf");
    }
    read_config_file(path);
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

U0 arrange()
{
  I64 pos;
  I64 index;
  I64 count = visible_count();
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
  if (count <= 0) {
    selected = -1;
    if (bar_window) XRaiseWindow(dpy, bar_window);
    XFlush(dpy);
    return;
  }
  if (mode == MODE_FLOATING) {
    for (pos = 0; pos < count; pos++) {
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
  usable_w = screen_w - (2 * gap);
  usable_h = screen_h - top - (2 * gap);
  if (usable_w < 100) usable_w = 100;
  if (usable_h < 80) usable_h = 80;
  if (layout == LAYOUT_MONOCLE) {
    for (pos = 0; pos < count; pos++) {
      index = visible_client_at(pos);
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
      index = visible_client_at(pos);
      if (pos == count - 1) this_w = screen_w - gap - x;
      XSetWindowBorderWidth(dpy, clients[index].win, border_width);
      XSetWindowBorder(dpy, clients[index].win, border_pixel_for(index));
      set_client_geometry(index, x, top + gap,
          this_w - 2 * border_width, usable_h - 2 * border_width);
      x += col_w;
    }
  } else if (count == 1) {
    index = visible_client_at(0);
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
    index = visible_client_at(0);
    XSetWindowBorderWidth(dpy, clients[index].win, border_width);
    XSetWindowBorder(dpy, clients[index].win, border_pixel_for(index));
    set_client_geometry(index, gap, top + gap,
        master_w - 2 * border_width, usable_h - 2 * border_width);
    y = top + gap;
    for (pos = 1; pos < count; pos++) {
      I64 this_h = base_h;
      index = visible_client_at(pos);
      if (pos == count - 1) this_h += extra_h;
      XSetWindowBorderWidth(dpy, clients[index].win, border_width);
      XSetWindowBorder(dpy, clients[index].win, border_pixel_for(index));
      set_client_geometry(index, gap + master_w + gap, y,
          stack_w - 2 * border_width, this_h - 2 * border_width);
      y += this_h + gap;
    }
  }
  if (selected >= 0 && selected < nclients && clients[selected].workspace == current_workspace && layout != LAYOUT_MONOCLE)
    XRaiseWindow(dpy, clients[selected].win);
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

U0 manage(U64 win)
{
  XWindowAttributes wa;
  I64 i;
  if (client_index(win) >= 0 || nclients >= MAX_CLIENTS) return;
  if (!XGetWindowAttributes(dpy, win, &wa) || wa.override_redirect) return;
  if (wa.map_state == IsViewable && wa.width <= 1 && wa.height <= 1) return;
  i = nclients;
  clients[i].win = win;
  clients[i].x = wa.x;
  clients[i].y = wa.y;
  clients[i].w = wa.width;
  clients[i].h = wa.height;
  clients[i].workspace = current_workspace;
  clients[i].mapped = 1;
  clients[i].ignore_unmap = 0;
  nclients++;
  // ButtonPressMask is exclusive: if the application already selected it, the
  // whole request fails with BadAccess and EnterWindowMask would be lost too.
  // Mod4 clicks reach us through the passive grabs below instead.
  XSelectInput(dpy, win, StructureNotifyMask | EnterWindowMask);
  grab_window_buttons(win);
  XSetWindowBorderWidth(dpy, win, border_width);
  XMapWindow(dpy, win);
  if (mode == MODE_FLOATING) {
    I64 offset = (i % 7) * 24;
    I32 w = screen_w * 70 / 100;
    I32 h = screen_h * 70 / 100;
    clients[i].x = (screen_w - w) / 2 + offset;
    clients[i].y = bar_offset() + (screen_h - bar_offset() - h) / 2 + offset;
    clients[i].w = w;
    clients[i].h = h;
    XMoveResizeWindow(dpy, win, clients[i].x, clients[i].y, w, h);
  }
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
  if (drag_mode) return;
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
      if (i >= 0 && mode == MODE_TILING) arrange();
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
