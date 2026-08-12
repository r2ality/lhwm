// holywm — a BSP tiling window manager for X11, written in HolyC.
// Fork of nvwm (github.com/Vifuddyxg/nvwm) rebuilt in HolyC; compiled with
// the holyc-lang hcc compiler and linked directly against Xlib. Terry would
// have wanted a window manager eventually.

#include "xlib.HH"

#define MOD          Mod4Mask
#define MAXBINDS     128
#define MAXMODEBINDS 24
#define MAXCMDS      16
#define MAXRULES     32
#define MAXMONS      8
#define MAXWS        500   /* hard cap (array size); active count is numws */
#define MAXAUTOSTART 8
#define MAXDOCKS     16
#define MAXTRAYICONS 16
#define CMDLINE_MAX  256
#define PATH_MAX     4096

/* XEmbed system tray (freedesktop System Tray spec) */
#define SYSTEM_TRAY_REQUEST_DOCK 0
#define XEMBED_EMBEDDED_NOTIFY   0

#define BAR_TOP    0
#define BAR_BOTTOM 1

#define MODE_INSERT  0
#define MODE_NORMAL  1
#define MODE_COMMAND 2

class Node
{
  I64 leaf;
  I64 floating;
  I64 horiz;
  I64 fullscreen;
  I64 real_fullscreen;
  I64 ignore_unmap;
  F64 ratio;
  Node *a;
  Node *b;
  Node *par;
  U64 win;
  I64 x;
  I64 y;
  I64 w;
  I64 h;
  U64 thumb;          /* WM-owned snapshot of window contents, 0 if none */
  I64 thumb_w;
  I64 thumb_h;
};

class ModBind
{
  U32 mod;
  U8 code;
  U8 action[128];
};

class ModeBind
{
  U64 sym;
  U8 action[128];
};

class CmdBind
{
  U8 name[64];
  U8 action[128];
};

class Rule
{
  U8 class_name[64];
  U8 instance_name[64];
  U8 title[128];
  I64 set_floating;
  I64 floating;
  I64 workspace;
  I64 follow_class;
};

class Mon
{
  I64 x;
  I64 y;
  I64 w;
  I64 h;
  I64 wx;
  I64 wy;
  I64 ww;
  I64 wh;
  I64 curws;
  Node *tree[MAXWS];
  Node *focused[MAXWS];
  U64 barwin;
  U64 barpix;
};

I64 numws;   /* active workspaces, configurable: 1..MAXWS */
I64 gap;
I64 bw;
I64 barh;
I64 barenabled;
I64 externalbarh;
I64 barpadx;
I64 baritemgap;
I64 bartextpad;
I64 barwsminw;
U64 cfocus;
U64 cnorm;
U64 barbg;
U64 barfg;
U64 baraccentbg;
U64 baraccentfg;
U64 barmutedfg;
U8 term[128];
U8 barfontname[128];
U8 barleftcfg[128];
U8 barcentercfg[128];
U8 barrightcfg[128];
I64 screen_off_minutes;
/* Pointer warps generate synthetic motion.  Keep them off by default so an
   X11 game never sees a workspace/focus change as mouse movement. */
I64 warp_pointer;
I64 barpos;
U8 *dpy;
U64 root;
I64 sw;
I64 sh;
Mon mons[MAXMONS];
I64 nmons;
I64 curmon;
I64 randr_active;
I32 randr_event_base;
/* auto-enable connected-but-disabled monitors out of the box (config: auto_monitors) */
I64 auto_monitors;
/* command run after the monitor layout changes -- e.g. to re-apply the wallpaper,
   which X invalidates on every framebuffer resize (config: monitor_hook) */
U8 monitor_hook[256];
/* index of the monitor whose bar is currently being drawn (per-monitor curws) */
I64 barmon;
/* workspace overview (Super+Z) state */
I64 overview_active;
I64 overview_sel;
I64 overview_mon;
U64 overview_win;
U64 overview_pix;
/* XComposite + XRender: present and redirect active -> live thumbnails */
I64 composite_ok;
I64 redirect_done;   /* the one-time subwindow redirect has been resolved */
/* compositor mode (config: compositor): 0=auto, 1=on (always redirect), 2=off (never) */
I64 compositor_mode;
/* drag-to-move inside the overview */
I64 ov_drag;             /* a press is in progress */
Node *ov_drag_node;      /* leaf being dragged, NULL if empty-cell press */
I64 ov_drag_ws;          /* workspace the press started on */
I64 ov_press_rx;         /* press point (root coords) */
I64 ov_press_ry;
I64 ov_ptr_x;            /* current pointer (monitor-local) */
I64 ov_ptr_y;
I64 ov_moved;            /* moved past click threshold */
U64 wmcheckwin;
ModBind modbinds[MAXBINDS];
I64 nmodbinds;
ModeBind normalbinds[MAXMODEBINDS];
I64 nnormalbinds;
CmdBind cmdbinds[MAXCMDS];
I64 ncmdbinds;
Rule rules[MAXRULES];
I64 nrules;
U64 dockwins[MAXDOCKS];
I64 ndockwins;
U8 autostart_cmds[MAXAUTOSTART][256];
I64 nautostart;
I64 modbind_limit;
I64 normalbind_limit;
I64 cmd_limit;
I64 autostart_limit;
U8 *bargc;
XFontStruct *barfont;
U64 normalcursor;
U64 movecursor;
U64 resizecursor;
I64 mode;
I64 keyboard_grabbed;
I64 running;
U32 numlockmask;
U64 atom_net_active_window;
U64 atom_net_client_list;
U64 atom_net_current_desktop;
U64 atom_net_num_desktops;
U64 atom_net_supported;
U64 atom_net_wm_check;
U64 atom_utf8_string;
U64 atom_net_wm_wtype;
U64 atom_wtype_dock;
U64 atom_wtype_dialog;
U64 atom_wtype_utility;
U64 atom_wtype_toolbar;
U64 atom_wtype_splash;
U64 atom_net_wm_desktop;
U64 atom_net_wm_state;
U64 atom_net_wm_state_fs;
U64 atom_net_wm_name;
U64 atom_net_wm_strut;
U64 atom_net_wm_strut_part;
U64 atom_wm_protocols;
U64 atom_wm_delete_window;
U64 atom_net_wm_pid;
U64 atom_net_system_tray;
U64 atom_tray_opcode;
U64 atom_tray_orient;
U64 atom_xembed;
U64 atom_manager;
/* system tray: icons dock into the bar of monitor `traymon` (the primary) */
U64 trayicons[MAXTRAYICONS];
I64 ntrayicons;
U64 trayselwin;      /* persistent _NET_SYSTEM_TRAY_S<n> selection owner */
I64 traymon;
I64 tray_draw_x;     /* bar-local x of the tray slot, set while drawing */
U8 cached_title[256];
U8 cmdline[CMDLINE_MAX];
I64 cmdline_len;
U8 timestr[32];
U8 batterystr[64];
I64 last_clock_second;
I64 last_battery_update;   /* was a function-local static in the C original */
I64 drag_mode;
I64 drag_mon;
I64 drag_ox;
I64 drag_oy;
I32 drag_wx;
I32 drag_wy;
I64 drag_ww;
I64 drag_wh;
Node *drag_node;

U0 init_globals()
{ /* the C original's non-zero static initializers */
  numws = 9;
  gap = 8; bw = 2; barh = 24; barenabled = 1;
  barpadx = 10; baritemgap = 6; bartextpad = 8; barwsminw = 20;
  cfocus = 0x5588ff; cnorm = 0x333333;
  barbg = 0x111111; barfg = 0xeeeeee;
  baraccentbg = 0x5588ff; baraccentfg = 0x111111;
  barmutedfg = 0xaaaaaa;
  StrCpy(term, "st");
  StrCpy(barfontname, "9x15");
  StrCpy(barleftcfg, "workspaces");
  StrCpy(barcentercfg, "command");
  StrCpy(barrightcfg, "clock");
  barpos = BAR_TOP;
  nmons = 1;
  randr_event_base = -1;
  auto_monitors = 1;
  ov_drag_ws = -1;
  tray_draw_x = -1;
  last_clock_second = -1;
  mode = MODE_INSERT;
  running = 1;
  modbind_limit = MAXBINDS;
  normalbind_limit = MAXMODEBINDS;
  cmd_limit = MAXCMDS;
  autostart_limit = MAXAUTOSTART;
}

/* ---- prototypes (mirrors the C original's forward declarations) ---- */
U0 drawbars();
U0 update_clock();
U0 update_battery();
U0 setupbars();
U0 enter_mode(I64 newmode);
Node *mon_focused(I64 mi);
U0 showtree(Node *n);
U0 hidetree(Node *n);
U0 close_overview();
U0 capture_thumb(Node *n);
U0 capture_tree(Node *n);
U0 free_thumb(Node *n);
U0 init_composite();
U0 spawn(U8 *cmd);
U0 initatoms();
U0 apply_rules(Node *n, I64 *targetws, I64 *out_follow);
U0 update_client_list();
U0 update_current_desktop();
U0 update_num_desktops();
U0 update_active_window();
U0 set_window_desktop(U64 win, I64 ws);
U0 update_supported_atoms();
U0 setup_wm_check();
U0 reloadwm();
U0 collect_leaves(Node *n, Node **list, I64 *count, I64 maxcount);
U0 free_tree(Node *n);
I64 querygeom(Mon *out, I64 max);
I64 updategeom();
U0 retile();
U0 setfocus(I64 mi, Node *n, I64 warp);
U0 attach_to_ws(I64 mi, I64 ws, Node *leaf);
U0 wait_event_or_tick();
U0 apply_screen_off_config();
U0 close_window(U64 win);
U0 destroybars();
U0 compute_dock_struts(I64 *out_top, I64 *out_bottom);
U0 sync_dock_stack();
Node *find_real_fs_leaf(Node *n);
I64 bar_uses_item(U8 *item);
U0 setup_tray();
U0 tray_release_icons();
U0 draw_overview();
U0 loadcfg();
U0 updatenumlockmask();
U0 grab_mod_binds();
U0 scandocks();
U0 switch_workspace_on(I64 mi, I64 ws);
I64 apply_wm_action(U8 *action);

public I32 xerr(U8 *d, XErrorEvent *e)
{
  return 0;
}

U64 hcol(U8 *s)
{ /* strtoul(s, NULL, 16): parse hex until the first non-hex char */
  U64 v = 0;
  if (*s == '#') s++;
  while (*s) {
    U8 c = *s;
    if (c >= '0' && c <= '9') v = v * 16 + c - '0';
    else if (c >= 'a' && c <= 'f') v = v * 16 + c - 'a' + 10;
    else if (c >= 'A' && c <= 'F') v = v * 16 + c - 'A' + 10;
    else break;
    s++;
  }
  return v;
}

U8 *ltrim(U8 *s)
{
  while (*s == ' ' || *s == '\t') s++;
  return s;
}

U0 rtrim(U8 *s)
{
  I64 len = StrLen(s);
  while (len && (s[len - 1] == '\n' || s[len - 1] == '\r' ||
                 s[len - 1] == ' ' || s[len - 1] == '\t')) {
    len--;
    s[len] = 0;
  }
}

U0 copystr(U8 *dst, I64 dstsz, U8 *src)
{
  I64 n;
  if (!dstsz) return;
  if (!src) src = "";
  n = StrLen(src);
  if (n >= dstsz) n = dstsz - 1;
  MemCpy(dst, src, n);
  dst[n] = 0;
}

/* bounded append; StrPrint's %s path is unusable on fixed buffers (the
   holyc-lang runtime MSize/ReAllocs the destination as if heap-allocated) */
U0 stradd(U8 *dst, U8 *src)
{
  StrCpy(dst + StrLen(dst), src);
}

U8 *skip_command_prefix(U8 *s)
{
  if (s && s[0] == ':') return s + 1;
  return s;
}

/* strtok_r(s, ",", &save) workalike: skips empty fields, NUL-terminates */
U8 *tok_comma(U8 **save)
{
  U8 *s = *save;
  U8 *e;
  if (!s) return NULL;
  while (*s == ',') s++;
  if (!*s) {
    *save = NULL;
    return NULL;
  }
  e = strchr(s, ',');
  if (e) {
    *e = 0;
    *save = e + 1;
  } else {
    *save = NULL;
  }
  return s;
}

U64 parse_keysym_name(U8 *name)
{
  U8 lowered[64];
  I64 len;
  I64 i;
  U64 sym;

  if (!name) return NoSymbol;
  if (!*name) return NoSymbol;
  if (!StrCmp(name, " ")) return XK_space;

  len = StrLen(name);
  if (len >= 64) len = 63;
  for (i = 0; i < len; i++) {
    U8 c = name[i];
    if (c >= 'A' && c <= 'Z') lowered[i] = c - 'A' + 'a';
    else lowered[i] = c;
  }
  lowered[len] = 0;

  if (!StrCmp(lowered, "space")) return XK_space;
  if (!StrCmp(lowered, "return") || !StrCmp(lowered, "enter")) return XK_Return;
  if (!StrCmp(lowered, "escape") || !StrCmp(lowered, "esc")) return XK_Escape;
  if (!StrCmp(lowered, "page_up") || !StrCmp(lowered, "pageup") || !StrCmp(lowered, "prior"))
    return XK_Page_Up;
  if (!StrCmp(lowered, "page_down") || !StrCmp(lowered, "pagedown") || !StrCmp(lowered, "next"))
    return XK_Page_Down;
  if (!StrCmp(lowered, "left")) return XK_Left;
  if (!StrCmp(lowered, "right")) return XK_Right;
  if (!StrCmp(lowered, "up")) return XK_Up;
  if (!StrCmp(lowered, "down")) return XK_Down;
  if (!StrCmp(lowered, "tab")) return XK_Tab;
  if (!StrCmp(lowered, "backspace")) return XK_BackSpace;
  if (!StrCmp(lowered, "xf86audioraisevolume")) return XF86XK_AudioRaiseVolume;
  if (!StrCmp(lowered, "xf86audiolowervolume")) return XF86XK_AudioLowerVolume;
  if (!StrCmp(lowered, "xf86audiomute")) return XF86XK_AudioMute;
  if (!StrCmp(lowered, "xf86audioplay")) return XF86XK_AudioPlay;
  if (!StrCmp(lowered, "xf86audiopause")) return XF86XK_AudioPause;
  if (!StrCmp(lowered, "xf86audionext")) return XF86XK_AudioNext;
  if (!StrCmp(lowered, "xf86audioprev")) return XF86XK_AudioPrev;
  if (!StrCmp(lowered, "xf86audiostop")) return XF86XK_AudioStop;
  if (!StrCmp(lowered, "xf86monbrightnessup")) return XF86XK_MonBrightnessUp;
  if (!StrCmp(lowered, "xf86monbrightnessdown")) return XF86XK_MonBrightnessDown;

  sym = XStringToKeysym(name);
  if (sym == NoSymbol) sym = XStringToKeysym(lowered);
  if (sym == NoSymbol && StrLen(name) == 1) sym = name[0];
  return sym;
}

I64 textw(U8 *s)
{
  I64 len;
  I64 w;
  if (!s) return 0;
  len = StrLen(s);
  if (!barfont) return len * 8;
  w = XTextWidth(barfont, s, len);
  if (w) return w;
  return len * 8;
}

U0 build_mode_text(U8 *dst, I64 dstsz)
{
  U8 *label;
  if (mode == MODE_INSERT) label = "INSERT";
  else if (mode == MODE_NORMAL) label = "NORMAL";
  else label = "COMMAND";
  copystr(dst, dstsz, label);
}

I64 clampi(I64 value, I64 minv, I64 maxv)
{
  if (value < minv) return minv;
  if (value > maxv) return maxv;
  return value;
}

I64 parse_bool_value(U8 *v, I64 fallback)
{
  if (!v) return fallback;
  if (!strcasecmp(v, "1") || !strcasecmp(v, "true") ||
      !strcasecmp(v, "yes") || !strcasecmp(v, "on")) return 1;
  if (!strcasecmp(v, "0") || !strcasecmp(v, "false") ||
      !strcasecmp(v, "no") || !strcasecmp(v, "off")) return 0;
  return fallback;
}

I64 get_window_strut(U64 win, I64 *out_top, I64 *out_bottom)
{
  U64 actual_type;
  I32 actual_format;
  U64 nitems;
  U64 bytes_after;
  U8 *data = NULL;
  I64 *ldata;

  *out_top = 0;
  *out_bottom = 0;
  if (XGetWindowProperty(dpy, win, atom_net_wm_strut_part, 0, 12, False,
        XA_CARDINAL, &actual_type, &actual_format, &nitems, &bytes_after,
        &data) == Success && data && nitems >= 4) {
    ldata = data(I64 *);
    *out_top = ldata[2];
    *out_bottom = ldata[3];
    XFree(data);
    return 1;
  }
  if (data) {
    XFree(data);
    data = NULL;
  }
  if (XGetWindowProperty(dpy, win, atom_net_wm_strut, 0, 4, False,
        XA_CARDINAL, &actual_type, &actual_format, &nitems, &bytes_after,
        &data) == Success && data && nitems >= 4) {
    ldata = data(I64 *);
    *out_top = ldata[2];
    *out_bottom = ldata[3];
    XFree(data);
    return 1;
  }
  if (data) XFree(data);
  return 0;
}

U0 compute_dock_struts(I64 *out_top, I64 *out_bottom)
{
  I64 i;
  *out_top = 0;
  *out_bottom = 0;
  for (i = 0; i < ndockwins; i++) {
    I64 t = 0;
    I64 b = 0;
    XWindowAttributes wa;
    if (get_window_strut(dockwins[i], &t, &b)) {
      if (t > *out_top) *out_top = t;
      if (b > *out_bottom) *out_bottom = b;
      continue;
    }
    if (!XGetWindowAttributes(dpy, dockwins[i], &wa)) continue;
    if (wa.map_state == IsUnmapped) continue;
    if (wa.y + wa.height <= sh / 2) {
      if (wa.height > *out_top) *out_top = wa.height;
    } else {
      if (wa.height > *out_bottom) *out_bottom = wa.height;
    }
  }
  *out_top = clampi(*out_top, 0, 256);
  *out_bottom = clampi(*out_bottom, 0, 256);
}

I64 get_window_title(U64 win, U8 *dst, I64 dstsz)
{
  XTextProperty prop;
  /* hcc bug: `&local` compiles to the local's VALUE for typed-pointer locals
     (U64*, U8**, ...); only U8* and class-pointer locals work. Out-params that
     return a pointer therefore go through a U8* + postfix cast. */
  U8 *listraw = NULL;
  U8 **list = NULL;
  I32 count = 0;
  I64 ok;

  dst[0] = 0;
  if (XGetTextProperty(dpy, win, &prop, atom_net_wm_name) && prop.value && prop.nitems > 0) {
    if (prop.encoding == atom_utf8_string) {
      copystr(dst, dstsz, prop.value);
      XFree(prop.value);
      return dst[0] != 0;
    }
    ok = XmbTextPropertyToTextList(dpy, &prop, &listraw, &count);
    list = listraw(U8 **);
    if (ok >= Success && count > 0 && list && list[0])
      copystr(dst, dstsz, list[0]);
    if (ok >= Success && list) XFreeStringList(list);
    XFree(prop.value);
    listraw = NULL;
    list = NULL;
    if (dst[0]) return 1;
  }

  if (XGetWMName(dpy, win, &prop) && prop.value && prop.nitems > 0) {
    ok = XmbTextPropertyToTextList(dpy, &prop, &listraw, &count);
    list = listraw(U8 **);
    if (ok >= Success && count > 0 && list && list[0])
      copystr(dst, dstsz, list[0]);
    if (ok >= Success && list) XFreeStringList(list);
    XFree(prop.value);
    if (dst[0]) return 1;
  }
  return 0;
}

I64 get_window_class(U64 win, U8 *class_name, I64 class_sz,
    U8 *instance_name, I64 instance_sz)
{
  XClassHint hint;
  class_name[0] = 0;
  instance_name[0] = 0;
  if (!XGetClassHint(dpy, win, &hint)) return 0;
  if (hint.res_class) {
    copystr(class_name, class_sz, hint.res_class);
    XFree(hint.res_class);
  }
  if (hint.res_name) {
    copystr(instance_name, instance_sz, hint.res_name);
    XFree(hint.res_name);
  }
  return class_name[0] || instance_name[0];
}

I64 window_has_atom(U64 win, U64 prop, U64 value)
{
  U64 actual_type;
  I32 actual_format;
  U64 nitems;
  U64 bytes_after;
  U8 *data = NULL;
  U64 *atoms;
  I64 found = 0;
  I64 i;
  if (XGetWindowProperty(dpy, win, prop, 0, 32, False, XA_ATOM,
        &actual_type, &actual_format, &nitems, &bytes_after,
        &data) != Success) return 0;
  atoms = data(U64 *);
  if (actual_type == XA_ATOM && actual_format == 32 && atoms) {
    for (i = 0; i < nitems; i++) {
      if (atoms[i] == value) {
        found = 1;
        break;
      }
    }
  }
  if (data) XFree(data);
  return found;
}

U0 refresh_cached_title()
{
  Node *n = mon_focused(curmon);
  cached_title[0] = 0;
  if (n && n->leaf) get_window_title(n->win, cached_title, 256);
}

U0 build_title_text(U8 *dst, I64 dstsz)
{
  copystr(dst, dstsz, cached_title);
}

U0 build_clock_text(U8 *dst, I64 dstsz)
{
  update_clock();
  if (timestr[0]) copystr(dst, dstsz, timestr);
  else copystr(dst, dstsz, "--:--");
}

U0 build_battery_text(U8 *dst, I64 dstsz)
{
  update_battery();
  copystr(dst, dstsz, batterystr);
}

U0 update_clock()
{
  I64 now = time(NULL);
  Tm tm_now;
  localtime_r(&now, &tm_now);
  if (tm_now.tm_sec == last_clock_second) return;
  last_clock_second = tm_now.tm_sec;
  StrPrint(timestr, "%02d:%02d", tm_now.tm_hour, tm_now.tm_min);
}

U0 update_battery()
{
  I64 now = time(NULL);
  U8 *bases[4];
  U8 path[256];
  U8 status[32];
  U8 cap[32];
  U8 *f;
  I64 i;

  bases[0] = "/sys/class/power_supply/BAT0";
  bases[1] = "/sys/class/power_supply/BAT1";
  bases[2] = "/sys/class/power_supply/battery";
  bases[3] = NULL;

  if (last_battery_update && now - last_battery_update < 15) return;
  last_battery_update = now;
  batterystr[0] = 0;

  for (i = 0; bases[i]; i++) {
    StrCpy(path, bases[i]);
    stradd(path, "/capacity");
    f = fopen(path, "r");
    if (!f) continue;
    if (!fgets(cap, 32, f)) {
      fclose(f);
      continue;
    }
    fclose(f);
    rtrim(cap);

    StrCpy(path, bases[i]);
    stradd(path, "/status");
    f = fopen(path, "r");
    if (f && fgets(status, 32, f)) {
      fclose(f);
      rtrim(status);
    } else {
      if (f) fclose(f);
      status[0] = 0;
    }

    if (!strcasecmp(status, "Charging")) StrCpy(batterystr, "BAT+ ");
    else if (!strcasecmp(status, "Full")) StrCpy(batterystr, "BAT= ");
    else StrCpy(batterystr, "BAT ");
    stradd(batterystr, cap);
    stradd(batterystr, "%");
    return;
  }
}

/* ---- XEmbed system tray ----
   holywm owns the _NET_SYSTEM_TRAY_S<screen> selection; apps that minimize to
   a tray (nm-applet, telegram, discord, ...) dock their icon window here and
   it is reparented into the bar. Clicks land on the icon's own window, so the
   app's tray menu -- including its Quit entry -- works natively. */

I64 tray_icon_size()
{
  I64 s = barh - 6;
  if (s < 8) return 8;
  return s;
}

I64 tray_index(U64 win)
{
  I64 i;
  for (i = 0; i < ntrayicons; i++)
    if (trayicons[i] == win) return i;
  return -1;
}

I64 tray_width()
{
  if (!ntrayicons) return 0;
  return ntrayicons * tray_icon_size() + (ntrayicons - 1) * baritemgap;
}

/* park icons off-screen when the tray slot was not drawn this pass */
U0 tray_layout_icons()
{
  I64 sz = tray_icon_size();
  I64 y = (barh - sz) / 2;
  I64 x = tray_draw_x;
  I64 i;
  if (!ntrayicons || traymon >= nmons || !mons[traymon].barwin) return;
  if (x < 0) x = -(sz + baritemgap) * ntrayicons;
  for (i = 0; i < ntrayicons; i++) {
    XMoveResizeWindow(dpy, trayicons[i], x, y, sz, sz);
    x += sz + baritemgap;
  }
}

U0 tray_dock_icon(U64 win)
{
  XEvent ev;
  if (!win || tray_index(win) >= 0 || ntrayicons >= MAXTRAYICONS) return;
  if (traymon >= nmons || !mons[traymon].barwin) return;
  trayicons[ntrayicons] = win;
  ntrayicons++;
  XSelectInput(dpy, win, StructureNotifyMask);
  XReparentWindow(dpy, win, mons[traymon].barwin, 0, 0);
  XSetWindowBackground(dpy, win, barbg);
  MemSet(&ev, 0, sizeof(XEvent));
  ev.xclient.type = ClientMessage;
  ev.xclient.window = win;
  ev.xclient.message_type = atom_xembed;
  ev.xclient.format = 32;
  ev.xclient.l[0] = CurrentTime;
  ev.xclient.l[1] = XEMBED_EMBEDDED_NOTIFY;
  ev.xclient.l[3] = mons[traymon].barwin;
  XSendEvent(dpy, win, False, NoEventMask, &ev);
  XMapWindow(dpy, win);
  drawbars();
}

U0 tray_remove_icon(U64 win)
{
  I64 idx = tray_index(win);
  if (idx < 0) return;
  memmove(&trayicons[idx], &trayicons[idx + 1],
      (ntrayicons - idx - 1) * sizeof(U64));
  ntrayicons--;
  drawbars();
}

/* hand every icon back to the root window and drop the tray selection; used
   before the bar window is destroyed (icons are its children and would die
   with it) and on exit. Re-acquiring later broadcasts MANAGER again, so tray
   apps re-dock on their own. */
U0 tray_release_icons()
{
  I64 i;
  for (i = 0; i < ntrayicons; i++) {
    XSelectInput(dpy, trayicons[i], NoEventMask);
    XUnmapWindow(dpy, trayicons[i]);
    XReparentWindow(dpy, trayicons[i], root, 0, 0);
  }
  ntrayicons = 0;
  tray_draw_x = -1;
  if (trayselwin) {
    XDestroyWindow(dpy, trayselwin);
    trayselwin = 0;
  }
}

U0 setup_tray()
{
  XEvent ev;
  if (!barenabled || !bar_uses_item("tray")) return;
  if (!trayselwin) {
    U64 orient = 0;   /* horizontal */
    U8 *op = &orient;
    trayselwin = XCreateSimpleWindow(dpy, root, -1, -1, 1, 1, 0, 0, 0);
    XChangeProperty(dpy, trayselwin, atom_tray_orient,
        XA_CARDINAL, 32, PropModeReplace, op, 1);
  }
  if (XGetSelectionOwner(dpy, atom_net_system_tray) == trayselwin) return;
  XSetSelectionOwner(dpy, atom_net_system_tray, trayselwin, CurrentTime);
  if (XGetSelectionOwner(dpy, atom_net_system_tray) != trayselwin) return;
  /* announce the new tray so running apps dock their icons */
  MemSet(&ev, 0, sizeof(XEvent));
  ev.xclient.type = ClientMessage;
  ev.xclient.window = root;
  ev.xclient.message_type = atom_manager;
  ev.xclient.format = 32;
  ev.xclient.l[0] = CurrentTime;
  ev.xclient.l[1] = atom_net_system_tray;
  ev.xclient.l[2] = trayselwin;
  XSendEvent(dpy, root, False, StructureNotifyMask, &ev);
}

I64 monforpt(I64 x, I64 y)
{
  I64 i;
  for (i = 0; i < nmons; i++) {
    if (x >= mons[i].x && x < mons[i].x + mons[i].w &&
        y >= mons[i].y && y < mons[i].y + mons[i].h) return i;
  }
  return 0;
}

Node *mon_tree(I64 mi)
{
  return mons[mi].tree[mons[mi].curws];
}

Node *mon_focused(I64 mi)
{
  return mons[mi].focused[mons[mi].curws];
}

Node *mon_tree_at(I64 mi, I64 ws)
{
  return mons[mi].tree[ws];
}

Node *mon_focused_at(I64 mi, I64 ws)
{
  return mons[mi].focused[ws];
}

U0 mon_setfocused(I64 mi, Node *n)
{
  mons[mi].focused[mons[mi].curws] = n;
}

U0 mon_settree_at(I64 mi, I64 ws, Node *n)
{
  mons[mi].tree[ws] = n;
}

U0 mon_setfocused_at(I64 mi, I64 ws, Node *n)
{
  mons[mi].focused[ws] = n;
}

Node *mkleaf(U64 w)
{
  Node *n = CAlloc(sizeof(Node));
  n->leaf = 1;
  n->ratio = 0.5;
  n->win = w;
  return n;
}

I64 atom_in_window_property(U64 win, U64 prop, U64 value)
{
  return window_has_atom(win, prop, value);
}

I64 window_is_dialog_like(U64 win)
{
  U64 transient_for;
  if (XGetTransientForHint(dpy, win, &transient_for)) return 1;
  return atom_in_window_property(win, atom_net_wm_wtype, atom_wtype_dialog) ||
         atom_in_window_property(win, atom_net_wm_wtype, atom_wtype_utility) ||
         atom_in_window_property(win, atom_net_wm_wtype, atom_wtype_toolbar) ||
         atom_in_window_property(win, atom_net_wm_wtype, atom_wtype_splash);
}

I64 window_is_dock(U64 win)
{
  return atom_in_window_property(win, atom_net_wm_wtype, atom_wtype_dock);
}

I64 dock_index(U64 win)
{
  I64 i;
  for (i = 0; i < ndockwins; i++) {
    if (dockwins[i] == win) return i;
  }
  return -1;
}

U0 add_dock_window(U64 win)
{
  if (!win || dock_index(win) >= 0 || ndockwins >= MAXDOCKS) return;
  dockwins[ndockwins] = win;
  ndockwins++;
}

U0 remove_dock_window(U64 win)
{
  I64 idx = dock_index(win);
  if (idx < 0) return;
  ndockwins--;
  dockwins[idx] = dockwins[ndockwins];
  dockwins[ndockwins] = 0;
}

I64 any_real_fs_visible()
{
  I64 i;
  for (i = 0; i < nmons; i++) {
    if (find_real_fs_leaf(mon_tree(i))) return 1;
  }
  return 0;
}

U0 sync_dock_stack()
{
  I64 hide_for_fullscreen = any_real_fs_visible();
  I64 i;
  for (i = 0; i < ndockwins; i++) {
    if (hide_for_fullscreen) XLowerWindow(dpy, dockwins[i]);
    else XRaiseWindow(dpy, dockwins[i]);
  }
}

Node *findleaf(Node *n, U64 w)
{
  Node *r;
  if (!n) return NULL;
  if (n->leaf) {
    if (n->win == w) return n;
    return NULL;
  }
  r = findleaf(n->a, w);
  if (r) return r;
  return findleaf(n->b, w);
}

Node *findleaf_any(U64 w, I64 *out_mi, I64 *out_ws)
{
  I64 mi;
  I64 ws;
  for (mi = 0; mi < nmons; mi++) {
    for (ws = 0; ws < numws; ws++) {
      Node *n = findleaf(mon_tree_at(mi, ws), w);
      if (n) {
        if (out_mi) *out_mi = mi;
        if (out_ws) *out_ws = ws;
        return n;
      }
    }
  }
  return NULL;
}

I64 monforwin(U64 w)
{
  I64 i;
  for (i = 0; i < nmons; i++) {
    if (findleaf(mon_tree(i), w)) return i;
  }
  return curmon;
}

Node *firstleaf(Node *n)
{
  while (n && !n->leaf) n = n->a;
  return n;
}

Node *find_fullscreen_leaf(Node *n)
{
  Node *r;
  if (!n) return NULL;
  if (n->leaf) {
    if (n->real_fullscreen || n->fullscreen) return n;
    return NULL;
  }
  r = find_fullscreen_leaf(n->a);
  if (r) return r;
  return find_fullscreen_leaf(n->b);
}

Node *find_real_fs_leaf(Node *n)
{
  Node *r;
  if (!n) return NULL;
  if (n->leaf) {
    if (n->real_fullscreen) return n;
    return NULL;
  }
  r = find_real_fs_leaf(n->a);
  if (r) return r;
  return find_real_fs_leaf(n->b);
}

Node *nextleaf(I64 mi, Node *cur)
{
  Node *tree = mon_tree(mi);
  Node *n;
  if (!cur || !tree) return firstleaf(tree);
  n = cur;
  while (n->par) {
    if (n->par->a == n) {
      Node *r = firstleaf(n->par->b);
      if (r) return r;
    }
    n = n->par;
  }
  return firstleaf(tree);
}

Node *prevleaf(I64 mi, Node *cur)
{
  Node *tree = mon_tree(mi);
  Node *prev = NULL;
  Node *n;
  if (!tree) return NULL;
  if (!cur) {
    n = firstleaf(tree);
    if (!n) return NULL;
    n = nextleaf(mi, n);
    while (n && n != firstleaf(tree)) {
      prev = n;
      n = nextleaf(mi, n);
    }
    if (prev) return prev;
    return firstleaf(tree);
  }
  n = firstleaf(tree);
  while (n) {
    if (n == cur) break;
    prev = n;
    n = nextleaf(mi, n);
    if (n == firstleaf(tree)) break;
  }
  if (prev) return prev;
  n = firstleaf(tree);
  prev = n;
  n = nextleaf(mi, prev);
  while (n && n != firstleaf(tree)) {
    prev = n;
    n = nextleaf(mi, prev);
  }
  return prev;
}

U0 swap_leaf_payload(Node *a, Node *b)
{
  U64 wtmp;
  I64 ftmp;
  I64 fstmp;
  U64 ptmp;
  if (!a || !b || a == b || !a->leaf || !b->leaf) return;
  wtmp = a->win;
  a->win = b->win;
  b->win = wtmp;
  ftmp = a->floating;
  a->floating = b->floating;
  b->floating = ftmp;
  fstmp = a->fullscreen;
  a->fullscreen = b->fullscreen;
  b->fullscreen = fstmp;
  fstmp = a->real_fullscreen;
  a->real_fullscreen = b->real_fullscreen;
  b->real_fullscreen = fstmp;
  /* thumbnails follow their window */
  ptmp = a->thumb;
  a->thumb = b->thumb;
  b->thumb = ptmp;
  ftmp = a->thumb_w;
  a->thumb_w = b->thumb_w;
  b->thumb_w = ftmp;
  ftmp = a->thumb_h;
  a->thumb_h = b->thumb_h;
  b->thumb_h = ftmp;
}

/* ---- XComposite/XRender live thumbnails ---- */

/* largest stored thumbnail edge; windows are downscaled to this once at
   capture time so the overview only ever rescales a small pixmap */
#define THUMB_CAP 512

U0 init_composite()
{
  I32 evb;
  I32 erb;
  I32 maj = 0;
  I32 min = 0;
  if (compositor_mode == 2) return;   /* compositor = off: leave compositing to picom */
  if (!XCompositeQueryExtension(dpy, &evb, &erb)) return;
  XCompositeQueryVersion(dpy, &maj, &min);
  /* XCompositeNameWindowPixmap needs >= 0.2 */
  if (maj == 0 && min < 2) return;
  if (!XRenderQueryExtension(dpy, &evb, &erb)) return;
  /* Capability is present, but DON'T grab the redirect here. We defer it to the
     first overview capture (ensure_redirect): by then any compositor launched
     from our own autostart is already running and owns _NET_WM_CM_S<screen>, so
     in auto mode we correctly detect it and skip our redirect -- which avoids
     fighting picom's reference count and breaking its wallpaper / animations.
     Redirecting eagerly at startup happened before autostart and always lost. */
  composite_ok = 1;
}

/* Resolve the one-time subwindow redirect, lazily, on first overview capture.
   An external compositor (picom/compton) already redirects in Manual mode, so we
   only take over when nobody owns the _NET_WM_CM_S<screen> selection. Either way
   XCompositeNameWindowPixmap then yields the off-screen pixmaps for thumbnails. */
U0 ensure_redirect()
{
  U8 cmsel[32];
  U64 cm;
  if (redirect_done) return;
  redirect_done = 1;
  if (compositor_mode == 1) {   /* compositor = on: always take over */
    XCompositeRedirectSubwindows(dpy, root, CompositeRedirectAutomatic);
    return;
  }
  StrPrint(cmsel, "_NET_WM_CM_S%d", XDefaultScreen(dpy));
  cm = XInternAtom(dpy, cmsel, False);
  if (XGetSelectionOwner(dpy, cm) == None)
    XCompositeRedirectSubwindows(dpy, root, CompositeRedirectAutomatic);
}

U0 free_thumb(Node *n)
{
  if (n && n->thumb) {
    XFreePixmap(dpy, n->thumb);
    n->thumb = 0;
    n->thumb_w = 0;
    n->thumb_h = 0;
  }
}

I64 XDoubleToFixed(F64 d)
{
  I64 r = d * 65536;
  return r;
}

/* blit a source pixmap scaled to fit dst rect via XRender (bilinear) */
U0 render_scaled(U64 dst, U64 srcpix, I64 sw_, I64 sh_,
                 I64 dx, I64 dy, I64 dw, I64 dh)
{
  I32 s;
  U8 *fmt;
  U64 src;
  XTransform xf;
  F64 fw;
  F64 fh;
  if (sw_ < 1 || sh_ < 1 || dw < 1 || dh < 1) return;
  s = XDefaultScreen(dpy);
  fmt = XRenderFindVisualFormat(dpy, XDefaultVisual(dpy, s));
  if (!fmt) return;
  src = XRenderCreatePicture(dpy, srcpix, fmt, 0, NULL);
  /* transform maps dst coords -> src coords, so the diagonal is src/dst */
  fw = sw_;
  fh = sh_;
  MemSet(&xf, 0, sizeof(XTransform));
  xf.m[0] = XDoubleToFixed(fw / dw);
  xf.m[4] = XDoubleToFixed(fh / dh);
  xf.m[8] = XDoubleToFixed(1.0);
  XRenderSetPictureTransform(dpy, src, &xf);
  XRenderSetPictureFilter(dpy, src, "bilinear", NULL, 0);
  XRenderComposite(dpy, PictOpSrc, src, None, dst, 0, 0, 0, 0, dx, dy, dw, dh);
  XRenderFreePicture(dpy, src);
}

/* snapshot one viewable window into its node's cached thumb pixmap */
U0 capture_thumb(Node *n)
{
  XWindowAttributes wa;
  U8 *sfmt;
  U64 wp;
  I64 srcw;
  I64 srch;
  F64 scale = 1.0;
  I64 mx;
  I64 tw;
  I64 th;
  I32 s;
  U64 src;
  U64 dst;
  XTransform xf;
  if (!composite_ok || !n || !n->leaf || !n->win) return;
  ensure_redirect();   /* first capture decides whether we redirect or defer to picom */
  if (!XGetWindowAttributes(dpy, n->win, &wa)) return;
  if (wa.map_state != IsViewable || wa.width < 1 || wa.height < 1) return;

  sfmt = XRenderFindVisualFormat(dpy, wa.visual);
  if (!sfmt) return;
  wp = XCompositeNameWindowPixmap(dpy, n->win);
  if (!wp) return;

  /* the named pixmap spans the window plus its border */
  srcw = wa.width + 2 * wa.border_width;
  srch = wa.height + 2 * wa.border_width;
  mx = srcw;
  if (srch > mx) mx = srch;
  if (mx > THUMB_CAP) {
    scale = THUMB_CAP;
    scale /= mx;
  }
  tw = srcw * scale;
  if (tw < 1) tw = 1;
  th = srch * scale;
  if (th < 1) th = 1;

  s = XDefaultScreen(dpy);
  if (n->thumb && (n->thumb_w != tw || n->thumb_h != th)) free_thumb(n);
  if (!n->thumb) {
    n->thumb = XCreatePixmap(dpy, root, tw, th, XDefaultDepth(dpy, s));
    n->thumb_w = tw;
    n->thumb_h = th;
  }

  src = XRenderCreatePicture(dpy, wp, sfmt, 0, NULL);
  dst = XRenderCreatePicture(dpy, n->thumb,
      XRenderFindVisualFormat(dpy, XDefaultVisual(dpy, s)), 0, NULL);
  MemSet(&xf, 0, sizeof(XTransform));
  xf.m[0] = XDoubleToFixed(1.0 / scale);
  xf.m[4] = XDoubleToFixed(1.0 / scale);
  xf.m[8] = XDoubleToFixed(1.0);
  XRenderSetPictureTransform(dpy, src, &xf);
  XRenderSetPictureFilter(dpy, src, "bilinear", NULL, 0);
  XRenderComposite(dpy, PictOpSrc, src, None, dst, 0, 0, 0, 0, 0, 0, tw, th);
  XRenderFreePicture(dpy, src);
  XRenderFreePicture(dpy, dst);
  XFreePixmap(dpy, wp);
}

U0 capture_tree(Node *n)
{
  if (!n) return;
  if (n->leaf) {
    capture_thumb(n);
    return;
  }
  capture_tree(n->a);
  capture_tree(n->b);
}

U0 drawborder(Node *n, I64 focused)
{
  I64 w = bw;
  if (n->real_fullscreen) w = 0;
  XSetWindowBorderWidth(dpy, n->win, w);
  if (focused) XSetWindowBorder(dpy, n->win, cfocus);
  else XSetWindowBorder(dpy, n->win, cnorm);
}

U0 raise_floating(Node *n)
{
  if (!n) return;
  if (n->leaf) {
    if (n->floating) XRaiseWindow(dpy, n->win);
    return;
  }
  raise_floating(n->a);
  raise_floating(n->b);
}

U0 unmap_managed(Node *n)
{
  if (!n || !n->leaf) return;
  n->ignore_unmap++;
  XUnmapWindow(dpy, n->win);
}

U0 show_only_leaf(Node *n, Node *target)
{
  if (!n) return;
  if (n->leaf) {
    if (n == target) XMapRaised(dpy, n->win);
    else unmap_managed(n);
    return;
  }
  show_only_leaf(n->a, target);
  show_only_leaf(n->b, target);
}

I64 has_tiled_leaf(Node *n)
{
  if (!n) return 0;
  if (n->leaf) return !n->floating;
  return has_tiled_leaf(n->a) || has_tiled_leaf(n->b);
}

U0 tilenode(Node *n, I64 x, I64 y, I64 w, I64 h, Node *foc)
{
  if (!n) return;
  n->x = x;
  n->y = y;
  n->w = w;
  n->h = h;
  if (n->leaf) {
    drawborder(n, n == foc);
    if (n->real_fullscreen) {
      XMoveResizeWindow(dpy, n->win, x, y, w, h);
    } else if (n->fullscreen) {
      XMoveResizeWindow(dpy, n->win, x, y, w - 2 * bw, h - 2 * bw);
    } else if (!n->floating) {
      I64 tw = w - 2 * gap - 2 * bw;
      I64 th = h - 2 * gap - 2 * bw;
      if (tw < 1) tw = 1;
      if (th < 1) th = 1;
      XMoveResizeWindow(dpy, n->win, x + gap, y + gap, tw, th);
    }
    return;
  }
  if (!has_tiled_leaf(n->a) && has_tiled_leaf(n->b)) {
    tilenode(n->b, x, y, w, h, foc);
    return;
  }
  if (!has_tiled_leaf(n->b) && has_tiled_leaf(n->a)) {
    tilenode(n->a, x, y, w, h, foc);
    return;
  }
  if (!has_tiled_leaf(n->a) && !has_tiled_leaf(n->b)) return;
  if (n->horiz) {
    I64 wa = w * n->ratio;
    tilenode(n->a, x, y, wa, h, foc);
    tilenode(n->b, x + wa, y, w - wa, h, foc);
  } else {
    I64 ha = h * n->ratio;
    tilenode(n->a, x, y, w, ha, foc);
    tilenode(n->b, x, y + ha, w, h - ha, foc);
  }
}

I64 draw_tag_box(U64 win, I64 x, I64 y, U8 *text, U64 bg, U64 fg, I64 minw)
{
  I64 pad = bartextpad;
  I64 w = textw(text) + pad * 2;
  if (w < minw) w = minw;
  XSetForeground(dpy, bargc, bg);
  XFillRectangle(dpy, win, bargc, x, y, w, barh);
  XSetForeground(dpy, bargc, fg);
  XDrawString(dpy, win, bargc, x + pad, y + barh - 8, text, StrLen(text));
  return w;
}

#define BAR_ITEM_NONE       0
#define BAR_ITEM_WORKSPACES 1
#define BAR_ITEM_COMMAND    2
#define BAR_ITEM_TITLE      3
#define BAR_ITEM_CLOCK      4
#define BAR_ITEM_BATTERY    5
#define BAR_ITEM_MODE       6
#define BAR_ITEM_TRAY       7

I64 parse_bar_item(U8 *name)
{
  if (!strcasecmp(name, "workspaces")) return BAR_ITEM_WORKSPACES;
  if (!strcasecmp(name, "command")) return BAR_ITEM_COMMAND;
  if (!strcasecmp(name, "title")) return BAR_ITEM_TITLE;
  if (!strcasecmp(name, "clock")) return BAR_ITEM_CLOCK;
  if (!strcasecmp(name, "battery")) return BAR_ITEM_BATTERY;
  if (!strcasecmp(name, "mode")) return BAR_ITEM_MODE;
  if (!strcasecmp(name, "tray")) return BAR_ITEM_TRAY;
  return BAR_ITEM_NONE;
}

U0 build_bar_item_text(I64 item, U8 *dst, I64 dstsz)
{
  dst[0] = 0;
  switch (item) {
  case BAR_ITEM_COMMAND:
  case BAR_ITEM_MODE:
    build_mode_text(dst, dstsz);
    break;
  case BAR_ITEM_TITLE:
    build_title_text(dst, dstsz);
    break;
  case BAR_ITEM_CLOCK:
    build_clock_text(dst, dstsz);
    break;
  case BAR_ITEM_BATTERY:
    build_battery_text(dst, dstsz);
    break;
  default:
    break;
  }
}

/* a workspace is shown on monitor mi's bar if that monitor holds windows
   there, or it is that monitor's current workspace */
I64 mon_ws_visible_in_bar(I64 mi, I64 ws)
{
  return mons[mi].tree[ws] != NULL || ws == mons[mi].curws;
}

I64 workspace_section_width()
{
  I64 width = 0;
  I64 i;
  U8 part[8];
  for (i = 0; i < numws; i++) {
    if (!mon_ws_visible_in_bar(barmon, i)) continue;
    StrPrint(part, "%d", i + 1);
    width += textw(part) + bartextpad * 2 + baritemgap;
  }
  return width;
}

I64 draw_workspace_section(U64 win, I64 x, I64 y)
{
  I64 curx = x;
  I64 i;
  U8 part[8];
  for (i = 0; i < numws; i++) {
    U64 bg = barbg;
    U64 fg = barmutedfg;
    if (!mon_ws_visible_in_bar(barmon, i)) continue;
    StrPrint(part, "%d", i + 1);
    if (i == mons[barmon].curws) {
      bg = baraccentbg;
      fg = baraccentfg;
    } else if (mons[barmon].tree[i]) {
      fg = barfg;
    }
    curx += draw_tag_box(win, curx, y, part, bg, fg, barwsminw);
    curx += baritemgap;
  }
  return curx;
}

I64 bar_item_width(I64 item)
{
  U8 tmp[256];

  if (item == BAR_ITEM_WORKSPACES) return workspace_section_width();
  if (item == BAR_ITEM_TRAY) {
    if (barmon == traymon) return tray_width();
    return 0;
  }
  build_bar_item_text(item, tmp, 256);
  if (!tmp[0]) return 0;

  switch (item) {
  case BAR_ITEM_COMMAND:
    if (mode == MODE_COMMAND && cmdline_len > 0)
      return textw(tmp) + bartextpad * 2 + baritemgap + textw(cmdline) + bartextpad * 2;
    return textw(tmp) + bartextpad * 2;
  case BAR_ITEM_TITLE:
  case BAR_ITEM_CLOCK:
  case BAR_ITEM_BATTERY:
  case BAR_ITEM_MODE:
    return textw(tmp) + bartextpad * 2;
  default:
    return 0;
  }
}

I64 draw_bar_item(U64 win, I64 x, I64 y, I64 item)
{
  U8 tmp[256];
  I64 curx = x;

  if (item == BAR_ITEM_WORKSPACES) return draw_workspace_section(win, x, y);
  if (item == BAR_ITEM_TRAY) {
    /* nothing to paint: the icons are child windows of the bar, moved into
       this slot after the bar pixmap is copied (tray_layout_icons) */
    if (barmon == traymon) tray_draw_x = curx;
    return curx + bar_item_width(BAR_ITEM_TRAY);
  }

  build_bar_item_text(item, tmp, 256);
  if (!tmp[0]) return curx;

  switch (item) {
  case BAR_ITEM_COMMAND:
    curx += draw_tag_box(win, curx, y, tmp, baraccentbg, baraccentfg, 0);
    if (mode == MODE_COMMAND && cmdline_len > 0) {
      curx += baritemgap;
      curx += draw_tag_box(win, curx, y, cmdline, cnorm, barfg, 0);
    }
    return curx;
  case BAR_ITEM_TITLE:
    return curx + draw_tag_box(win, curx, y, tmp, barbg, barfg, 0);
  case BAR_ITEM_CLOCK:
  case BAR_ITEM_MODE:
    return curx + draw_tag_box(win, curx, y, tmp, baraccentbg, baraccentfg, 0);
  case BAR_ITEM_BATTERY:
    return curx + draw_tag_box(win, curx, y, tmp, cnorm, barfg, 0);
  default:
    return curx;
  }
}

I64 section_width(U8 *cfg)
{
  U8 buf[128];
  U8 item[128];
  U8 *tok;
  U8 *save;
  I64 width = 0;
  I64 kind;
  copystr(buf, 128, cfg);
  save = buf;
  tok = tok_comma(&save);
  while (tok) {
    copystr(item, 128, ltrim(tok));
    rtrim(item);
    kind = parse_bar_item(item);
    if (kind != BAR_ITEM_NONE) width += bar_item_width(kind) + baritemgap;
    tok = tok_comma(&save);
  }
  if (width > 0) return width - baritemgap;
  return 0;
}

I64 draw_section(U64 win, I64 x, I64 y, U8 *cfg)
{
  U8 buf[128];
  U8 item[128];
  U8 *tok;
  U8 *save;
  I64 curx = x;
  I64 kind;
  copystr(buf, 128, cfg);
  save = buf;
  tok = tok_comma(&save);
  while (tok) {
    copystr(item, 128, ltrim(tok));
    rtrim(item);
    kind = parse_bar_item(item);
    if (kind != BAR_ITEM_NONE) {
      curx = draw_bar_item(win, curx, y, kind);
      curx += baritemgap;
    }
    tok = tok_comma(&save);
  }
  return curx;
}

U0 drawbar(I64 mi)
{
  Mon *m = &mons[mi];
  I64 leftx = barpadx;
  I64 centx;
  I64 rightx;
  I64 leftw;
  I64 centerw;
  I64 rightw;
  if (!m->barwin) return;
  barmon = mi;

  if (!m->barpix)
    m->barpix = XCreatePixmap(dpy, m->barwin, m->w, barh, XDefaultDepth(dpy, XDefaultScreen(dpy)));

  if (mi == traymon) tray_draw_x = -1;
  centerw = section_width(barcentercfg);
  rightw = section_width(barrightcfg);

  XSetForeground(dpy, bargc, barbg);
  XFillRectangle(dpy, m->barpix, bargc, 0, 0, m->w, barh);

  leftw = section_width(barleftcfg);
  draw_section(m->barpix, leftx, 0, barleftcfg);
  rightx = m->w - rightw - barpadx;
  if (rightw > 0) draw_section(m->barpix, rightx, 0, barrightcfg);
  centx = (m->w - centerw) / 2;
  if (centerw > 0 && centx > leftx + leftw + 12 && centx + centerw < rightx - 12)
    draw_section(m->barpix, centx, 0, barcentercfg);

  XCopyArea(dpy, m->barpix, m->barwin, bargc, 0, 0, m->w, barh, 0, 0);
  if (mi == traymon) tray_layout_icons();
}

I64 bar_uses_item(U8 *item)
{
  return strstr(barleftcfg, item) || strstr(barcentercfg, item) || strstr(barrightcfg, item);
}

U0 drawbars_on_tick()
{
  I64 now = time(NULL);
  Tm tm_now;
  if (!bar_uses_item("clock") && !bar_uses_item("battery")) return;
  localtime_r(&now, &tm_now);
  if (tm_now.tm_sec != last_clock_second) {
    drawbars();
  }
}

U0 wait_event_or_tick()
{
  I32 xfd = XConnectionNumber(dpy);
  FdSet readfds;

  XFlush(dpy);
  MemSet(&readfds, 0, sizeof(FdSet));
  readfds.bits[xfd / 64] |= 1 << (xfd % 64);

  if (bar_uses_item("clock") || bar_uses_item("battery")) {
    TimeSpec now;
    TimeVal tv;
    I64 usec;

    clock_gettime(CLOCK_REALTIME, &now);
    usec = 1000000 - now.tv_nsec / 1000;
    if (usec <= 0) usec = 1000;
    tv.tv_sec = usec / 1000000;
    tv.tv_usec = usec % 1000000;
    select(xfd + 1, &readfds, NULL, NULL, &tv);
  } else {
    select(xfd + 1, &readfds, NULL, NULL, NULL);
  }
}

U0 drawbars()
{
  I64 i;
  if (!barenabled) return;
  for (i = 0; i < nmons; i++) drawbar(i);
  XFlush(dpy);
}

U0 retile()
{
  I64 i;
  for (i = 0; i < nmons; i++) {
    Mon *m = &mons[i];
    Node *fs = find_fullscreen_leaf(mon_tree(i));
    if (fs) {
      show_only_leaf(mon_tree(i), fs);
      drawborder(fs, fs == mon_focused(i));
      if (fs->real_fullscreen) {
        if (barenabled && m->barwin) XUnmapWindow(dpy, m->barwin);
        XMoveResizeWindow(dpy, fs->win, m->x, m->y, m->w, m->h);
      } else {
        if (barenabled && m->barwin) XMapRaised(dpy, m->barwin);
        XMoveResizeWindow(dpy, fs->win, m->wx, m->wy, m->ww - 2 * bw, m->wh - 2 * bw);
      }
      XRaiseWindow(dpy, fs->win);
    } else {
      Node *foc_i;
      if (barenabled && m->barwin) XMapRaised(dpy, m->barwin);
      showtree(mon_tree(i));
      tilenode(mon_tree(i), m->wx, m->wy, m->ww, m->wh, mon_focused(i));
      raise_floating(mon_tree(i));
      foc_i = mon_focused(i);
      if (foc_i && (foc_i->floating || foc_i->fullscreen)) XRaiseWindow(dpy, foc_i->win);
    }
    if (barenabled && m->barwin && !find_real_fs_leaf(mon_tree(i))) XRaiseWindow(dpy, m->barwin);
  }
  sync_dock_stack();
  drawbars();
}

U0 warpfocus(Node *n)
{
  if (!warp_pointer || !n || !n->leaf) return;
  XWarpPointer(dpy, None, root, 0, 0, 0, 0, n->x + n->w / 2, n->y + n->h / 2);
}

U0 setfocus(I64 mi, Node *n, I64 warp)
{
  Node *fs;
  Node *prev;
  if (!n || !n->leaf) return;
  fs = find_fullscreen_leaf(mon_tree(mi));
  if (fs && fs != n) {
    n = fs;
    warp = 0;
  }
  prev = mon_focused(mi);
  mon_setfocused(mi, n);
  curmon = mi;
  if (prev && prev != n) drawborder(prev, 0);
  if (mode == MODE_INSERT) XSetInputFocus(dpy, n->win, RevertToPointerRoot, CurrentTime);
  drawborder(n, 1);
  if (n->floating || n->fullscreen || n->real_fullscreen) XRaiseWindow(dpy, n->win);
  if (barenabled && mons[mi].barwin) XRaiseWindow(dpy, mons[mi].barwin);
  if (warp) warpfocus(n);
  update_active_window();
  refresh_cached_title();
}

U0 showtree(Node *n)
{
  if (!n) return;
  if (n->leaf) {
    XMapWindow(dpy, n->win);
    return;
  }
  showtree(n->a);
  showtree(n->b);
}

U0 free_tree(Node *n)
{
  if (!n) return;
  if (!n->leaf) {
    free_tree(n->a);
    free_tree(n->b);
  } else {
    free_thumb(n);
  }
  Free(n);
}

/* free only the internal split nodes of a tree, leaving leaf nodes intact */
U0 free_splits(Node *n)
{
  if (!n || n->leaf) return;
  free_splits(n->a);
  free_splits(n->b);
  Free(n);
}

/* true if the given output is physically connected */
I64 output_is_connected(XRRScreenResources *sr, U64 out)
{
  XRROutputInfo *oi = XRRGetOutputInfo(dpy, sr, out);
  I64 c = oi && oi->connection == RR_Connected;
  if (oi) XRRFreeOutputInfo(oi);
  return c;
}

/* tight framebuffer bounding box over every active CRTC */
U0 active_bbox(XRRScreenResources *sr, I64 *w, I64 *h)
{
  I64 bw2 = 0;
  I64 bh = 0;
  I64 i;
  for (i = 0; i < sr->ncrtc; i++) {
    XRRCrtcInfo *ci = XRRGetCrtcInfo(dpy, sr, sr->crtcs[i]);
    if (!ci) continue;
    if (ci->mode != None && ci->noutput > 0) {
      I64 r = ci->x + ci->width;
      I64 b = ci->y + ci->height;
      if (r > bw2) bw2 = r;
      if (b > bh) bh = b;
    }
    XRRFreeCrtcInfo(ci);
  }
  *w = bw2;
  *h = bh;
}

U0 set_screen_px(I64 w, I64 h)
{
  I64 mmw = w * 25.4 / 96.0 + 0.5;
  I64 mmh = h * 25.4 / 96.0 + 0.5;
  XRRSetScreenSize(dpy, root, w, h, mmw, mmh);
}

/* Built-in `xrandr --auto`. Drives the output set to match what is physically
 * plugged in: disconnected outputs are turned OFF (so an unplugged monitor never
 * lingers as a phantom CRTC + dead framebuffer region that mangles the wallpaper),
 * connected-but-dark outputs are lit at their preferred mode and laid out
 * left-to-right, and the framebuffer is resized to the tight bounding box.
 * Returns 1 if the layout changed. */
I64 autoconfigure_outputs()
{
  I64 changed = 0;
  XRRScreenResources *sr;
  I64 i;
  I64 j;
  I64 o;
  I64 m;
  I64 c;
  I64 u;
  U64 used[64];
  I64 nused = 0;
  I64 rightmost = 0;
  I64 maxbottom = 0;
  if (!auto_monitors || !randr_active) return 0;

  /* Pass A: turn off CRTCs whose outputs are all disconnected (kill phantoms). */
  sr = XRRGetScreenResources(dpy, root);
  if (!sr) return 0;
  for (i = 0; i < sr->ncrtc; i++) {
    XRRCrtcInfo *ci = XRRGetCrtcInfo(dpy, sr, sr->crtcs[i]);
    if (!ci) continue;
    if (ci->mode != None && ci->noutput > 0) {
      I64 any = 0;
      for (j = 0; j < ci->noutput; j++)
        if (output_is_connected(sr, ci->outputs[j])) {
          any = 1;
          break;
        }
      if (!any) {
        XRRSetCrtcConfig(dpy, sr, sr->crtcs[i], CurrentTime, 0, 0,
                         None, RR_Rotate_0, NULL, 0);
        changed = 1;
      }
    }
    XRRFreeCrtcInfo(ci);
  }
  XRRFreeScreenResources(sr);
  if (changed) XSync(dpy, False);

  /* Pass B: enable connected outputs that have no CRTC, extended to the right. */
  sr = XRRGetScreenResources(dpy, root);
  if (!sr) return changed;
  for (i = 0; i < sr->ncrtc; i++) {
    XRRCrtcInfo *ci = XRRGetCrtcInfo(dpy, sr, sr->crtcs[i]);
    if (!ci) continue;
    if (ci->mode != None && ci->noutput > 0) {
      I64 r = ci->x + ci->width;
      I64 b = ci->y + ci->height;
      if (nused < 64) {
        used[nused] = sr->crtcs[i];
        nused++;
      }
      if (r > rightmost) rightmost = r;
      if (b > maxbottom) maxbottom = b;
    }
    XRRFreeCrtcInfo(ci);
  }
  for (o = 0; o < sr->noutput; o++) {
    XRROutputInfo *oi = XRRGetOutputInfo(dpy, sr, sr->outputs[o]);
    U64 rmode;
    I64 mw = 0;
    I64 mh = 0;
    U64 crtc = None;
    I64 needw;
    I64 needh;
    I64 curw;
    I64 curh;
    U64 out1;
    if (!oi) continue;
    if (oi->connection != RR_Connected || oi->crtc != None || oi->nmode == 0) {
      XRRFreeOutputInfo(oi);
      continue;
    }
    rmode = oi->modes[0];   /* preferred mode comes first */
    for (m = 0; m < sr->nmode; m++)
      if (sr->modes[m].id == rmode) {
        mw = sr->modes[m].width;
        mh = sr->modes[m].height;
        break;
      }
    if (mw == 0) {
      XRRFreeOutputInfo(oi);
      continue;
    }

    for (c = 0; c < oi->ncrtc && crtc == None; c++) {
      U64 cand = oi->crtcs[c];
      I64 taken = 0;
      for (u = 0; u < nused; u++)
        if (used[u] == cand) {
          taken = 1;
          break;
        }
      if (!taken) crtc = cand;
    }
    if (crtc == None) {
      XRRFreeOutputInfo(oi);
      continue;
    }

    /* grow the framebuffer before the new CRTC lands outside it */
    needw = rightmost + mw;
    needh = maxbottom;
    if (mh > needh) needh = mh;
    curw = XDisplayWidth(dpy, XDefaultScreen(dpy));
    curh = XDisplayHeight(dpy, XDefaultScreen(dpy));
    if (needw < curw) needw = curw;
    if (needh < curh) needh = curh;
    set_screen_px(needw, needh);

    out1 = sr->outputs[o];
    if (XRRSetCrtcConfig(dpy, sr, crtc, CurrentTime, rightmost, 0, rmode,
                         RR_Rotate_0, &out1, 1) == RRSetConfigSuccess) {
      if (nused < 64) {
        used[nused] = crtc;
        nused++;
      }
      rightmost += mw;
      if (mh > maxbottom) maxbottom = mh;
      changed = 1;
    }
    XRRFreeOutputInfo(oi);
  }
  XRRFreeScreenResources(sr);

  /* Pass C: shrink the framebuffer back to the tight bounding box of what is on. */
  sr = XRRGetScreenResources(dpy, root);
  if (sr) {
    I64 bw2 = 0;
    I64 bh = 0;
    active_bbox(sr, &bw2, &bh);
    if (bw2 > 0 && bh > 0 &&
        (bw2 != XDisplayWidth(dpy, XDefaultScreen(dpy)) ||
         bh != XDisplayHeight(dpy, XDefaultScreen(dpy)))) {
      set_screen_px(bw2, bh);
      changed = 1;
    }
    XRRFreeScreenResources(sr);
  }

  if (changed) XSync(dpy, False);
  return changed;
}

/* fill out[] with current monitor geometry via Xinerama; returns monitor count */
I64 querygeom(Mon *out, I64 max)
{
  I32 n = 0;
  I64 i;
  if (XineramaIsActive(dpy)) {
    XineramaScreenInfo *xi = XineramaQueryScreens(dpy, &n);
    if (xi) {
      if (n > max) n = max;
      for (i = 0; i < n; i++) {
        out[i].x = xi[i].x_org;
        out[i].y = xi[i].y_org;
        out[i].w = xi[i].width;
        out[i].h = xi[i].height;
      }
      XFree(xi);
    }
  }
  if (n < 1) {
    n = 1;
    out[0].x = 0;
    out[0].y = 0;
    out[0].w = XDisplayWidth(dpy, XDefaultScreen(dpy));
    out[0].h = XDisplayHeight(dpy, XDefaultScreen(dpy));
  }
  return n;
}

/* re-read monitor layout after a hotplug/resolution change.
 * Returns 1 if the layout changed (caller should rebuild bars and retile). */
I64 updategeom()
{
  Mon ng[MAXMONS];
  I64 nn = querygeom(ng, MAXMONS);
  I64 changed = (nn != nmons);
  I64 i;
  I64 mi;
  I64 ws;
  I64 k;

  for (i = 0; i < nn && !changed; i++) {
    if (ng[i].x != mons[i].x || ng[i].y != mons[i].y ||
        ng[i].w != mons[i].w || ng[i].h != mons[i].h) changed = 1;
  }
  if (!changed) return 0;
  if (overview_active) close_overview();

  /* monitors removed: migrate their windows onto the last surviving monitor */
  if (nn < nmons) {
    I64 target = nn - 1;
    for (mi = nn; mi < nmons; mi++) {
      for (ws = 0; ws < numws; ws++) {
        Node *tree = mons[mi].tree[ws];
        Node *leaves[256];
        I64 cnt = 0;
        if (!tree) continue;
        collect_leaves(tree, leaves, &cnt, 256);
        mons[mi].tree[ws] = NULL;
        mons[mi].focused[ws] = NULL;
        free_splits(tree);
        for (k = 0; k < cnt; k++) {
          Node *lf = leaves[k];
          lf->par = NULL;
          lf->a = NULL;
          lf->b = NULL;
          attach_to_ws(target, ws, lf);
        }
      }
    }
    /* hide windows migrated onto a non-current workspace of the target */
    for (ws = 0; ws < numws; ws++)
      if (ws != mons[target].curws) hidetree(mons[target].tree[ws]);
  }

  for (i = 0; i < nn; i++) {
    mons[i].x = ng[i].x;
    mons[i].y = ng[i].y;
    mons[i].w = ng[i].w;
    mons[i].h = ng[i].h;
  }
  nmons = nn;
  if (curmon >= nmons) curmon = nmons - 1;

  sw = XDisplayWidth(dpy, XDefaultScreen(dpy));
  sh = XDisplayHeight(dpy, XDefaultScreen(dpy));
  return 1;
}

U0 initatoms()
{
  U8 trayname[32];
  atom_net_active_window = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", False);
  atom_net_client_list = XInternAtom(dpy, "_NET_CLIENT_LIST", False);
  atom_net_current_desktop = XInternAtom(dpy, "_NET_CURRENT_DESKTOP", False);
  atom_net_num_desktops = XInternAtom(dpy, "_NET_NUMBER_OF_DESKTOPS", False);
  atom_net_supported = XInternAtom(dpy, "_NET_SUPPORTED", False);
  atom_net_wm_check = XInternAtom(dpy, "_NET_SUPPORTING_WM_CHECK", False);
  atom_utf8_string = XInternAtom(dpy, "UTF8_STRING", False);
  atom_net_wm_wtype = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE", False);
  atom_wtype_dock = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DOCK", False);
  atom_wtype_dialog = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DIALOG", False);
  atom_wtype_utility = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_UTILITY", False);
  atom_wtype_toolbar = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_TOOLBAR", False);
  atom_wtype_splash = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_SPLASH", False);
  atom_net_wm_desktop = XInternAtom(dpy, "_NET_WM_DESKTOP", False);
  atom_net_wm_state = XInternAtom(dpy, "_NET_WM_STATE", False);
  atom_net_wm_state_fs = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", False);
  atom_net_wm_name = XInternAtom(dpy, "_NET_WM_NAME", False);
  atom_net_wm_strut = XInternAtom(dpy, "_NET_WM_STRUT", False);
  atom_net_wm_strut_part = XInternAtom(dpy, "_NET_WM_STRUT_PARTIAL", False);
  atom_wm_protocols = XInternAtom(dpy, "WM_PROTOCOLS", False);
  atom_wm_delete_window = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
  atom_net_wm_pid = XInternAtom(dpy, "_NET_WM_PID", False);
  StrPrint(trayname, "_NET_SYSTEM_TRAY_S%d", XDefaultScreen(dpy));
  atom_net_system_tray = XInternAtom(dpy, trayname, False);
  atom_tray_opcode = XInternAtom(dpy, "_NET_SYSTEM_TRAY_OPCODE", False);
  atom_tray_orient = XInternAtom(dpy, "_NET_SYSTEM_TRAY_ORIENTATION", False);
  atom_xembed = XInternAtom(dpy, "_XEMBED", False);
  atom_manager = XInternAtom(dpy, "MANAGER", False);
}

U0 setup_wm_check()
{
  U8 *name = "holywm";
  U8 *wp;
  wmcheckwin = XCreateSimpleWindow(dpy, root, -1, -1, 1, 1, 0, 0, 0);
  wp = &wmcheckwin;
  XChangeProperty(dpy, wmcheckwin, atom_net_wm_check, XA_WINDOW, 32,
      PropModeReplace, wp, 1);
  XChangeProperty(dpy, root, atom_net_wm_check, XA_WINDOW, 32,
      PropModeReplace, wp, 1);
  XChangeProperty(dpy, wmcheckwin, atom_net_wm_name,
      atom_utf8_string, 8, PropModeReplace, name, StrLen(name));
}

U0 update_supported_atoms()
{
  U64 supported[15];
  U8 *sp = supported;
  supported[0] = atom_net_active_window;
  supported[1] = atom_net_client_list;
  supported[2] = atom_net_current_desktop;
  supported[3] = atom_net_num_desktops;
  supported[4] = atom_net_wm_wtype;
  supported[5] = atom_wtype_dock;
  supported[6] = atom_wtype_dialog;
  supported[7] = atom_wtype_utility;
  supported[8] = atom_wtype_toolbar;
  supported[9] = atom_wtype_splash;
  supported[10] = atom_net_wm_desktop;
  supported[11] = atom_net_wm_state;
  supported[12] = atom_net_wm_state_fs;
  supported[13] = atom_net_wm_strut;
  supported[14] = atom_net_wm_strut_part;
  XChangeProperty(dpy, root, atom_net_supported, XA_ATOM, 32, PropModeReplace,
      sp, 15);
}

U0 collect_client_windows(Node *n, U64 *list, I64 *count, I64 maxcount)
{
  if (!n || *count >= maxcount) return;
  if (n->leaf) {
    list[*count] = n->win;
    *count = *count + 1;
    return;
  }
  collect_client_windows(n->a, list, count, maxcount);
  collect_client_windows(n->b, list, count, maxcount);
}

U0 update_client_list()
{
  U64 list[1024];
  I64 count = 0;
  I64 mi;
  I64 ws;
  U8 *lp = list;
  for (mi = 0; mi < nmons; mi++) {
    for (ws = 0; ws < numws; ws++) {
      collect_client_windows(mon_tree_at(mi, ws), list, &count, 1024);
    }
  }
  XChangeProperty(dpy, root, atom_net_client_list, XA_WINDOW, 32, PropModeReplace,
      lp, count);
}

U0 update_current_desktop()
{
  U64 ws = mons[curmon].curws;
  U8 *wp = &ws;
  XChangeProperty(dpy, root, atom_net_current_desktop, XA_CARDINAL, 32, PropModeReplace,
      wp, 1);
}

U0 update_num_desktops()
{
  U64 n = numws;
  U8 *np = &n;
  XChangeProperty(dpy, root, atom_net_num_desktops, XA_CARDINAL, 32, PropModeReplace,
      np, 1);
}

U0 update_active_window()
{
  U64 win = None;
  U8 *wp = &win;
  if (mon_focused(curmon)) win = mon_focused(curmon)->win;
  XChangeProperty(dpy, root, atom_net_active_window, XA_WINDOW, 32, PropModeReplace,
      wp, 1);
}

U0 set_window_desktop(U64 win, I64 ws)
{
  U64 val = ws;
  U8 *vp = &val;
  XChangeProperty(dpy, win, atom_net_wm_desktop, XA_CARDINAL, 32, PropModeReplace,
      vp, 1);
}

U0 apply_rules(Node *n, I64 *targetws, I64 *out_follow)
{
  U8 class_name[64];
  U8 instance_name[64];
  U8 title[128];
  I64 want_follow = 0;
  I64 base_ws = 0;
  I64 i;
  I64 ws;
  I64 mi;
  I64 li;
  if (targetws) base_ws = *targetws;
  if (!n || !n->leaf) return;
  get_window_class(n->win, class_name, 64, instance_name, 64);
  get_window_title(n->win, title, 128);

  if (window_is_dialog_like(n->win)) n->floating = 1;

  for (i = 0; i < nrules; i++) {
    Rule *r = &rules[i];
    I64 match = 1;
    if (r->class_name[0] && StrCmp(r->class_name, class_name)) match = 0;
    if (r->instance_name[0] && StrCmp(r->instance_name, instance_name)) match = 0;
    if (r->title[0] && StrCmp(r->title, title)) match = 0;
    if (!match) continue;
    if (r->set_floating) n->floating = r->floating;
    if (targetws && r->workspace >= 0) *targetws = r->workspace;
    if (r->follow_class) want_follow = 1;
  }

  /* follow_class: if no explicit workspace rule fired, find existing window
     of same class on another workspace and follow it */
  if (want_follow && targetws && *targetws == base_ws && class_name[0]) {
    for (ws = 0; ws < numws; ws++) {
      I64 found = 0;
      if (ws == base_ws) continue;
      for (mi = 0; mi < nmons && !found; mi++) {
        Node *leaves[256];
        I64 count = 0;
        collect_leaves(mon_tree_at(mi, ws), leaves, &count, 256);
        for (li = 0; li < count; li++) {
          U8 lc[64];
          U8 li2[64];
          get_window_class(leaves[li]->win, lc, 64, li2, 64);
          if (!StrCmp(lc, class_name)) {
            found = 1;
            break;
          }
        }
      }
      if (found) {
        *targetws = ws;
        if (out_follow) *out_follow = 1;
        break;
      }
    }
  }
}

U0 hidetree(Node *n)
{
  if (!n) return;
  if (n->leaf) {
    unmap_managed(n);
    return;
  }
  hidetree(n->a);
  hidetree(n->b);
}

/* switch only monitor mi to workspace ws; other monitors keep their own */
U0 switch_workspace_on(I64 mi, I64 ws)
{
  if (mi < 0 || mi >= nmons || ws < 0 || ws >= numws || ws == mons[mi].curws) return;
  /* A game can use a pointer grab/relative mouse input.  Drop keyboard focus
     before its window becomes unviewable, so it receives FocusOut before the
     workspace change and cannot keep consuming normal X11 input in the
     background.  Unmapping then releases any server-side pointer grab. */
  if (mon_focused(mi)) XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime);
  /* snapshot the windows we are about to hide so the overview can still
     show their contents while they are unmapped */
  if (composite_ok) capture_tree(mons[mi].tree[mons[mi].curws]);
  hidetree(mons[mi].tree[mons[mi].curws]);
  mons[mi].curws = ws;
  showtree(mons[mi].tree[ws]);
  retile();
  if (mi == curmon) update_current_desktop();
  if (mon_focused(mi)) setfocus(mi, mon_focused(mi), 1);
  else if (mi == curmon) update_active_window();
}

/* the monitor the user is looking at: the one under the pointer */
I64 pointer_mon()
{
  U64 dw;
  I32 rx;
  I32 ry;
  I32 wx;
  I32 wy;
  U32 msk;
  if (XQueryPointer(dpy, root, &dw, &dw, &rx, &ry, &wx, &wy, &msk))
    return monforpt(rx, ry);
  return curmon;
}

/* keyboard workspace switching acts on the monitor under the pointer, so it
   never targets a stale curmon left on another monitor (matches scroll-wheel) */
U0 switch_workspace(I64 ws)
{
  I64 mi = pointer_mon();
  curmon = mi;
  switch_workspace_on(mi, ws);
}

U0 attach_to_ws(I64 mi, I64 ws, Node *leaf)
{
  Node *focused;
  Node *tree;
  Node *t;
  Node *sp;
  I64 horiz;
  leaf->par = NULL;
  set_window_desktop(leaf->win, ws);
  if (!mon_tree_at(mi, ws)) {
    mon_settree_at(mi, ws, leaf);
    mon_setfocused_at(mi, ws, leaf);
    update_client_list();
    return;
  }
  focused = mon_focused_at(mi, ws);
  tree = mon_tree_at(mi, ws);
  if (focused && focused->leaf) t = focused;
  else t = firstleaf(tree);
  if (t->w > 0) horiz = t->w >= t->h;
  else horiz = mons[mi].ww >= mons[mi].wh;
  sp = CAlloc(sizeof(Node));
  sp->ratio = 0.5;
  sp->horiz = horiz;
  sp->par = t->par;
  sp->a = t;
  sp->b = leaf;
  if (!t->par) mon_settree_at(mi, ws, sp);
  else if (t->par->a == t) t->par->a = sp;
  else t->par->b = sp;
  t->par = sp;
  leaf->par = sp;
  mon_setfocused_at(mi, ws, leaf);
  update_client_list();
}

U0 attach(I64 mi, Node *leaf)
{
  attach_to_ws(mi, mons[mi].curws, leaf);
}

U0 detach_from_ws(I64 mi, I64 ws, Node *n)
{
  Node *p;
  Node *sib;
  if (!n->par) {
    mon_settree_at(mi, ws, NULL);
    mon_setfocused_at(mi, ws, NULL);
    update_client_list();
    return;
  }
  p = n->par;
  if (p->a == n) sib = p->b;
  else sib = p->a;
  sib->par = p->par;
  if (!p->par) mon_settree_at(mi, ws, sib);
  else if (p->par->a == p) p->par->a = sib;
  else p->par->b = sib;
  if (mon_focused_at(mi, ws) == n) mon_setfocused_at(mi, ws, firstleaf(sib));
  Free(p);
  n->par = NULL;
  update_client_list();
}

U0 detach(I64 mi, Node *n)
{
  detach_from_ws(mi, mons[mi].curws, n);
}

U0 removewin(U64 w)
{
  I64 mi = 0;
  I64 ws = 0;
  Node *n = findleaf_any(w, &mi, &ws);
  if (!n) return;
  if (drag_node == n) {
    drag_node = NULL;
    drag_mode = 0;
  }
  if (ov_drag_node == n) {
    ov_drag_node = NULL;
    ov_drag = 0;
  }
  free_thumb(n);
  detach_from_ws(mi, ws, n);
  Free(n);
  update_active_window();
}

U0 collect_leaves(Node *n, Node **list, I64 *count, I64 maxcount)
{
  if (!n || *count >= maxcount) return;
  if (n->leaf) {
    list[*count] = n;
    *count = *count + 1;
    return;
  }
  collect_leaves(n->a, list, count, maxcount);
  collect_leaves(n->b, list, count, maxcount);
}

/* tiled (non-floating) leaf on monitor mi whose tile rect holds (px,py) */
Node *tiled_leaf_at(I64 mi, I64 px, I64 py)
{
  Node *list[64];
  I64 cnt = 0;
  I64 i;
  collect_leaves(mon_tree(mi), list, &cnt, 64);
  for (i = 0; i < cnt; i++) {
    Node *n = list[i];
    if (n->floating) continue;
    if (px >= n->x && px < n->x + n->w && py >= n->y && py < n->y + n->h)
      return n;
  }
  return NULL;
}

I64 interval_overlap(I64 a1, I64 a2, I64 b1, I64 b2)
{
  I64 lo = a1;
  I64 hi = a2;
  if (b1 > lo) lo = b1;
  if (b2 < hi) hi = b2;
  if (hi > lo) return hi - lo;
  return 0;
}

/* direction codes, used by the pure picker below */
#define DIR_LEFT  0
#define DIR_RIGHT 1
#define DIR_UP    2
#define DIR_DOWN  3

I64 dir_code(U8 *dir)
{
  if (!StrCmp(dir, "left")) return DIR_LEFT;
  if (!StrCmp(dir, "right")) return DIR_RIGHT;
  if (!StrCmp(dir, "up")) return DIR_UP;
  return DIR_DOWN;
}

/* === directional picker (ported from inis' layout_focus_direction) ===
   Given the tiled leaf rectangles in `leaves`, return the window in direction
   `d` of `from`, the way inis (and Hyprland) does it -- centre-based, which is
   what makes it feel right on dwindle/Fibonacci layouts, not just master-stack:

     - a candidate counts as "in that direction" when its CENTRE is past our
       centre on that axis (dx > 0 for right, etc.); `primary` is the centre
       distance along the axis and the nearer centre wins;
     - ties are broken by the smaller full (Euclidean) centre distance, so we
       pick the window we are most squarely lined up with -- inis' exact rule;
     - GUARD: a window that overlaps us on the perpendicular axis (a true
       side-by-side neighbour) always beats one that does not. Pure centre
       distance alone can pick a diagonal tile whose centre happens to be
       nearer on the axis (e.g. a wide top tile when going right); requiring
       perpendicular overlap first keeps "go right" from ever jumping
       up/down-and-over. Only if nothing overlaps do we fall back to the
       plain centre-nearest window, so edge presses still move like inis.

   Returns NULL when there is nothing in that direction. */
Node *pick_directional(Node **leaves, I64 count, Node *from, I64 d)
{
  Node *best = NULL;     /* nearest centre WITH perpendicular overlap */
  Node *fallback = NULL; /* nearest centre of any in-direction window */
  I64 best_primary = 0;
  I64 best_dist = 0;
  I64 fb_primary = 0;
  I64 fb_dist = 0;
  I64 fx1;
  I64 fy1;
  I64 fx2;
  I64 fy2;
  I64 fcx;
  I64 fcy;
  I64 i;

  if (!from) return NULL;
  fx1 = from->x;
  fy1 = from->y;
  fx2 = from->x + from->w;
  fy2 = from->y + from->h;
  fcx = from->x + from->w / 2;
  fcy = from->y + from->h / 2;

  for (i = 0; i < count; i++) {
    Node *n = leaves[i];
    I64 ncx;
    I64 ncy;
    I64 dx;
    I64 dy;
    I64 primary;
    I64 overlap;
    I64 valid;
    I64 dist;
    if (n == from || n->floating) continue;
    ncx = n->x + n->w / 2;
    ncy = n->y + n->h / 2;
    dx = ncx - fcx;
    dy = ncy - fcy;

    if (d == DIR_LEFT) {
      valid = dx < 0;
      primary = -dx;
      overlap = interval_overlap(fy1, fy2, n->y, n->y + n->h);
    } else if (d == DIR_RIGHT) {
      valid = dx > 0;
      primary = dx;
      overlap = interval_overlap(fy1, fy2, n->y, n->y + n->h);
    } else if (d == DIR_UP) {
      valid = dy < 0;
      primary = -dy;
      overlap = interval_overlap(fx1, fx2, n->x, n->x + n->w);
    } else {
      valid = dy > 0;
      primary = dy;
      overlap = interval_overlap(fx1, fx2, n->x, n->x + n->w);
    }

    if (!valid) continue;
    dist = dx * dx + dy * dy;
    if (overlap > 0) {
      if (!best || primary < best_primary ||
          (primary == best_primary && dist < best_dist)) {
        best = n;
        best_primary = primary;
        best_dist = dist;
      }
    }
    if (!fallback || primary < fb_primary ||
        (primary == fb_primary && dist < fb_dist)) {
      fallback = n;
      fb_primary = primary;
      fb_dist = dist;
    }
  }
  if (best) return best;
  return fallback;
}

Node *find_directional_focus(I64 mi, Node *from, U8 *dir)
{
  Node *nodes[256];
  I64 count = 0;
  if (!from) return NULL;
  collect_leaves(mon_tree(mi), nodes, &count, 256);
  return pick_directional(nodes, count, from, dir_code(dir));
}

I64 swap_in_direction(U8 *dir)
{
  Node *cur = mon_focused(curmon);
  Node *n;
  U64 focused_win;
  if (!cur) return 1;
  n = find_directional_focus(curmon, cur, dir);
  if (!n || n == cur) return 1;
  focused_win = cur->win;
  swap_leaf_payload(cur, n);
  retile();
  setfocus(curmon, findleaf(mon_tree(curmon), focused_win), 1);
  return 1;
}

U0 move_to_ws(I64 targetws)
{
  Node *n;
  I64 srcmon = curmon;
  I64 srcws = mons[srcmon].curws;
  if (targetws < 0 || targetws >= numws || targetws == srcws) return;
  n = mon_focused(srcmon);
  if (!n) return;
  detach_from_ws(srcmon, srcws, n);
  attach_to_ws(srcmon, targetws, n);
  hidetree(n);
  retile();
  if (mon_focused(curmon)) setfocus(curmon, mon_focused(curmon), 1);
}

U0 move_to_ws_follow(I64 targetws)
{
  if (targetws < 0 || targetws >= numws || targetws == mons[curmon].curws) return;
  move_to_ws(targetws);
  switch_workspace(targetws);
}

/* ---- workspace overview (Super+Z), niri-style schematic ---- */

/* grid adapts to the active workspace count: a near-square layout */
I64 ov_cols()
{
  I64 c = 1;
  while (c * c < numws) c++;
  return c;
}

I64 ov_rows()
{
  I64 c = ov_cols();
  return (numws + c - 1) / c;
}

/* mirror of tilenode's split math, drawing scaled boxes instead of moving
   real windows; used to render a miniature of a workspace in the overview */
U0 overview_draw_node(Node *n, I64 x, I64 y, I64 w, I64 h, Node *foc, U64 pic)
{
  if (!n || w < 2 || h < 2) return;
  if (n->leaf) {
    I64 focused = (n == foc);
    U64 bg;
    if (pic && n->thumb) {
      /* live (or last-seen) window contents */
      render_scaled(pic, n->thumb, n->thumb_w, n->thumb_h,
                    x + 1, y + 1, w - 2, h - 2);
    } else {
      if (focused) bg = baraccentbg;
      else bg = cnorm;
      XSetForeground(dpy, bargc, bg);
      XFillRectangle(dpy, overview_pix, bargc, x + 1, y + 1, w - 2, h - 2);
    }
    if (focused) XSetForeground(dpy, bargc, baraccentbg);
    else XSetForeground(dpy, bargc, barbg);
    XDrawRectangle(dpy, overview_pix, bargc, x, y, w - 1, h - 1);
    if (w > 44 && h > 18 && barfont) {
      U8 title[128];
      I64 len;
      get_window_title(n->win, title, 128);
      len = StrLen(title);
      while (len > 0 && textw(title) > w - 10) {
        len--;
        title[len] = 0;
      }
      if (len > 0) {
        /* legible title bar over the thumbnail */
        if (focused) XSetForeground(dpy, bargc, baraccentbg);
        else XSetForeground(dpy, bargc, barbg);
        XFillRectangle(dpy, overview_pix, bargc, x + 1, y + 1, w - 2, 18);
        if (focused) XSetForeground(dpy, bargc, baraccentfg);
        else XSetForeground(dpy, bargc, barfg);
        XDrawString(dpy, overview_pix, bargc, x + 5, y + 14, title, len);
      }
    }
    return;
  }
  if (!has_tiled_leaf(n->a) && has_tiled_leaf(n->b)) {
    overview_draw_node(n->b, x, y, w, h, foc, pic);
    return;
  }
  if (!has_tiled_leaf(n->b) && has_tiled_leaf(n->a)) {
    overview_draw_node(n->a, x, y, w, h, foc, pic);
    return;
  }
  if (!has_tiled_leaf(n->a) && !has_tiled_leaf(n->b)) return;
  if (n->horiz) {
    I64 wa = w * n->ratio;
    overview_draw_node(n->a, x, y, wa, h, foc, pic);
    overview_draw_node(n->b, x + wa, y, w - wa, h, foc, pic);
  } else {
    I64 ha = h * n->ratio;
    overview_draw_node(n->a, x, y, w, ha, foc, pic);
    overview_draw_node(n->b, x, y + ha, w, h - ha, foc, pic);
  }
}

U0 overview_cell_rect(I64 ws, I64 *cx, I64 *cy, I64 *cw, I64 *ch)
{
  Mon *m = &mons[overview_mon];
  I64 cols = ov_cols();
  I64 rows = ov_rows();
  I64 pad = 16;
  I64 cellw = (m->w - pad * (cols + 1)) / cols;
  I64 cellh = (m->h - pad * (rows + 1)) / rows;
  *cx = pad + (ws % cols) * (cellw + pad);
  *cy = pad + (ws / cols) * (cellh + pad);
  *cw = cellw;
  *ch = cellh;
}

U0 draw_overview()
{
  Mon *m = &mons[overview_mon];
  U64 pic = None;
  I64 ws;
  U8 lbl[8];
  if (!overview_pix) return;

  if (composite_ok) {
    I32 s = XDefaultScreen(dpy);
    pic = XRenderCreatePicture(dpy, overview_pix,
        XRenderFindVisualFormat(dpy, XDefaultVisual(dpy, s)), 0, NULL);
  }

  XSetForeground(dpy, bargc, barbg);
  XFillRectangle(dpy, overview_pix, bargc, 0, 0, m->w, m->h);
  for (ws = 0; ws < numws; ws++) {
    I64 cx;
    I64 cy;
    I64 cw;
    I64 ch;
    I64 sel;
    I64 cur;
    I64 ix;
    I64 iy;
    I64 iw;
    I64 ih;
    U64 border;
    overview_cell_rect(ws, &cx, &cy, &cw, &ch);
    sel = (ws == overview_sel);
    cur = (ws == m->curws);
    XSetForeground(dpy, bargc, 0x1a1a1a);
    XFillRectangle(dpy, overview_pix, bargc, cx, cy, cw, ch);

    StrPrint(lbl, "%d", ws + 1);
    if (cur) XSetForeground(dpy, bargc, baraccentbg);
    else XSetForeground(dpy, bargc, barmutedfg);
    if (barfont) XDrawString(dpy, overview_pix, bargc, cx + 6, cy + 16, lbl, StrLen(lbl));

    ix = cx + 6;
    iy = cy + 24;
    iw = cw - 12;
    ih = ch - 30;
    if (m->tree[ws]) overview_draw_node(m->tree[ws], ix, iy, iw, ih, m->focused[ws], pic);

    if (sel) border = baraccentbg;
    else if (cur) border = barfg;
    else border = cnorm;
    XSetForeground(dpy, bargc, border);
    XDrawRectangle(dpy, overview_pix, bargc, cx, cy, cw - 1, ch - 1);
    if (sel) XDrawRectangle(dpy, overview_pix, bargc, cx + 1, cy + 1, cw - 3, ch - 3);
  }

  /* ghost of the window being dragged, following the cursor */
  if (ov_drag && ov_drag_node && ov_moved) {
    I64 gw = 220;
    I64 gh = 140;
    I64 gx = ov_ptr_x - gw / 2;
    I64 gy = ov_ptr_y - gh / 2;
    if (pic && ov_drag_node->thumb)
      render_scaled(pic, ov_drag_node->thumb, ov_drag_node->thumb_w,
                    ov_drag_node->thumb_h, gx, gy, gw, gh);
    else {
      XSetForeground(dpy, bargc, baraccentbg);
      XFillRectangle(dpy, overview_pix, bargc, gx, gy, gw, gh);
    }
    XSetForeground(dpy, bargc, baraccentbg);
    XDrawRectangle(dpy, overview_pix, bargc, gx, gy, gw - 1, gh - 1);
  }

  if (pic != None) XRenderFreePicture(dpy, pic);
  XCopyArea(dpy, overview_pix, overview_win, bargc, 0, 0, m->w, m->h, 0, 0);
}

U0 open_overview()
{
  Mon *m;
  I64 mi;
  U64 dw;
  I32 rx;
  I32 ry;
  I32 wx;
  I32 wy;
  U32 msk;
  XSetWindowAttributes wa;
  if (overview_active) return;
  /* always open on the monitor under the pointer */
  if (XQueryPointer(dpy, root, &dw, &dw, &rx, &ry, &wx, &wy, &msk))
    overview_mon = monforpt(rx, ry);
  else
    overview_mon = curmon;
  overview_sel = mons[overview_mon].curws;
  ov_drag = 0;
  ov_drag_node = NULL;
  ov_moved = 0;
  m = &mons[overview_mon];
  /* refresh thumbnails of every monitor's visible workspace */
  if (composite_ok)
    for (mi = 0; mi < nmons; mi++)
      capture_tree(mons[mi].tree[mons[mi].curws]);
  MemSet(&wa, 0, sizeof(XSetWindowAttributes));
  wa.override_redirect = True;
  wa.background_pixel = barbg;
  wa.event_mask = ExposureMask | ButtonPressMask;
  overview_win = XCreateWindow(dpy, root, m->x, m->y, m->w, m->h, 0,
      CopyFromParent, InputOutput, NULL,
      CWOverrideRedirect | CWBackPixel | CWEventMask, &wa);
  overview_pix = XCreatePixmap(dpy, overview_win, m->w, m->h,
      XDefaultDepth(dpy, XDefaultScreen(dpy)));
  XMapRaised(dpy, overview_win);
  XGrabKeyboard(dpy, root, True, GrabModeAsync, GrabModeAsync, CurrentTime);
  /* actively grab the pointer so we receive motion + release for dragging */
  XGrabPointer(dpy, overview_win, True,
      ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
      GrabModeAsync, GrabModeAsync, None, normalcursor, CurrentTime);
  overview_active = 1;
  draw_overview();
}

U0 close_overview()
{
  if (!overview_active) return;
  overview_active = 0;
  ov_drag = 0;
  ov_drag_node = NULL;
  ov_moved = 0;
  XUngrabPointer(dpy, CurrentTime);
  XUngrabKeyboard(dpy, CurrentTime);
  if (overview_pix) {
    XFreePixmap(dpy, overview_pix);
    overview_pix = 0;
  }
  if (overview_win) {
    XDestroyWindow(dpy, overview_win);
    overview_win = 0;
  }
  /* restore the normal/command-mode keyboard grab if the WM held one */
  if (keyboard_grabbed)
    XGrabKeyboard(dpy, root, True, GrabModeAsync, GrabModeAsync, CurrentTime);
  if (mon_focused(curmon)) setfocus(curmon, mon_focused(curmon), 0);
}

U0 overview_choose(I64 ws)
{
  I64 mi = overview_mon;
  close_overview();
  switch_workspace_on(mi, ws);
}

U0 overview_key(U64 sym)
{
  switch (sym) {
  case XK_Escape:
  case XK_q:
  case XK_z:
    close_overview();
    return;
  case XK_Return:
  case XK_KP_Enter:
  case XK_space:
    overview_choose(overview_sel);
    return;
  case XK_Left:
  case XK_h:
    if (overview_sel % ov_cols()) {
      overview_sel--;
      draw_overview();
    }
    return;
  case XK_Right:
  case XK_l:
    if (overview_sel % ov_cols() != ov_cols() - 1 && overview_sel + 1 < numws) {
      overview_sel++;
      draw_overview();
    }
    return;
  case XK_Up:
  case XK_k:
    if (overview_sel >= ov_cols()) {
      overview_sel -= ov_cols();
      draw_overview();
    }
    return;
  case XK_Down:
  case XK_j:
    if (overview_sel + ov_cols() < numws) {
      overview_sel += ov_cols();
      draw_overview();
    }
    return;
  default:
    if (sym >= XK_1 && sym <= XK_9) overview_choose(sym - XK_1);
    return;
  }
}

/* which leaf, if any, sits under (px,py) — mirrors overview_draw_node layout */
Node *overview_node_at(Node *n, I64 x, I64 y, I64 w, I64 h, I64 px, I64 py)
{
  Node *r;
  I64 wa;
  I64 ha;
  if (!n || w < 2 || h < 2) return NULL;
  if (n->leaf) {
    if (px >= x && px < x + w && py >= y && py < y + h) return n;
    return NULL;
  }
  if (!has_tiled_leaf(n->a) && has_tiled_leaf(n->b))
    return overview_node_at(n->b, x, y, w, h, px, py);
  if (!has_tiled_leaf(n->b) && has_tiled_leaf(n->a))
    return overview_node_at(n->a, x, y, w, h, px, py);
  if (!has_tiled_leaf(n->a) && !has_tiled_leaf(n->b)) return NULL;
  if (n->horiz) {
    wa = w * n->ratio;
    r = overview_node_at(n->a, x, y, wa, h, px, py);
    if (r) return r;
    return overview_node_at(n->b, x + wa, y, w - wa, h, px, py);
  }
  ha = h * n->ratio;
  r = overview_node_at(n->a, x, y, w, ha, px, py);
  if (r) return r;
  return overview_node_at(n->b, x, y + ha, w, h - ha, px, py);
}

/* resolve a root-coordinate point to a workspace cell and (optionally) a leaf */
Node *overview_pick(I64 rx, I64 ry, I64 *out_ws)
{
  Mon *m = &mons[overview_mon];
  I64 lx = rx - m->x;
  I64 ly = ry - m->y;
  I64 ws;
  if (out_ws) *out_ws = -1;
  for (ws = 0; ws < numws; ws++) {
    I64 cx;
    I64 cy;
    I64 cw;
    I64 ch;
    overview_cell_rect(ws, &cx, &cy, &cw, &ch);
    if (lx >= cx && lx < cx + cw && ly >= cy && ly < cy + ch) {
      I64 ix = cx + 6;
      I64 iy = cy + 24;
      I64 iw = cw - 12;
      I64 ih = ch - 30;
      if (out_ws) *out_ws = ws;
      return overview_node_at(m->tree[ws], ix, iy, iw, ih, lx, ly);
    }
  }
  return NULL;
}

U0 overview_press(I64 rx, I64 ry)
{
  I64 ws;
  Node *leaf = overview_pick(rx, ry, &ws);
  ov_drag = (ws >= 0);
  ov_drag_node = leaf;
  ov_drag_ws = ws;
  ov_press_rx = rx;
  ov_press_ry = ry;
  ov_ptr_x = rx - mons[overview_mon].x;
  ov_ptr_y = ry - mons[overview_mon].y;
  ov_moved = 0;
  if (ws >= 0 && ws != overview_sel) {
    overview_sel = ws;
    draw_overview();
  }
}

U0 overview_motion(I64 rx, I64 ry)
{
  if (!ov_drag) return;
  ov_ptr_x = rx - mons[overview_mon].x;
  ov_ptr_y = ry - mons[overview_mon].y;
  if (!ov_moved) {
    I64 dx = rx - ov_press_rx;
    I64 dy = ry - ov_press_ry;
    if (dx * dx + dy * dy > 36) ov_moved = 1;   /* >6px = a drag */
  }
  if (ov_moved) draw_overview();
}

/* move a leaf to another workspace on the overview's monitor */
U0 overview_move_leaf(Node *leaf, I64 srcws, I64 dstws)
{
  I64 mi = overview_mon;
  detach_from_ws(mi, srcws, leaf);
  attach_to_ws(mi, dstws, leaf);
  if (dstws == mons[mi].curws) showtree(leaf);   /* now visible */
  else hidetree(leaf);                           /* now hidden  */
  retile();
}

U0 overview_release(I64 rx, I64 ry)
{
  I64 was_drag;
  Node *node;
  I64 srcws;
  I64 dstws;
  Node *target;
  if (!ov_drag) return;
  was_drag = ov_moved;
  node = ov_drag_node;
  srcws = ov_drag_ws;
  ov_drag = 0;
  ov_drag_node = NULL;
  ov_moved = 0;

  if (!was_drag) {
    /* a plain click enters the workspace under the pointer */
    I64 ws;
    overview_pick(rx, ry, &ws);
    if (ws >= 0) overview_choose(ws);
    return;
  }
  if (!node) {
    draw_overview();
    return;
  }

  target = overview_pick(rx, ry, &dstws);
  if (dstws < 0 || dstws == srcws) {
    if (target && target != node && dstws == srcws)
      swap_leaf_payload(node, target);   /* reorder within a workspace */
    retile();
    draw_overview();
    return;
  }
  overview_move_leaf(node, srcws, dstws);
  draw_overview();
}

U0 toggle_overview()
{
  if (overview_active) close_overview();
  else open_overview();
}

U0 screenshot()
{
  U8 *cmd =
      "mkdir -p \"$HOME/Pictures/Screenshots\" && "
      "if command -v maim >/dev/null 2>&1; then "
      "maim \"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d-%H%M%S).png\"; "
      "elif command -v scrot >/dev/null 2>&1; then "
      "scrot \"$HOME/Pictures/Screenshots/%Y-%m-%d-%H%M%S.png\"; "
      "elif command -v import >/dev/null 2>&1; then "
      "import -window root \"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d-%H%M%S).png\"; "
      "fi";
  spawn(cmd);
}

U0 close_window(U64 win)
{
  U8 *protraw = NULL;   /* hcc &typed-ptr-local bug: see get_window_title */
  U64 *protocols = NULL;
  I32 nprotocols = 0;
  I64 supports_delete = 0;
  I64 i;

  if (!win) return;

  if (XGetWMProtocols(dpy, win, &protraw, &nprotocols)) {
    protocols = protraw(U64 *);
    for (i = 0; i < nprotocols; i++) {
      if (protocols[i] == atom_wm_delete_window) {
        supports_delete = 1;
        break;
      }
    }
    if (protocols) XFree(protocols);
  }

  if (supports_delete) {
    XEvent ev;
    MemSet(&ev, 0, sizeof(XEvent));
    ev.xclient.type = ClientMessage;
    ev.xclient.window = win;
    ev.xclient.message_type = atom_wm_protocols;
    ev.xclient.format = 32;
    ev.xclient.l[0] = atom_wm_delete_window;
    ev.xclient.l[1] = CurrentTime;
    XSendEvent(dpy, win, False, NoEventMask, &ev);
    return;
  }

  XDestroyWindow(dpy, win);
}

I64 window_pid(U64 win)
{
  U64 actual_type;
  I32 actual_format;
  U64 nitems;
  U64 bytes_after;
  U8 *data = NULL;
  U64 *up;
  I64 pid = 0;
  if (XGetWindowProperty(dpy, win, atom_net_wm_pid, 0, 1, False,
        XA_CARDINAL, &actual_type, &actual_format, &nitems, &bytes_after,
        &data) == Success && data && nitems >= 1) {
    up = data(U64 *);
    pid = *up;
  }
  if (data) XFree(data);
  return pid;
}

/* a window we must never touch: WM internals, the bar and any dock/panel */
I64 window_is_protected(U64 win)
{
  I64 i;
  if (win == root || win == wmcheckwin) return 1;
  for (i = 0; i < nmons; i++)
    if (win == mons[i].barwin) return 1;
  if (dock_index(win) >= 0 || window_is_dock(win)) return 1;
  return 0;
}

/* :clear — hard "debloat" reset, like rebooting the laptop without
   leaving the session. Kills every client application across all
   monitors/workspaces, including ones that ignore WM_DELETE_WINDOW
   (Stremio & friends) or sit minimized in a tray, by signalling their
   process (_NET_WM_PID) and force-disconnecting the rest (XKillClient).
   The WM, the bar, docks/compositor and pure background services
   (audio, dbus, ...) own no app window here, so they survive. */
U0 clear_all_windows()
{
  I64 pids[512];
  I64 npids = 0;
  I64 self = getpid();
  U8 *treeraw = NULL;   /* hcc &typed-ptr-local bug: see get_window_title */
  U64 *tree;
  U64 d1;
  U64 d2;
  U32 num = 0;
  I64 i;
  I64 j;

  /* enumerate every top-level window, not just the tiling tree, so we
     also catch tray-minimized and otherwise untracked client windows */
  if (!XQueryTree(dpy, root, &d1, &d2, &treeraw, &num)) return;
  tree = treeraw(U64 *);

  for (i = 0; i < num; i++) {
    U64 win = tree[i];
    XWindowAttributes wa;
    I64 pid;
    if (window_is_protected(win)) continue;

    if (!XGetWindowAttributes(dpy, win, &wa)) continue;
    if (wa.override_redirect) continue;       /* menus, tooltips, etc. */
    if (wa.wclass != InputOutput) continue;

    pid = window_pid(win);
    if (pid > 0 && pid != self) {
      I64 seen = 0;
      for (j = 0; j < npids; j++)
        if (pids[j] == pid) {
          seen = 1;
          break;
        }
      if (!seen && npids < 512) {
        pids[npids] = pid;
        npids++;
      }
    } else {
      /* no usable PID: ask nicely, then sever the X connection */
      close_window(win);
      XKillClient(dpy, win);
    }
  }
  if (tree) XFree(tree);

  /* give processes a brief chance to exit cleanly, then make sure */
  for (i = 0; i < npids; i++) kill(pids[i], SIGTERM);
  if (npids) {
    TimeSpec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 300000000;  /* 300 ms */
    nanosleep(&ts, NULL);
    for (i = 0; i < npids; i++) kill(pids[i], SIGKILL);
  }
  XFlush(dpy);
}

U0 spawn(U8 *cmd)
{
  if (fork() == 0) {
    U8 *argv[4];
    setsid();
    close(XConnectionNumber(dpy));
    argv[0] = "sh";
    argv[1] = "-c";
    argv[2] = cmd;
    argv[3] = NULL;
    execvp("sh", argv);
    _exit(0);
  }
}

U0 start_command_prompt(U8 prefix)
{
  cmdline[0] = prefix;
  cmdline[1] = 0;
  cmdline_len = 1;
  enter_mode(MODE_COMMAND);
}

U0 shell_quote_single(U8 *dst, I64 dstsz, U8 *src)
{
  I64 pos = 0;
  U8 *repl = "'\\''";
  I64 i;
  if (!dstsz) return;
  dst[0] = 0;
  if (pos + 1 < dstsz) {
    dst[pos] = '\'';
    pos++;
  }
  while (*src && pos + 1 < dstsz) {
    if (*src == '\'') {
      for (i = 0; repl[i] && pos + 1 < dstsz; i++) {
        dst[pos] = repl[i];
        pos++;
      }
    } else {
      dst[pos] = *src;
      pos++;
    }
    src++;
  }
  if (pos + 1 < dstsz) {
    dst[pos] = '\'';
    pos++;
  }
  dst[pos] = 0;
}

U0 spawn_in_terminal(U8 *cmd)
{
  U8 quoted[CMDLINE_MAX * 4];
  U8 full[CMDLINE_MAX * 4 + 256];

  if (!cmd) {
    spawn(term);
    return;
  }
  if (!*cmd) {
    spawn(term);
    return;
  }

  shell_quote_single(quoted, CMDLINE_MAX * 4, cmd);
  StrCpy(full, term);
  stradd(full, " -e sh -lc ");
  stradd(full, quoted);
  spawn(full);
}

I64 parse_mods(U8 *keys)
{
  I64 mask = 0;
  if (strstr(keys, "mod")) mask |= Mod4Mask;
  if (strstr(keys, "shift")) mask |= ShiftMask;
  if (strstr(keys, "ctrl")) mask |= ControlMask;
  if (strstr(keys, "alt")) mask |= Mod1Mask;
  return mask;
}

U0 reset_config_defaults()
{
  gap = 8;
  bw = 2;
  barh = 24;
  barenabled = 1;
  externalbarh = 0;
  barpadx = 10;
  baritemgap = 6;
  bartextpad = 8;
  barwsminw = 20;
  cfocus = 0x5588ff;
  cnorm = 0x333333;
  barbg = 0x111111;
  barfg = 0xeeeeee;
  baraccentbg = 0x5588ff;
  baraccentfg = 0x111111;
  barmutedfg = 0xaaaaaa;
  copystr(term, 128, "st");
  copystr(barfontname, 128, "9x15");
  copystr(barleftcfg, 128, "command,title,workspaces");
  copystr(barcentercfg, 128, "command");
  copystr(barrightcfg, 128, "clock");
  screen_off_minutes = 0;
  warp_pointer = 0;
  barpos = BAR_TOP;
  nmodbinds = 0;
  nnormalbinds = 0;
  ncmdbinds = 0;
  nrules = 0;
  nautostart = 0;
  modbind_limit = MAXBINDS;
  normalbind_limit = MAXMODEBINDS;
  cmd_limit = MAXCMDS;
  autostart_limit = MAXAUTOSTART;
}

U0 updatenumlockmask()
{
  XModifierKeymap *modmap;
  I64 mod2;
  I64 k;
  numlockmask = 0;
  modmap = XGetModifierMapping(dpy);
  if (!modmap) return;
  for (mod2 = 0; mod2 < 8; mod2++) {
    for (k = 0; k < modmap->max_keypermod; k++) {
      U8 code = modmap->modifiermap[mod2 * modmap->max_keypermod + k];
      if (!code) continue;
      if (XkbKeycodeToKeysym(dpy, code, 0, 0) == XK_Num_Lock) {
        numlockmask = 1 << mod2;
      }
    }
  }
  XFreeModifiermap(modmap);
}

U0 upsert_modbind(U32 mod2, U8 code, U8 *action)
{
  I64 i;
  for (i = 0; i < nmodbinds; i++) {
    if (modbinds[i].mod == mod2 && modbinds[i].code == code) {
      copystr(modbinds[i].action, 128, action);
      return;
    }
  }
  if (nmodbinds >= modbind_limit) return;
  modbinds[nmodbinds].mod = mod2;
  modbinds[nmodbinds].code = code;
  copystr(modbinds[nmodbinds].action, 128, action);
  nmodbinds++;
}

U0 upsert_normalbind(U64 sym, U8 *action)
{
  I64 i;
  for (i = 0; i < nnormalbinds; i++) {
    if (normalbinds[i].sym == sym) {
      copystr(normalbinds[i].action, 128, action);
      return;
    }
  }
  if (nnormalbinds >= normalbind_limit) return;
  normalbinds[nnormalbinds].sym = sym;
  copystr(normalbinds[nnormalbinds].action, 128, action);
  nnormalbinds++;
}

U0 upsert_cmdbind(U8 *name, U8 *action)
{
  I64 i;
  for (i = 0; i < ncmdbinds; i++) {
    if (!StrCmp(cmdbinds[i].name, name)) {
      copystr(cmdbinds[i].action, 128, action);
      return;
    }
  }
  if (ncmdbinds >= cmd_limit) return;
  copystr(cmdbinds[ncmdbinds].name, 64, name);
  copystr(cmdbinds[ncmdbinds].action, 128, action);
  ncmdbinds++;
}

U0 add_autostart_cmd(U8 *cmd)
{
  if (!cmd) return;
  if (!*cmd) return;
  if (nautostart >= autostart_limit) return;
  copystr(autostart_cmds[nautostart], 256, cmd);
  nautostart++;
}

/* config line: bind_<mode> = <keyexpr> = <action>
   (the C original used sscanf; this splits on the two '=' by hand) */
I64 parse_bind_config(U8 *line)
{
  U8 mode_name[64];
  U8 keyexpr[128];
  U8 action[256];
  U8 *p;
  U8 *eq2;
  I64 i;

  if (StrNCmp(line, "bind_", 5)) return 0;
  p = line + 5;
  i = 0;
  while (*p && *p != ' ' && *p != '\t' && *p != '=' && i < 63) {
    mode_name[i] = *p;
    i++;
    p++;
  }
  mode_name[i] = 0;
  p = ltrim(p);
  if (*p != '=') return 0;
  p++;
  eq2 = strchr(p, '=');
  if (!eq2) return 0;
  i = 0;
  while (p < eq2 && i < 127) {
    keyexpr[i] = *p;
    i++;
    p++;
  }
  keyexpr[i] = 0;
  copystr(action, 128, ltrim(eq2 + 1));
  rtrim(mode_name);
  rtrim(keyexpr);
  rtrim(action);
  if (!strcasecmp(mode_name, "insert")) {
    U8 *kp = strrchr(keyexpr, '+');
    U64 sym;
    U8 code;

    if (kp) kp = kp + 1;
    else kp = keyexpr;
    kp = ltrim(kp);
    if (!*kp) return 1;
    sym = parse_keysym_name(kp);
    if (sym == NoSymbol) return 1;
    code = XKeysymToKeycode(dpy, sym);
    if (code) upsert_modbind(parse_mods(keyexpr), code, action);
    return 1;
  }
  if (!strcasecmp(mode_name, "normal")) {
    U64 sym = parse_keysym_name(keyexpr);
    if (sym != NoSymbol) upsert_normalbind(sym, action);
    return 1;
  }
  return 1;
}

/* config line: command = <name> = <action> */
I64 parse_command_config(U8 *line)
{
  U8 cmd_name[64];
  U8 cmd_action[256];
  U8 *p;
  U8 *eq2;
  I64 i;

  if (StrNCmp(line, "command", 7)) return 0;
  p = ltrim(line + 7);
  if (*p != '=') return 0;
  p++;
  p = ltrim(p);
  eq2 = strchr(p, '=');
  if (!eq2) return 0;
  i = 0;
  while (p < eq2 && i < 63) {
    cmd_name[i] = *p;
    i++;
    p++;
  }
  cmd_name[i] = 0;
  copystr(cmd_action, 128, ltrim(eq2 + 1));
  rtrim(cmd_name);
  rtrim(cmd_action);
  upsert_cmdbind(skip_command_prefix(cmd_name), cmd_action);
  return 1;
}

/* config line: rule = <kind>:<value> = <actions,...> */
I64 parse_rule_config(U8 *line)
{
  U8 rule_match[128];
  U8 rule_action[128];
  Rule *r;
  U8 *kind;
  U8 *value;
  U8 *save;
  U8 *act;
  U8 *p;
  U8 *eq2;
  I64 i;

  if (StrNCmp(line, "rule", 4)) return 0;
  p = ltrim(line + 4);
  if (*p != '=') return 0;
  p++;
  p = ltrim(p);
  eq2 = strchr(p, '=');
  if (!eq2) return 0;
  i = 0;
  while (p < eq2 && i < 127) {
    rule_match[i] = *p;
    i++;
    p++;
  }
  rule_match[i] = 0;
  copystr(rule_action, 128, ltrim(eq2 + 1));
  rtrim(rule_match);
  rtrim(rule_action);
  if (nrules >= MAXRULES) return 1;

  r = &rules[nrules];
  MemSet(r, 0, sizeof(Rule));
  r->workspace = -1;
  kind = ltrim(rule_match);
  value = strchr(kind, ':');
  if (!value) return 1;
  *value = 0;
  value++;
  kind = ltrim(kind);
  value = ltrim(value);
  rtrim(kind);
  if (!strcasecmp(kind, "class")) copystr(r->class_name, 64, value);
  else if (!strcasecmp(kind, "instance")) copystr(r->instance_name, 64, value);
  else if (!strcasecmp(kind, "title")) copystr(r->title, 128, value);
  else return 1;

  save = rule_action;
  act = tok_comma(&save);
  while (act) {
    act = ltrim(act);
    rtrim(act);
    if (!strcasecmp(act, "float")) {
      r->set_floating = 1;
      r->floating = 1;
    } else if (!strcasecmp(act, "tile")) {
      r->set_floating = 1;
      r->floating = 0;
    } else if (!strcasecmp(act, "follow_class")) {
      r->follow_class = 1;
    } else if (!strncasecmp(act, "workspace:", 10)) {
      I64 ws = Atoi(act + 10);
      if (ws >= 1 && ws <= numws) r->workspace = ws - 1;
    }
    act = tok_comma(&save);
  }
  nrules++;
  return 1;
}

I64 parse_key_value(U8 *line, U8 *k, I64 ksz, U8 *v, I64 vsz)
{
  U8 *eq = strchr(line, '=');
  if (!eq) return 0;
  *eq = 0;
  copystr(k, ksz, ltrim(line));
  rtrim(k);
  copystr(v, vsz, ltrim(eq + 1));
  rtrim(v);
  return 1;
}

I64 apply_limit_config(U8 *k, U8 *v)
{
  if (!StrCmp(k, "insert_bind_limit")) modbind_limit = clampi(Atoi(v), 1, MAXBINDS);
  else if (!StrCmp(k, "normal_bind_limit")) normalbind_limit = clampi(Atoi(v), 1, MAXMODEBINDS);
  else if (!StrCmp(k, "command_limit")) cmd_limit = clampi(Atoi(v), 1, MAXCMDS);
  else if (!StrCmp(k, "autostart_limit")) autostart_limit = clampi(Atoi(v), 1, MAXAUTOSTART);
  else return 0;
  return 1;
}

I64 apply_scalar_config(U8 *k, U8 *v)
{
  if (!StrCmp(k, "gap")) gap = Atoi(v);
  else if (!StrCmp(k, "workspaces")) numws = clampi(Atoi(v), 1, MAXWS);
  else if (!StrCmp(k, "border")) bw = Atoi(v);
  else if (!StrCmp(k, "bar_height")) barh = clampi(Atoi(v), 0, 256);
  else if (!StrCmp(k, "bar_enabled")) barenabled = parse_bool_value(v, barenabled);
  else if (!StrCmp(k, "auto_monitors")) auto_monitors = parse_bool_value(v, auto_monitors);
  else if (!StrCmp(k, "monitor_hook")) copystr(monitor_hook, 256, v);
  else if (!StrCmp(k, "compositor")) {
    if (!strcasecmp(v, "off")) compositor_mode = 2;
    else if (!strcasecmp(v, "on")) compositor_mode = 1;
    else compositor_mode = 0;   /* auto */
  }
  else if (!StrCmp(k, "external_bar_height")) {
    if (!strcasecmp(v, "auto")) externalbarh = -1;
    else externalbarh = clampi(Atoi(v), 0, 256);
  }
  else if (!StrCmp(k, "bar_padding_x")) barpadx = Atoi(v);
  else if (!StrCmp(k, "bar_item_gap")) baritemgap = Atoi(v);
  else if (!StrCmp(k, "bar_text_padding")) bartextpad = Atoi(v);
  else if (!StrCmp(k, "bar_workspace_min_width")) barwsminw = Atoi(v);
  else if (!StrCmp(k, "border_focus")) cfocus = hcol(v);
  else if (!StrCmp(k, "border_normal")) cnorm = hcol(v);
  else if (!StrCmp(k, "bar_bg")) barbg = hcol(v);
  else if (!StrCmp(k, "bar_fg")) barfg = hcol(v);
  else if (!StrCmp(k, "bar_accent_bg")) baraccentbg = hcol(v);
  else if (!StrCmp(k, "bar_accent_fg")) baraccentfg = hcol(v);
  else if (!StrCmp(k, "bar_muted_fg")) barmutedfg = hcol(v);
  else if (!StrCmp(k, "bar_font")) copystr(barfontname, 128, v);
  else if (!StrCmp(k, "bar_left")) copystr(barleftcfg, 128, v);
  else if (!StrCmp(k, "bar_center")) copystr(barcentercfg, 128, v);
  else if (!StrCmp(k, "bar_right")) copystr(barrightcfg, 128, v);
  else if (!StrCmp(k, "screen_off_minutes")) screen_off_minutes = clampi(Atoi(v), 0, 1440);
  else if (!StrCmp(k, "warp_pointer")) warp_pointer = parse_bool_value(v, warp_pointer);
  else if (!StrCmp(k, "bar_position")) {
    if (!strcasecmp(v, "bottom")) barpos = BAR_BOTTOM;
    else barpos = BAR_TOP;
  } else if (!StrCmp(k, "terminal")) {
    copystr(term, 128, v);
  } else {
    return 0;
  }
  return 1;
}

U0 grab_mod_binds()
{
  I64 i;
  for (i = 0; i < nmodbinds; i++) {
    XGrabKey(dpy, modbinds[i].code, modbinds[i].mod, root, True, GrabModeAsync, GrabModeAsync);
    XGrabKey(dpy, modbinds[i].code, modbinds[i].mod | LockMask, root, True, GrabModeAsync, GrabModeAsync);
    if (numlockmask) {
      XGrabKey(dpy, modbinds[i].code, modbinds[i].mod | numlockmask, root, True, GrabModeAsync, GrabModeAsync);
      XGrabKey(dpy, modbinds[i].code, modbinds[i].mod | numlockmask | LockMask,
          root, True, GrabModeAsync, GrabModeAsync);
    }
  }
}

U0 loadcfg_file(U8 *path)
{
  U8 *f = fopen(path, "r");
  U8 line[512];
  U8 k[64];
  U8 v[448];
  if (!f) return;
  while (fgets(line, 512, f)) {
    U8 *p = ltrim(line);
    if (!*p || *p == '#') continue;
    if (parse_bind_config(p) || parse_command_config(p) || parse_rule_config(p)) continue;
    if (!parse_key_value(p, k, 64, v, 448)) continue;
    if (!StrCmp(k, "autostart")) {
      add_autostart_cmd(v);
      continue;
    }
    if (apply_limit_config(k, v)) continue;
    apply_scalar_config(k, v);
  }
  fclose(f);
}

U0 loadcfg()
{
  U8 homecfg[PATH_MAX];
  U8 *home = getenv("HOME");
  homecfg[0] = 0;
  if (home) {
    if (home[0]) {
      StrCpy(homecfg, home);
      stradd(homecfg, "/.config/holywm/config.conf");
    }
  }

  reset_config_defaults();
  loadcfg_file("/etc/holywm/config.conf");
  loadcfg_file("./config.conf");
  if (homecfg[0]) loadcfg_file(homecfg);
}

U0 run_autostart()
{
  I64 i;
  for (i = 0; i < nautostart; i++) spawn(autostart_cmds[i]);
}

U0 scandocks()
{
  U32 num;
  I64 i;
  U64 d1;
  U64 d2;
  U8 *winsraw = NULL;   /* hcc &typed-ptr-local bug: see get_window_title */
  U64 *wins;
  XWindowAttributes wa;

  if (!XQueryTree(dpy, root, &d1, &d2, &winsraw, &num)) return;
  wins = winsraw(U64 *);
  for (i = 0; i < num; i++) {
    if (!XGetWindowAttributes(dpy, wins[i], &wa)) continue;
    if (wa.map_state != IsViewable) continue;
    if (window_is_dock(wins[i])) {
      add_dock_window(wins[i]);
      XSelectInput(dpy, wins[i], PropertyChangeMask);
    }
  }
  if (wins) XFree(wins);
}

U0 apply_screen_off_config()
{
  U8 cmd[128];

  if (screen_off_minutes <= 0) {
    spawn("xset s off -dpms >/dev/null 2>&1");
    return;
  }

  StrPrint(cmd, "xset s off +dpms dpms 0 0 %d >/dev/null 2>&1",
      screen_off_minutes * 60);
  spawn(cmd);
}

U0 restartwm()
{
  /* drop our grabs/state so the new instance starts clean, then re-exec.
     execvp resolves "holywm" via PATH to the currently-installed binary. */
  U8 *argv[2];
  XUngrabKey(dpy, AnyKey, AnyModifier, root);
  XSync(dpy, False);
  if (dpy) XCloseDisplay(dpy);
  argv[0] = "holywm";
  argv[1] = NULL;
  execvp("holywm", argv);
  /* if exec failed, there is nothing sane left to do */
  _exit(1);
}

U0 reloadwm()
{
  I64 mi;
  if (overview_active) close_overview();
  XUngrabKey(dpy, AnyKey, AnyModifier, root);
  loadcfg();
  /* if a reload lowered the workspace count, keep each monitor on a valid
     one (windows on now-hidden workspaces stay attached, reachable again
     if the count is raised back) */
  for (mi = 0; mi < nmons; mi++)
    if (mons[mi].curws >= numws) mons[mi].curws = numws - 1;
  update_num_desktops();
  apply_screen_off_config();
  updatenumlockmask();
  grab_mod_binds();
  ndockwins = 0;
  setupbars();
  scandocks();
  setupbars();
  setup_tray();
  retile();
  if (mon_focused(curmon)) setfocus(curmon, mon_focused(curmon), 0);
  else update_active_window();
}

U0 set_net_wm_state(U64 win, I64 fullscreen)
{
  if (fullscreen) {
    U64 atoms[1];
    U8 *ap = atoms;
    atoms[0] = atom_net_wm_state_fs;
    XChangeProperty(dpy, win, atom_net_wm_state, XA_ATOM, 32, PropModeReplace, ap, 1);
  } else {
    XDeleteProperty(dpy, win, atom_net_wm_state);
  }
}

U0 handle_client_fullscreen(U64 win, I64 action, U64 a1, U64 a2)
{
  I64 mi;
  Node *n;
  I64 wants = 0;
  if (a1 != atom_net_wm_state_fs && a2 != atom_net_wm_state_fs) return;
  mi = monforwin(win);
  n = findleaf(mon_tree(mi), win);
  if (!n) return;
  if (action == 1) wants = 1;
  else if (action == 0) wants = 0;
  else wants = !n->real_fullscreen;
  n->real_fullscreen = wants;
  if (wants) {
    n->fullscreen = 0;
    n->floating = 0;
    setfocus(mi, n, 0);
  }
  set_net_wm_state(win, wants);
  retile();
}

U0 sync_window_fullscreen(U64 win)
{
  I64 mi;
  I64 ws;
  Node *n = findleaf_any(win, &mi, &ws);
  I64 wants;
  if (!n) return;
  wants = window_has_atom(win, atom_net_wm_state, atom_net_wm_state_fs);
  if (n->real_fullscreen == wants) return;
  n->real_fullscreen = wants;
  if (wants) {
    n->fullscreen = 0;
    n->floating = 0;
    if (ws == mons[mi].curws) setfocus(mi, n, 0);
  }
  retile();
}

U0 enter_mode(I64 newmode)
{
  if (newmode == MODE_INSERT) {
    mode = MODE_INSERT;
    cmdline[0] = 0;
    cmdline_len = 0;
    if (keyboard_grabbed) {
      XUngrabKeyboard(dpy, CurrentTime);
      keyboard_grabbed = 0;
    }
    if (mon_focused(curmon)) setfocus(curmon, mon_focused(curmon), 0);
  } else {
    if (!keyboard_grabbed) {
      if (XGrabKeyboard(dpy, root, True, GrabModeAsync, GrabModeAsync, CurrentTime) == GrabSuccess) {
        keyboard_grabbed = 1;
      }
    }
    mode = newmode;
    if (newmode == MODE_NORMAL) {
      cmdline[0] = 0;
      cmdline_len = 0;
    } else if (!cmdline_len) {
      copystr(cmdline, CMDLINE_MAX, ":");
      cmdline_len = 1;
    }
  }
  drawbars();
}

I64 apply_wm_action(U8 *action)
{
  Mon *m = &mons[curmon];
  if (!StrNCmp(action, "spawn:", 6)) {
    spawn(action + 6);
    return 1;
  }
  if (!StrNCmp(action, "wm:mode:", 8)) {
    U8 *name = action + 8;
    if (!StrCmp(name, "insert")) enter_mode(MODE_INSERT);
    else if (!StrCmp(name, "normal")) enter_mode(MODE_NORMAL);
    else if (!StrCmp(name, "command")) {
      copystr(cmdline, CMDLINE_MAX, ":");
      cmdline_len = 1;
      enter_mode(MODE_COMMAND);
    }
    return 1;
  }
  if (!StrCmp(action, "wm:quit")) {
    running = 0;
    return 1;
  }
  if (!StrCmp(action, "wm:kill")) {
    if (mon_focused(curmon)) close_window(mon_focused(curmon)->win);
    return 1;
  }
  if (!StrCmp(action, "wm:clear")) {
    clear_all_windows();
    return 1;
  }
  if (!StrCmp(action, "wm:reload")) {
    reloadwm();
    return 1;
  }
  if (!StrCmp(action, "wm:restart")) {
    restartwm();
    return 1;
  }
  if (!StrCmp(action, "wm:focus_next")) {
    Node *n = nextleaf(curmon, mon_focused(curmon));
    if (n && n != mon_focused(curmon)) setfocus(curmon, n, 1);
    return 1;
  }
  if (!StrCmp(action, "wm:focus_prev")) {
    Node *n = prevleaf(curmon, mon_focused(curmon));
    if (n && n != mon_focused(curmon)) setfocus(curmon, n, 1);
    return 1;
  }
  if (!StrCmp(action, "wm:swap_next")) {
    Node *cur = mon_focused(curmon);
    Node *n = nextleaf(curmon, cur);
    if (cur && n && n != cur) {
      U64 focused_win = cur->win;
      swap_leaf_payload(cur, n);
      retile();
      setfocus(curmon, findleaf(mon_tree(curmon), focused_win), 1);
    }
    return 1;
  }
  if (!StrCmp(action, "wm:swap_prev")) {
    Node *cur = mon_focused(curmon);
    Node *n = prevleaf(curmon, cur);
    if (cur && n && n != cur) {
      U64 focused_win = cur->win;
      swap_leaf_payload(cur, n);
      retile();
      setfocus(curmon, findleaf(mon_tree(curmon), focused_win), 1);
    }
    return 1;
  }
  if (!StrCmp(action, "wm:swap_left")) return swap_in_direction("left");
  if (!StrCmp(action, "wm:swap_right")) return swap_in_direction("right");
  if (!StrCmp(action, "wm:swap_up")) return swap_in_direction("up");
  if (!StrCmp(action, "wm:swap_down")) return swap_in_direction("down");
  if (!StrCmp(action, "wm:focus_left")) {
    Node *n = find_directional_focus(curmon, mon_focused(curmon), "left");
    if (n) setfocus(curmon, n, 1);
    return 1;
  }
  if (!StrCmp(action, "wm:focus_right")) {
    Node *n = find_directional_focus(curmon, mon_focused(curmon), "right");
    if (n) setfocus(curmon, n, 1);
    return 1;
  }
  if (!StrCmp(action, "wm:focus_up")) {
    Node *n = find_directional_focus(curmon, mon_focused(curmon), "up");
    if (n) setfocus(curmon, n, 1);
    return 1;
  }
  if (!StrCmp(action, "wm:focus_down")) {
    Node *n = find_directional_focus(curmon, mon_focused(curmon), "down");
    if (n) setfocus(curmon, n, 1);
    return 1;
  }
  if (!StrCmp(action, "wm:overview")) {
    toggle_overview();
    return 1;
  }
  if (!StrNCmp(action, "wm:workspace:", 13)) {
    switch_workspace(Atoi(action + 13) - 1);
    return 1;
  }
  if (!StrCmp(action, "wm:workspace_prev")) {
    I64 mi = pointer_mon();
    switch_workspace((mons[mi].curws + numws - 1) % numws);
    return 1;
  }
  if (!StrCmp(action, "wm:workspace_next")) {
    I64 mi = pointer_mon();
    switch_workspace((mons[mi].curws + 1) % numws);
    return 1;
  }
  if (!StrNCmp(action, "wm:move_to_workspace:", 21)) {
    move_to_ws(Atoi(action + 21) - 1);
    return 1;
  }
  if (!StrNCmp(action, "wm:move_to_workspace_follow:", 28)) {
    move_to_ws_follow(Atoi(action + 28) - 1);
    return 1;
  }
  if (!StrCmp(action, "wm:move_to_workspace_prev")) {
    move_to_ws_follow((mons[curmon].curws + numws - 1) % numws);
    return 1;
  }
  if (!StrCmp(action, "wm:move_to_workspace_next")) {
    move_to_ws_follow((mons[curmon].curws + 1) % numws);
    return 1;
  }
  if (!StrCmp(action, "wm:toggle_float_centered")) {
    Node *f = mon_focused(curmon);
    if (!f) return 1;
    f->floating ^= 1;
    if (f->floating) {
      I64 fw = m->ww * 3 / 5;
      I64 fh = m->wh * 3 / 5;
      I64 fx = m->wx + (m->ww - fw) / 2;
      I64 fy = m->wy + (m->wh - fh) / 2;
      if (fw < 50) fw = 50;
      if (fh < 50) fh = 50;
      XMoveResizeWindow(dpy, f->win, fx, fy, fw - 2 * bw, fh - 2 * bw);
      XRaiseWindow(dpy, f->win);
    }
    retile();
    return 1;
  }
  if (!StrCmp(action, "wm:toggle_float")) {
    Node *f = mon_focused(curmon);
    if (!f) return 1;
    f->floating ^= 1;
    if (f->floating) {
      U64 dw;
      I32 wx;
      I32 wy;
      U32 ww2;
      U32 wh2;
      U32 bw_req;
      U32 depth;
      if (XGetGeometry(dpy, f->win, &dw, &wx, &wy, &ww2, &wh2, &bw_req, &depth)) {
        I64 fw = ww2;
        I64 fh = wh2;
        if (fw < 50) fw = m->ww / 2;
        if (fh < 50) fh = m->wh / 2;
        XMoveResizeWindow(dpy, f->win, wx, wy, fw, fh);
      } else {
        I64 fw = m->ww / 2;
        I64 fh = m->wh / 2;
        I64 fx = m->wx + (m->ww - fw) / 2;
        I64 fy = m->wy + (m->wh - fh) / 2;
        XMoveResizeWindow(dpy, f->win, fx, fy, fw - 2 * bw, fh - 2 * bw);
      }
      XRaiseWindow(dpy, f->win);
    }
    retile();
    return 1;
  }
  if (!StrCmp(action, "wm:toggle_fullscreen")) {
    if (!mon_focused(curmon)) return 1;
    mon_focused(curmon)->fullscreen ^= 1;
    if (mon_focused(curmon)->fullscreen) {
      mon_focused(curmon)->floating = 0;
      mon_focused(curmon)->real_fullscreen = 0;
    }
    retile();
    XRaiseWindow(dpy, mon_focused(curmon)->win);
    return 1;
  }
  if (!StrCmp(action, "wm:toggle_real_fullscreen")) {
    Node *foc = mon_focused(curmon);
    if (!foc) return 1;
    foc->real_fullscreen ^= 1;
    if (foc->real_fullscreen) {
      foc->fullscreen = 0;
      foc->floating = 0;
    }
    set_net_wm_state(foc->win, foc->real_fullscreen);
    retile();
    XRaiseWindow(dpy, foc->win);
    return 1;
  }
  if (!StrCmp(action, "wm:screenshot")) {
    screenshot();
    return 1;
  }
  if (!StrCmp(action, "wm:toggle_split")) {
    if (mon_focused(curmon) && mon_focused(curmon)->par) {
      mon_focused(curmon)->par->horiz ^= 1;
      retile();
    }
    return 1;
  }
  if (!StrNCmp(action, "wm:ratio:", 9)) {
    if (mon_focused(curmon) && mon_focused(curmon)->par) {
      F64 delta = strtod(action + 9, NULL);
      Node *par = mon_focused(curmon)->par;
      par->ratio += delta;
      if (par->ratio < 0.1) par->ratio = 0.1;
      if (par->ratio > 0.9) par->ratio = 0.9;
      retile();
    }
    return 1;
  }
  return 0;
}

I64 run_command_line()
{
  U8 *name;
  I64 i;
  if (cmdline_len < 2 || (cmdline[0] != ':' && cmdline[0] != '/')) {
    enter_mode(MODE_NORMAL);
    return 0;
  }

  if (cmdline[0] == '/') {
    U8 *cmd = cmdline + 1;
    if (*cmd) spawn(cmd);
    enter_mode(MODE_NORMAL);
    return 1;
  }

  name = cmdline + 1;
  if (!StrNCmp(name, "t ", 2)) {
    while (*name == 't' || *name == ' ') name++;
    spawn_in_terminal(name);
    enter_mode(MODE_NORMAL);
    return 1;
  }
  if (!StrCmp(name, "t")) {
    spawn_in_terminal("");
    enter_mode(MODE_NORMAL);
    return 1;
  }
  for (i = 0; i < ncmdbinds; i++) {
    if (!StrCmp(name, cmdbinds[i].name)) {
      I64 keep = apply_wm_action(cmdbinds[i].action);
      if (mode == MODE_COMMAND) enter_mode(MODE_NORMAL);
      return keep;
    }
  }
  if (!StrCmp(name, "w!")) {
    I64 keep = apply_wm_action("wm:reload");
    if (mode == MODE_COMMAND) enter_mode(MODE_NORMAL);
    return keep;
  }
  if (!StrCmp(name, "q!")) {
    I64 keep = apply_wm_action("wm:quit");
    if (mode == MODE_COMMAND) enter_mode(MODE_NORMAL);
    return keep;
  }
  enter_mode(MODE_NORMAL);
  return 0;
}

U0 handle_command_key(XKeyEvent *kev, U64 sym)
{
  U8 text[32];
  I64 len = XLookupString(kev, text, 32, NULL, NULL);
  I64 i;

  if (sym == XK_Return || sym == XK_KP_Enter) {
    run_command_line();
    return;
  }
  if (sym == XK_Escape) {
    enter_mode(MODE_NORMAL);
    return;
  }
  if (sym == XK_BackSpace) {
    if (cmdline_len > 1) {
      cmdline_len--;
      cmdline[cmdline_len] = 0;
    }
    drawbars();
    return;
  }
  if (len <= 0) return;
  for (i = 0; i < len; i++) {
    if (cmdline_len < CMDLINE_MAX - 1 && text[i] >= 32 && text[i] < 127) {
      cmdline[cmdline_len] = text[i];
      cmdline_len++;
      cmdline[cmdline_len] = 0;
    }
  }
  drawbars();
}

I64 handle_normal_key(XKeyEvent *kev, U64 sym)
{
  U8 text[32];
  I64 len = XLookupString(kev, text, 32, NULL, NULL);
  I64 i;

  if (len > 0 && text[0] == ':') {
    start_command_prompt(':');
    return 1;
  }
  if (len > 0 && text[0] == '/') {
    start_command_prompt('/');
    return 1;
  }
  if (sym == XK_Escape) {
    enter_mode(MODE_INSERT);
    return 1;
  }
  if (sym == XK_Left || sym == XK_KP_Left) return apply_wm_action("wm:focus_prev");
  if (sym == XK_Right || sym == XK_KP_Right) return apply_wm_action("wm:focus_next");
  if (sym == XK_Up || sym == XK_KP_Up) return apply_wm_action("wm:focus_up");
  if (sym == XK_Down || sym == XK_KP_Down) return apply_wm_action("wm:focus_down");
  for (i = 0; i < nnormalbinds; i++) {
    if (normalbinds[i].sym == sym) {
      return apply_wm_action(normalbinds[i].action);
    }
  }
  return 0;
}

U0 destroybars()
{
  I64 i;
  tray_release_icons();   /* icons are barwin children; hand them back first */
  for (i = 0; i < nmons; i++) {
    if (mons[i].barpix) {
      XFreePixmap(dpy, mons[i].barpix);
      mons[i].barpix = 0;
    }
    if (mons[i].barwin) {
      XDestroyWindow(dpy, mons[i].barwin);
      mons[i].barwin = 0;
    }
  }
}

U0 setupbars()
{
  XGCValues gcv;
  XClassHint hint;
  U64 dock_type[1];
  U8 *dtp = dock_type;
  I64 top_reserved = 0;
  I64 bottom_reserved = 0;
  I64 dt = 0;
  I64 db = 0;
  I64 i;

  dock_type[0] = atom_wtype_dock;

  /* internal bar */
  if (barenabled && barh > 0) {
    if (barpos == BAR_TOP) top_reserved = barh;
    else bottom_reserved = barh;
  } else if (externalbarh > 0) {
    if (barpos == BAR_TOP) top_reserved = externalbarh;
    else bottom_reserved = externalbarh;
  }

  /* external docks (polybar etc) — checked on both sides regardless of barpos */
  compute_dock_struts(&dt, &db);
  if (dt > top_reserved) top_reserved = dt;
  if (db > bottom_reserved) bottom_reserved = db;

  if (bargc) XFreeGC(dpy, bargc);
  if (barfont) {
    XFreeFont(dpy, barfont);
    barfont = NULL;
  }
  bargc = XCreateGC(dpy, root, 0, &gcv);
  if (barenabled) {
    barfont = XLoadQueryFont(dpy, barfontname);
    if (!barfont) barfont = XLoadQueryFont(dpy, "9x15");
    if (!barfont) barfont = XLoadQueryFont(dpy, "fixed");
    if (barfont) XSetFont(dpy, bargc, barfont->fid);
  }

  for (i = 0; i < nmons; i++) {
    Mon *m = &mons[i];
    if (m->barpix) {
      XFreePixmap(dpy, m->barpix);
      m->barpix = 0;
    }
    m->wx = m->x;
    m->ww = m->w;
    m->wy = m->y + top_reserved;
    m->wh = m->h - top_reserved - bottom_reserved;
    if (m->wh < 1) m->wh = 1;

    if (!barenabled || barh <= 0) {
      if (m->barwin) {
        if (i == traymon) tray_release_icons();
        XDestroyWindow(dpy, m->barwin);
        m->barwin = 0;
      }
      continue;
    }

    if (barpos == BAR_TOP) {
      if (!m->barwin) m->barwin = XCreateSimpleWindow(dpy, root, m->x, m->y, m->w, barh, 0, barbg, barbg);
      XMoveResizeWindow(dpy, m->barwin, m->x, m->y, m->w, barh);
    } else {
      if (!m->barwin) m->barwin = XCreateSimpleWindow(dpy, root, m->x, m->y + m->h - barh, m->w, barh, 0, barbg, barbg);
      XMoveResizeWindow(dpy, m->barwin, m->x, m->y + m->h - barh, m->w, barh);
    }
    XSetWindowBackground(dpy, m->barwin, barbg);
    XChangeProperty(dpy, m->barwin, atom_net_wm_wtype, XA_ATOM, 32,
        PropModeReplace, dtp, 1);
    XStoreName(dpy, m->barwin, "holywm-bar");
    hint.res_name = "holywm-bar";
    hint.res_class = "HolyWMBar";
    XSetClassHint(dpy, m->barwin, &hint);
    XDefineCursor(dpy, m->barwin, normalcursor);
    XSelectInput(dpy, m->barwin, ExposureMask);
    XMapRaised(dpy, m->barwin);
  }
  if (barenabled) drawbars();
}

U0 handle_event(XEvent *evp)
{
  XEvent ev;
  MemCpy(&ev, evp, sizeof(XEvent));

  if (randr_active && ev.type == randr_event_base + RRScreenChangeNotify) {
    I64 rrchanged;
    XRRUpdateConfiguration(&ev);
    rrchanged = autoconfigure_outputs();   /* enable plugged / disable unplugged */
    if (updategeom()) {
      setupbars();
      retile();
      if (mon_focused(curmon)) setfocus(curmon, mon_focused(curmon), 0);
      rrchanged = 1;
    }
    /* the framebuffer resize invalidated the root wallpaper -- re-apply it */
    if (rrchanged && monitor_hook[0]) spawn(monitor_hook);
    return;
  }
  switch (ev.type) {
  case Expose: {
    I64 i;
    if (ev.xexpose.count != 0) break;
    if (overview_active && ev.xexpose.window == overview_win) {
      draw_overview();
      break;
    }
    for (i = 0; i < nmons; i++) {
      if (ev.xexpose.window == mons[i].barwin) {
        drawbar(i);
        break;
      }
    }
    break;
  }

  case MapRequest: {
    U64 dw;
    I32 rx;
    I32 ry;
    I32 wx;
    I32 wy;
    U32 msk;
    Node *n;
    I64 existing_mi = 0;
    I64 existing_ws = 0;
    Node *existing;
    I64 mi;
    I64 targetws;
    I64 follow = 0;
    XSelectInput(dpy, ev.xmaprequest.window, EnterWindowMask | PropertyChangeMask);
    XMapWindow(dpy, ev.xmaprequest.window);
    if (window_is_dock(ev.xmaprequest.window)) {
      add_dock_window(ev.xmaprequest.window);
      setupbars();
      retile();
      sync_dock_stack();
      break;
    }
    existing = findleaf_any(ev.xmaprequest.window, &existing_mi, &existing_ws);
    if (existing) {
      retile();
      if (existing_ws == mons[existing_mi].curws) setfocus(existing_mi, existing, 1);
      break;
    }
    XQueryPointer(dpy, root, &dw, &dw, &rx, &ry, &wx, &wy, &msk);
    mi = monforpt(rx, ry);
    targetws = mons[mi].curws;
    n = mkleaf(ev.xmaprequest.window);
    apply_rules(n, &targetws, &follow);
    if (window_has_atom(ev.xmaprequest.window, atom_net_wm_state,
          atom_net_wm_state_fs)) {
      n->real_fullscreen = 1;
    }
    attach_to_ws(mi, targetws, n);
    if (targetws != mons[mi].curws) {
      if (follow) {
        switch_workspace_on(mi, targetws);
      } else {
        unmap_managed(n);
        retile();
      }
    } else {
      Node *fs;
      retile();
      fs = find_fullscreen_leaf(mon_tree(mi));
      if (fs) setfocus(mi, fs, 0);
      else setfocus(mi, n, 1);
    }
    break;
  }

  case MapNotify:
    if (ev.xmap.override_redirect && window_is_dock(ev.xmap.window)) {
      add_dock_window(ev.xmap.window);
      XSelectInput(dpy, ev.xmap.window, PropertyChangeMask);
      setupbars();
      retile();
      sync_dock_stack();
    }
    break;

  case DestroyNotify:
    tray_remove_icon(ev.xdestroywindow.window);
    remove_dock_window(ev.xdestroywindow.window);
    removewin(ev.xdestroywindow.window);
    retile();
    if (mon_focused(curmon)) setfocus(curmon, mon_focused(curmon), 0);
    break;

  case UnmapNotify: {
    I64 mi = 0;
    I64 ws = 0;
    Node *n;
    if (tray_index(ev.xunmap.window) >= 0) {
      tray_remove_icon(ev.xunmap.window);
      break;
    }
    n = findleaf_any(ev.xunmap.window, &mi, &ws);
    if (!n) remove_dock_window(ev.xunmap.window);
    if (n) {
      if (n->ignore_unmap > 0) {
        n->ignore_unmap--;
      } else {
        removewin(ev.xunmap.window);
        retile();
        if (mon_focused(curmon)) setfocus(curmon, mon_focused(curmon), 0);
      }
    } else if (ev.xunmap.send_event) {
      removewin(ev.xunmap.window);
      retile();
      if (mon_focused(curmon)) setfocus(curmon, mon_focused(curmon), 0);
    }
    break;
  }

  case ReparentNotify:
    /* another tray (or the app itself) pulled the icon out of our bar */
    if (tray_index(ev.xreparent.window) >= 0 &&
        (traymon >= nmons || ev.xreparent.parent != mons[traymon].barwin))
      tray_remove_icon(ev.xreparent.window);
    break;

  case ConfigureNotify:
    /* icons resizing themselves are pushed back into their slot */
    if (tray_index(ev.xconfigure.window) >= 0) tray_layout_icons();
    break;

  case SelectionClear:
    if (trayselwin && ev.xselectionclear.window == trayselwin &&
        ev.xselectionclear.selection == atom_net_system_tray) {
      tray_release_icons();
      drawbars();
    }
    break;

  case PropertyNotify:
    if ((ev.xproperty.atom == atom_net_wm_strut ||
        ev.xproperty.atom == atom_net_wm_strut_part) &&
        dock_index(ev.xproperty.window) >= 0) {
      setupbars();
      retile();
      break;
    }
    if (ev.xproperty.atom == atom_net_wm_wtype &&
        window_is_dock(ev.xproperty.window)) {
      I64 mi = 0;
      I64 ws = 0;
      Node *n = findleaf_any(ev.xproperty.window, &mi, &ws);
      add_dock_window(ev.xproperty.window);
      if (n) {
        detach_from_ws(mi, ws, n);
        Free(n);
      }
      setupbars();
      retile();
      break;
    }
    if (ev.xproperty.atom == atom_net_wm_state) {
      sync_window_fullscreen(ev.xproperty.window);
    }
    if (ev.xproperty.atom == atom_net_wm_name || ev.xproperty.atom == XA_WM_NAME) {
      Node *focused = mon_focused(curmon);
      if (focused && focused->win == ev.xproperty.window)
        refresh_cached_title();
    }
    break;

  case ClientMessage:
    if (ev.xclient.message_type == atom_tray_opcode) {
      if (ev.xclient.l[1] == SYSTEM_TRAY_REQUEST_DOCK)
        tray_dock_icon(ev.xclient.l[2]);
      break;
    }
    if (ev.xclient.message_type == atom_net_current_desktop) {
      switch_workspace(ev.xclient.l[0]);
      break;
    }
    if (ev.xclient.message_type == atom_net_active_window) {
      I64 mi = 0;
      I64 ws = 0;
      Node *n = findleaf_any(ev.xclient.window, &mi, &ws);
      if (n) {
        if (ws != mons[mi].curws) switch_workspace_on(mi, ws);
        setfocus(mi, n, 1);
      }
      break;
    }
    if (ev.xclient.message_type == atom_net_wm_state) {
      handle_client_fullscreen(ev.xclient.window, ev.xclient.l[0],
          ev.xclient.l[1], ev.xclient.l[2]);
      break;
    }
    break;

  case ConfigureRequest: {
    I64 mi = 0;
    I64 ws = 0;
    Node *n = findleaf_any(ev.xconfigurerequest.window, &mi, &ws);
    XWindowChanges wc;
    if (n && ws == mons[mi].curws && !n->floating && !n->fullscreen && !n->real_fullscreen) {
      retile();
      break;
    }
    wc.x = ev.xconfigurerequest.x;
    wc.y = ev.xconfigurerequest.y;
    wc.width = ev.xconfigurerequest.width;
    wc.height = ev.xconfigurerequest.height;
    if (n) wc.border_width = bw;
    else wc.border_width = ev.xconfigurerequest.border_width;
    wc.sibling = ev.xconfigurerequest.above;
    wc.stack_mode = ev.xconfigurerequest.detail;
    XConfigureWindow(dpy, ev.xconfigurerequest.window,
        ev.xconfigurerequest.value_mask, &wc);
    if (dock_index(ev.xconfigurerequest.window) >= 0) {
      setupbars();
      retile();
    }
    break;
  }

  case EnterNotify:
    if (mode != MODE_INSERT) break;
    if (ev.xcrossing.mode == NotifyNormal) {
      I64 mi = monforwin(ev.xcrossing.window);
      Node *n = findleaf(mon_tree(mi), ev.xcrossing.window);
      if (n && n != mon_focused(mi)) setfocus(mi, n, 0);
    }
    break;

  case ButtonPress: {
    U64 clicked;
    I64 mi;
    I64 i;
    Node *n = NULL;
    I64 is_btn1;
    U64 dw;
    U32 gw;
    U32 gh;
    U32 gb;
    U32 gd;
    if (overview_active) {
      if (ev.xbutton.button == Button1)
        overview_press(ev.xbutton.x_root, ev.xbutton.y_root);
      else
        close_overview();
      break;
    }
    if (ev.xbutton.button == Button4 || ev.xbutton.button == Button5) {
      U32 st = ev.xbutton.state &
          (ShiftMask | ControlMask | Mod1Mask | Mod4Mask | LockMask | numlockmask);
      I64 pmi;
      I64 next;
      I64 targetws;
      st &= ~(LockMask | numlockmask);
      /* wheel up = next workspace, wheel down = previous;
         acts on the monitor under the pointer */
      pmi = monforpt(ev.xbutton.x_root, ev.xbutton.y_root);
      next = (ev.xbutton.button == Button4);
      if (next) targetws = (mons[pmi].curws + 1) % numws;
      else targetws = (mons[pmi].curws + numws - 1) % numws;
      if (st == MOD)
        switch_workspace_on(pmi, targetws);
      else if (st == (MOD | ControlMask))
        move_to_ws_follow(targetws);
      break;
    }

    if (ev.xbutton.subwindow) clicked = ev.xbutton.subwindow;
    else clicked = ev.xbutton.window;
    if (clicked == root) break;

    mi = monforpt(ev.xbutton.x_root, ev.xbutton.y_root);
    for (i = 0; i < nmons && !n; i++) {
      n = findleaf(mon_tree(i), clicked);
      if (n) mi = i;
    }
    if (!n || (ev.xbutton.button != Button1 && ev.xbutton.button != Button3)) break;

    is_btn1 = (ev.xbutton.button == Button1);

    if (n != mon_focused(mi)) setfocus(mi, n, 1);
    else {
      XRaiseWindow(dpy, n->win);
      raise_floating(mon_tree(mi));
    }

    XGetGeometry(dpy, n->win, &dw, &drag_wx, &drag_wy, &gw, &gh, &gb, &gd);
    drag_ww = gw;
    drag_wh = gh;
    drag_ox = ev.xbutton.x_root;
    drag_oy = ev.xbutton.y_root;
    drag_node = n;
    drag_mon = mi;
    /* Super+Button1 on a tiled window reorders (swaps) it in the
       direction you drag instead of detaching it to floating */
    if (is_btn1 && !n->real_fullscreen && !n->floating)
      drag_mode = 3;
    else if (is_btn1)
      drag_mode = 1;   /* floating: move */
    else
      drag_mode = 2;   /* Button3: resize floating / split ratio */

    if (drag_mode == 2)
      XGrabPointer(dpy, root, False, PointerMotionMask | ButtonReleaseMask,
          GrabModeAsync, GrabModeAsync, None, resizecursor, CurrentTime);
    else
      XGrabPointer(dpy, root, False, PointerMotionMask | ButtonReleaseMask,
          GrabModeAsync, GrabModeAsync, None, movecursor, CurrentTime);
    break;
  }

  case ButtonRelease:
    if (overview_active) {
      if (ev.xbutton.button == Button1)
        overview_release(ev.xbutton.x_root, ev.xbutton.y_root);
      break;
    }
    if (drag_mode) {
      XUngrabPointer(dpy, CurrentTime);
      if (drag_node) {
        U64 dw;
        I32 rx;
        I32 ry;
        I32 wx2;
        I32 wy2;
        U32 msk;
        I64 newmon;
        XQueryPointer(dpy, root, &dw, &dw, &rx, &ry, &wx2, &wy2, &msk);
        newmon = monforpt(rx, ry);
        if (newmon != drag_mon) {
          I64 was_floating = drag_node->floating;
          detach(drag_mon, drag_node);
          attach(newmon, drag_node);
          drag_node->floating = was_floating;
          curmon = newmon;
          retile();
        }
      }
    }
    drag_mode = 0;
    drag_node = NULL;
    drag_ww = 0;
    drag_wh = 0;
    break;

  case MotionNotify: {
    XEvent newer;
    I64 dx;
    I64 dy;
    while (XCheckTypedEvent(dpy, MotionNotify, &newer)) MemCpy(&ev, &newer, sizeof(XEvent));
    if (overview_active) {
      overview_motion(ev.xmotion.x_root, ev.xmotion.y_root);
      break;
    }
    if (!drag_mode || !drag_node) break;
    dx = ev.xmotion.x_root - drag_ox;
    dy = ev.xmotion.y_root - drag_oy;
    if (drag_mode == 3) {
      /* swap with whatever tiled window we are hovering, then
         follow our window into its new slot so the drag keeps
         pushing it in the direction of travel */
      Node *t = tiled_leaf_at(drag_mon,
          ev.xmotion.x_root, ev.xmotion.y_root);
      if (t && t != drag_node && !t->floating) {
        swap_leaf_payload(drag_node, t);
        retile();
        drag_node = t;
        setfocus(drag_mon, drag_node, 0);
      }
    } else if (drag_mode == 1) {
      I64 nx = drag_wx + dx;
      I64 ny = drag_wy + dy;
      Mon *dm = &mons[drag_mon];
      I64 top_off = dm->wy - dm->y;
      I64 bot_off = dm->h - (dm->wy - dm->y) - dm->wh;
      if (nx < 0) nx = 0;
      if (ny < top_off) ny = top_off;
      if (nx + drag_ww + 2 * bw > sw) nx = sw - drag_ww - 2 * bw;
      if (ny + drag_wh + 2 * bw > sh - bot_off) ny = sh - bot_off - drag_wh - 2 * bw;
      XMoveWindow(dpy, drag_node->win, nx, ny);
    } else if (drag_node->floating) {
      I64 nw = drag_ww + dx;
      I64 nh = drag_wh + dy;
      if (nw < 50) nw = 50;
      if (nh < 50) nh = 50;
      if (drag_wx + nw + 2 * bw > sw) nw = sw - drag_wx - 2 * bw;
      if (drag_wy + nh + 2 * bw > sh) nh = sh - drag_wy - 2 * bw;
      XResizeWindow(dpy, drag_node->win, nw, nh);
    } else if (drag_node->par) {
      Node *p = drag_node->par;
      I64 sign;
      F64 delta;
      if (p->a == drag_node) sign = 1;
      else sign = -1;
      if (p->horiz) {
        if (p->w > 0) delta = dx * sign * 1.0 / p->w;
        else delta = 0.0;
      } else {
        if (p->h > 0) delta = dy * sign * 1.0 / p->h;
        else delta = 0.0;
      }
      p->ratio += delta;
      if (p->ratio < 0.1) p->ratio = 0.1;
      if (p->ratio > 0.9) p->ratio = 0.9;
      retile();
      drag_ox = ev.xmotion.x_root;
      drag_oy = ev.xmotion.y_root;
    }
    break;
  }

  case KeyPress: {
    U32 state = ev.xkey.state &
        (ShiftMask | ControlMask | Mod1Mask | Mod4Mask | LockMask | numlockmask);
    U64 sym;
    I64 handled = 0;
    I64 i;
    state &= ~(LockMask | numlockmask);
    sym = XLookupKeysym(&ev.xkey, 0);

    if (overview_active) {
      overview_key(sym);
      break;
    }

    if (state == (ControlMask | Mod4Mask) && (sym == XK_Left || sym == XK_KP_Left)) {
      apply_wm_action("wm:swap_left");
      break;
    }
    if (state == (ControlMask | Mod4Mask) && (sym == XK_Right || sym == XK_KP_Right)) {
      apply_wm_action("wm:swap_right");
      break;
    }
    if (state == (ControlMask | Mod4Mask) && (sym == XK_Up || sym == XK_KP_Up)) {
      apply_wm_action("wm:swap_up");
      break;
    }
    if (state == (ControlMask | Mod4Mask) && (sym == XK_Down || sym == XK_KP_Down)) {
      apply_wm_action("wm:swap_down");
      break;
    }
    if (state == 0 && (sym == XK_Print || sym == XK_Sys_Req)) {
      apply_wm_action("wm:screenshot");
      break;
    }
    if (state == MOD && (sym == XK_Left || sym == XK_KP_Left)) {
      apply_wm_action("wm:focus_prev");
      break;
    }
    if (state == MOD && (sym == XK_Right || sym == XK_KP_Right)) {
      apply_wm_action("wm:focus_next");
      break;
    }
    if (state == MOD && (sym == XK_Up || sym == XK_KP_Up)) {
      apply_wm_action("wm:focus_up");
      break;
    }
    if (state == MOD && (sym == XK_Down || sym == XK_KP_Down)) {
      apply_wm_action("wm:focus_down");
      break;
    }

    for (i = 0; i < nmodbinds; i++) {
      if (ev.xkey.keycode == modbinds[i].code && state == modbinds[i].mod) {
        handled = apply_wm_action(modbinds[i].action);
        break;
      }
    }
    if (handled) break;

    /* built-in fallback so Super+Z opens the overview even without a
       config bind; a user bind for this key takes priority above */
    if (state == MOD && (sym == XK_z || sym == XK_Z)) {
      apply_wm_action("wm:overview");
      break;
    }

    if (mode == MODE_COMMAND) {
      handle_command_key(&ev.xkey, sym);
      break;
    }
    if (mode == MODE_NORMAL) {
      handle_normal_key(&ev.xkey, sym);
    }
    break;
  }
  }
}

U0 Main()
{
  I32 scr;
  I32 rrerr;
  I64 i;
  I64 b;
  I64 l;
  I64 m2;
  I64 ws;
  U32 locks[4];
  I64 dragbtns[2];
  U32 scrollmods[2];
  I64 scrollbtns[2];

  init_globals();
  signal(SIGCHLD, SIG_IGN);
  dpy = XOpenDisplay(NULL);
  if (!dpy) Exit(1);
  XSetErrorHandler(&xerr);

  scr = XDefaultScreen(dpy);
  root = XRootWindow(dpy, scr);
  sw = XDisplayWidth(dpy, scr);
  sh = XDisplayHeight(dpy, scr);
  normalcursor = XCreateFontCursor(dpy, XC_left_ptr);
  movecursor = XCreateFontCursor(dpy, XC_fleur);
  resizecursor = XCreateFontCursor(dpy, XC_bottom_right_corner);
  XDefineCursor(dpy, root, normalcursor);
  loadcfg();                 /* settings first: compositor + auto_monitors gate the startup below */
  init_composite();
  initatoms();
  setup_wm_check();
  update_supported_atoms();
  update_num_desktops();
  update_current_desktop();
  update_active_window();

  /* RandR: listen for monitor hotplug / resolution changes */
  if (XRRQueryExtension(dpy, &randr_event_base, &rrerr)) {
    randr_active = 1;
    XRRSelectInput(dpy, root, RRScreenChangeNotifyMask);
  }

  autoconfigure_outputs();   /* light up any already-plugged monitors */
  nmons = querygeom(mons, MAXMONS);

  XSelectInput(dpy, root, SubstructureNotifyMask | SubstructureRedirectMask | KeyPressMask);

  update_num_desktops();   /* numws is now known from config */
  apply_screen_off_config();
  updatenumlockmask();
  grab_mod_binds();
  setupbars();
  scandocks();
  setupbars();
  setup_tray();   /* before autostart, so autostarted tray apps find it */
  run_autostart();

  /* grab with every lock combination: X matches modifier state exactly,
     so NumLock/CapsLock would otherwise swallow the drag */
  locks[0] = 0;
  locks[1] = LockMask;
  locks[2] = numlockmask;
  locks[3] = numlockmask | LockMask;
  dragbtns[0] = Button1;
  dragbtns[1] = Button3;
  for (b = 0; b < 2; b++)
    for (l = 0; l < 4; l++)
      XGrabButton(dpy, dragbtns[b], MOD | locks[l], root, False,
          ButtonPressMask | ButtonReleaseMask,
          GrabModeAsync, GrabModeAsync, None, None);

  /* scroll wheel: MOD = switch workspace, MOD+Ctrl = move focused window
     to prev/next workspace and follow it */
  scrollmods[0] = MOD;
  scrollmods[1] = MOD | ControlMask;
  scrollbtns[0] = Button4;
  scrollbtns[1] = Button5;
  for (b = 0; b < 2; b++)
    for (m2 = 0; m2 < 2; m2++)
      for (l = 0; l < 4; l++)
        XGrabButton(dpy, scrollbtns[b], scrollmods[m2] | locks[l], root,
            False, ButtonPressMask, GrabModeAsync, GrabModeAsync,
            None, None);

  while (running) {
    while (XPending(dpy)) {
      XEvent ev;
      XNextEvent(dpy, &ev);
      handle_event(&ev);
    }
    drawbars_on_tick();
    if (!running) break;
    if (!XPending(dpy)) wait_event_or_tick();
  }

  if (keyboard_grabbed) XUngrabKeyboard(dpy, CurrentTime);
  for (i = 0; i < nmons; i++) {
    for (ws = 0; ws < numws; ws++) {
      free_tree(mons[i].tree[ws]);
      mons[i].tree[ws] = NULL;
      mons[i].focused[ws] = NULL;
    }
  }
  destroybars();
  if (wmcheckwin) {
    XDestroyWindow(dpy, wmcheckwin);
    wmcheckwin = 0;
  }
  if (normalcursor) XFreeCursor(dpy, normalcursor);
  if (movecursor) XFreeCursor(dpy, movecursor);
  if (resizecursor) XFreeCursor(dpy, resizecursor);
  XCloseDisplay(dpy);
}

Main;
