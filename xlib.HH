// xlib.HH — hand-written HolyC bindings for the slice of Xlib, Xinerama,
// Xrandr, Xcomposite, Xrender and libc that holywm uses. Layouts and values
// are generated from the C headers (scripts/gen-abi.c) and must match the
// x86_64 SysV ABI exactly; every class here mirrors the C struct byte for
// byte, including implicit padding, which HolyC does not insert differently
// (verified: hcc packs identically to C on this target).

#define NULL 0

// ---- X ids and scalar typedef stand-ins (all XIDs are unsigned long) ----
// Window/Atom/Pixmap/Cursor/Colormap/KeySym/Time/Picture/RRCrtc/... => U64
// KeyCode => U8, GC/Display*/Visual* => opaque pointers (U8*)

// ---- constants (values from abi-truth.txt) ----
#define ShiftMask   1
#define LockMask    2
#define ControlMask 4
#define Mod1Mask    8
#define Mod4Mask    64

#define Button1 1
#define Button3 3
#define Button4 4
#define Button5 5

#define KeyPress         2
#define ButtonPress      4
#define ButtonRelease    5
#define MotionNotify     6
#define EnterNotify      7
#define Expose           12
#define DestroyNotify    17
#define UnmapNotify      18
#define MapNotify        19
#define MapRequest       20
#define ReparentNotify   21
#define ConfigureNotify  22
#define ConfigureRequest 23
#define PropertyNotify   28
#define SelectionClear   29
#define ClientMessage    33

#define NoEventMask              0
#define KeyPressMask             1
#define ButtonPressMask          4
#define ButtonReleaseMask        8
#define EnterWindowMask          16
#define PointerMotionMask        64
#define ExposureMask             32768
#define StructureNotifyMask      131072
#define SubstructureNotifyMask   524288
#define SubstructureRedirectMask 1048576
#define PropertyChangeMask       4194304

#define GrabModeAsync       1
#define GrabSuccess         0
#define RevertToPointerRoot 1
#define CurrentTime         0
#define None                0
#define AnyKey              0
#define AnyModifier         32768
#define Success             0
#define PropModeReplace     0
#define True                1
#define False               0

#define XA_ATOM     4
#define XA_CARDINAL 6
#define XA_WINDOW   33
#define XA_WM_NAME  39

#define IsUnmapped 0
#define IsViewable 2

#define InputOutput    1
#define CopyFromParent 0

#define CWBackPixel        2
#define CWOverrideRedirect 512
#define CWEventMask        2048

#define NotifyNormal 0

#define XC_left_ptr            68
#define XC_fleur               52
#define XC_bottom_right_corner 14

#define NoSymbol        0
#define XK_space        32
#define XK_1            49
#define XK_9            57
#define XK_Z            90
#define XK_h            104
#define XK_j            106
#define XK_k            107
#define XK_l            108
#define XK_q            113
#define XK_z            122
#define XK_BackSpace    65288
#define XK_Tab          65289
#define XK_Return       65293
#define XK_Sys_Req      65301
#define XK_Escape       65307
#define XK_Left         65361
#define XK_Up           65362
#define XK_Right        65363
#define XK_Down         65364
#define XK_Page_Up      65365
#define XK_Page_Down    65366
#define XK_Print        65377
#define XK_Num_Lock     65407
#define XK_KP_Enter     65421
#define XK_KP_Left      65430
#define XK_KP_Up        65431
#define XK_KP_Right     65432
#define XK_KP_Down      65433

#define XF86XK_MonBrightnessUp   269025026
#define XF86XK_MonBrightnessDown 269025027
#define XF86XK_AudioLowerVolume  269025041
#define XF86XK_AudioMute         269025042
#define XF86XK_AudioRaiseVolume  269025043
#define XF86XK_AudioPlay         269025044
#define XF86XK_AudioStop         269025045
#define XF86XK_AudioPrev         269025046
#define XF86XK_AudioNext         269025047
#define XF86XK_AudioPause        269025073

#define RRScreenChangeNotifyMask 1
#define RRScreenChangeNotify     0
#define RR_Connected             0
#define RR_Rotate_0              1
#define RRSetConfigSuccess       0

#define CompositeRedirectAutomatic 0
#define PictOpSrc                  1

#define SIGCHLD 17
#define SIGTERM 15
#define SIGKILL 9
#define SIG_IGN 1
#define CLOCK_REALTIME 0

// ---- event structs (offsets verified against abi-truth.txt) ----

class XAnyEvent
{
  I32 type;      // 0
  U32 pad0;
  U64 serial;    // 8
  I32 send_event;// 16
  I32 pad1;
  U8 *display;   // 24
  U64 window;    // 32
};

class XKeyEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;      // 32
  U64 root;        // 40
  U64 subwindow;   // 48
  U64 time;        // 56
  I32 x;           // 64
  I32 y;
  I32 x_root;      // 72
  I32 y_root;
  U32 state;       // 80
  U32 keycode;     // 84
  I32 same_screen; // 88
  I32 pad2;
};

class XButtonEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;      // 32
  U64 root;
  U64 subwindow;   // 48
  U64 time;
  I32 x;
  I32 y;
  I32 x_root;      // 72
  I32 y_root;
  U32 state;       // 80
  U32 button;      // 84
  I32 same_screen;
  I32 pad2;
};

class XMotionEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;
  U64 root;
  U64 subwindow;
  U64 time;
  I32 x;
  I32 y;
  I32 x_root;      // 72
  I32 y_root;      // 76
  U32 state;
  U8 is_hint;
  U8 pad2a;
  U16 pad2b;
  I32 same_screen;
};

class XCrossingEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;      // 32
  U64 root;
  U64 subwindow;
  U64 time;
  I32 x;
  I32 y;
  I32 x_root;
  I32 y_root;
  I32 mode;        // 80
  I32 detail;
  I32 same_screen;
  I32 focus;
  U32 state;
  U32 pad2;
};

class XExposeEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;      // 32
  I32 x;
  I32 y;
  I32 width;
  I32 height;
  I32 count;       // 56
  I32 pad2;
};

class XMapRequestEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 parent;      // 32
  U64 window;      // 40
};

class XMapEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 event;       // 32
  U64 window;      // 40
  I32 override_redirect; // 48
  I32 pad2;
};

class XUnmapEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;  // 16
  I32 pad1;
  U8 *display;
  U64 event;       // 32
  U64 window;      // 40
  I32 from_configure; // 48
  I32 pad2;
};

class XDestroyWindowEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 event;       // 32
  U64 window;      // 40
};

class XReparentEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 event;       // 32
  U64 window;      // 40
  U64 parent;      // 48
  I32 x;
  I32 y;
  I32 override_redirect;
  I32 pad2;
};

class XConfigureEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 event;       // 32
  U64 window;      // 40
  I32 x;
  I32 y;
  I32 width;
  I32 height;
  I32 border_width;
  I32 pad2;
  U64 above;
  I32 override_redirect;
  I32 pad3;
};

class XConfigureRequestEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 parent;      // 32
  U64 window;      // 40
  I32 x;           // 48
  I32 y;           // 52
  I32 width;       // 56
  I32 height;      // 60
  I32 border_width;// 64
  I32 pad2;
  U64 above;       // 72
  I32 detail;      // 80
  I32 pad3;
  U64 value_mask;  // 88
};

class XPropertyEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;      // 32
  U64 atom;        // 40
  U64 time;
  I32 state;
  I32 pad2;
};

class XClientMessageEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;       // 32
  U64 message_type; // 40
  I32 format;       // 48
  I32 pad2;
  I64 l[5];         // data union, long form @ 56
};

class XSelectionClearEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;      // 32
  U64 selection;   // 40
  U64 time;
};

class XErrorEvent
{
  I32 type;
  U32 pad0;
  U8 *display;     // 8
  U64 resourceid;  // 16
  U64 serial;      // 24
  U8 error_code;   // 32
  U8 request_code;
  U8 minor_code;
  U8 pad1;
  U32 pad2;
};

union XEvent
{
  I32 type;
  XAnyEvent xany;
  XKeyEvent xkey;
  XButtonEvent xbutton;
  XMotionEvent xmotion;
  XCrossingEvent xcrossing;
  XExposeEvent xexpose;
  XMapRequestEvent xmaprequest;
  XMapEvent xmap;
  XUnmapEvent xunmap;
  XDestroyWindowEvent xdestroywindow;
  XReparentEvent xreparent;
  XConfigureEvent xconfigure;
  XConfigureRequestEvent xconfigurerequest;
  XPropertyEvent xproperty;
  XClientMessageEvent xclient;
  XSelectionClearEvent xselectionclear;
  I64 pad[24];
};

// ---- non-event structs ----

class XWindowAttributes
{
  I32 x;                 // 0
  I32 y;
  I32 width;             // 8
  I32 height;
  I32 border_width;      // 16
  I32 depth;             // 20
  U8 *visual;            // 24
  U64 root;              // 32
  I32 wclass;            // 40 ("class" is a HolyC keyword)
  I32 bit_gravity;
  I32 win_gravity;       // 48
  I32 backing_store;
  U64 backing_planes;    // 56
  U64 backing_pixel;     // 64
  I32 save_under;        // 72
  I32 pad0;
  U64 colormap;          // 80
  I32 map_installed;     // 88
  I32 map_state;         // 92
  I64 all_event_masks;   // 96
  I64 your_event_mask;   // 104
  I64 do_not_propagate_mask; // 112
  I32 override_redirect; // 120
  I32 pad1;
  U8 *screen;            // 128
};                       // size 136

class XSetWindowAttributes
{
  U64 background_pixmap;    // 0
  U64 background_pixel;     // 8
  U64 border_pixmap;        // 16
  U64 border_pixel;         // 24
  I32 bit_gravity;          // 32
  I32 win_gravity;
  I32 backing_store;        // 40
  I32 pad0;
  U64 backing_planes;       // 48
  U64 backing_pixel;        // 56
  I32 save_under;           // 64
  I32 pad1;
  I64 event_mask;           // 72
  I64 do_not_propagate_mask;// 80
  I32 override_redirect;    // 88
  I32 pad2;
  U64 colormap;             // 96
  U64 cursor;               // 104
};                          // size 112

class XWindowChanges
{
  I32 x;            // 0
  I32 y;
  I32 width;        // 8
  I32 height;
  I32 border_width; // 16
  I32 pad0;
  U64 sibling;      // 24
  I32 stack_mode;   // 32
  I32 pad1;
};                  // size 40

class XClassHint
{
  U8 *res_name;
  U8 *res_class;
};

class XTextProperty
{
  U8 *value;    // 0
  U64 encoding; // 8
  I32 format;   // 16
  I32 pad0;
  U64 nitems;   // 24
};              // size 32

class XModifierKeymap
{
  I32 max_keypermod; // 0
  I32 pad0;
  U8 *modifiermap;   // 8
};

class XFontStruct
{ // only ->fid is touched; the rest stays behind the pointer
  U8 *ext_data; // 0
  U64 fid;      // 8
};

class XGCValues
{ // passed with valuemask 0 only; sized to the real struct (128 bytes)
  I64 pad[16];
};

class XineramaScreenInfo
{
  I32 screen_number; // 0
  I16 x_org;         // 4
  I16 y_org;         // 6
  I16 width;         // 8
  I16 height;        // 10
};                   // size 12

class XRRModeInfo
{
  U64 id;      // 0
  U32 width;   // 8
  U32 height;  // 12
  U8 rest[64]; // dotClock..modeFlags, unused
};             // size 80

class XRRScreenResources
{
  U64 timestamp;       // 0
  U64 configTimestamp; // 8
  I32 ncrtc;           // 16
  I32 pad0;
  U64 *crtcs;          // 24
  I32 noutput;         // 32
  I32 pad1;
  U64 *outputs;        // 40
  I32 nmode;           // 48
  I32 pad2;
  XRRModeInfo *modes;  // 56 (sizeof(XRRModeInfo)==80, typed indexing works)
};                     // size 64

class XRRCrtcInfo
{
  U64 timestamp; // 0
  I32 x;         // 8
  I32 y;         // 12
  U32 width;     // 16
  U32 height;    // 20
  U64 mode;      // 24
  U16 rotation;  // 32
  U16 pad0;
  I32 noutput;   // 36
  U64 *outputs;  // 40
  U16 rotations; // 48
  U16 pad1;
  I32 npossible; // 52
  U64 *possible; // 56
};               // size 64

class XRROutputInfo
{
  U64 timestamp;     // 0
  U64 crtc;          // 8
  U8 *name;          // 16
  I32 nameLen;       // 24
  I32 pad0;
  U64 mm_width;      // 32
  U64 mm_height;     // 40
  U16 connection;    // 48
  U16 subpixel_order;// 50
  I32 ncrtc;         // 52
  U64 *crtcs;        // 56
  I32 nclone;        // 64
  I32 pad1;
  U64 *clones;       // 72
  I32 nmode;         // 80
  I32 npreferred;    // 84
  U64 *modes;        // 88
};                   // size 96

class XTransform
{
  I32 m[9]; // 3x3 XFixed row-major
};          // size 36

class TimeSpec
{
  I64 tv_sec;
  I64 tv_nsec;
};

class TimeVal
{
  I64 tv_sec;
  I64 tv_usec;
};

class Tm
{ // glibc struct tm prefix; trailing fields unused but sized in
  I32 tm_sec;   // 0
  I32 tm_min;   // 4
  I32 tm_hour;  // 8
  I32 tm_mday;
  I32 tm_mon;
  I32 tm_year;
  I32 tm_wday;
  I32 tm_yday;
  I32 tm_isdst;
  I32 pad0;
  I64 tm_gmtoff;
  U8 *tm_zone;
};

class FdSet
{
  I64 bits[16]; // 1024 bits, 128 bytes
};

// ---- Xlib ----
extern "c" U8 *XOpenDisplay(U8 *name);
extern "c" I32 XCloseDisplay(U8 *dpy);
extern "c" U8 *XSetErrorHandler(U8 *handler);
extern "c" I32 XDefaultScreen(U8 *dpy);
extern "c" U64 XRootWindow(U8 *dpy, I32 scr);
extern "c" I32 XDisplayWidth(U8 *dpy, I32 scr);
extern "c" I32 XDisplayHeight(U8 *dpy, I32 scr);
extern "c" U8 *XDefaultVisual(U8 *dpy, I32 scr);
extern "c" I32 XDefaultDepth(U8 *dpy, I32 scr);
extern "c" I32 XConnectionNumber(U8 *dpy);
extern "c" I32 XFlush(U8 *dpy);
extern "c" I32 XSync(U8 *dpy, I32 discard);
extern "c" I32 XPending(U8 *dpy);
extern "c" I32 XNextEvent(U8 *dpy, XEvent *ev);
extern "c" I32 XCheckTypedEvent(U8 *dpy, I32 type, XEvent *ev);
extern "c" I32 XSendEvent(U8 *dpy, U64 win, I32 propagate, I64 mask, XEvent *ev);
extern "c" I32 XSelectInput(U8 *dpy, U64 win, I64 mask);
extern "c" I32 XMapWindow(U8 *dpy, U64 win);
extern "c" I32 XMapRaised(U8 *dpy, U64 win);
extern "c" I32 XUnmapWindow(U8 *dpy, U64 win);
extern "c" I32 XDestroyWindow(U8 *dpy, U64 win);
extern "c" I32 XKillClient(U8 *dpy, U64 res);
extern "c" I32 XMoveWindow(U8 *dpy, U64 win, I32 x, I32 y);
extern "c" I32 XResizeWindow(U8 *dpy, U64 win, U32 w, U32 h);
extern "c" I32 XMoveResizeWindow(U8 *dpy, U64 win, I32 x, I32 y, U32 w, U32 h);
extern "c" I32 XRaiseWindow(U8 *dpy, U64 win);
extern "c" I32 XLowerWindow(U8 *dpy, U64 win);
extern "c" I32 XReparentWindow(U8 *dpy, U64 win, U64 parent, I32 x, I32 y);
extern "c" I32 XConfigureWindow(U8 *dpy, U64 win, U32 value_mask, XWindowChanges *wc);
extern "c" U64 XCreateSimpleWindow(U8 *dpy, U64 parent, I32 x, I32 y, U32 w, U32 h,
                                   U32 border_w, U64 border, U64 background);
extern "c" U64 XCreateWindow(U8 *dpy, U64 parent, I32 x, I32 y, U32 w, U32 h,
                             U32 border_w, I32 depth, U32 wclass, U8 *visual,
                             U64 valuemask, XSetWindowAttributes *attrs);
extern "c" I32 XGetWindowAttributes(U8 *dpy, U64 win, XWindowAttributes *wa);
extern "c" I32 XGetGeometry(U8 *dpy, U64 d, U64 *root, I32 *x, I32 *y,
                            U32 *w, U32 *h, U32 *border_w, U32 *depth);
extern "c" I32 XSetWindowBorderWidth(U8 *dpy, U64 win, U32 w);
extern "c" I32 XSetWindowBorder(U8 *dpy, U64 win, U64 pixel);
extern "c" I32 XSetWindowBackground(U8 *dpy, U64 win, U64 pixel);
extern "c" I32 XSetInputFocus(U8 *dpy, U64 focus, I32 revert_to, U64 time);
extern "c" I32 XQueryPointer(U8 *dpy, U64 win, U64 *root_ret, U64 *child_ret,
                             I32 *rx, I32 *ry, I32 *wx, I32 *wy, U32 *mask);
extern "c" I32 XWarpPointer(U8 *dpy, U64 src, U64 dst, I32 sx, I32 sy,
                            U32 sw, U32 sh, I32 dx, I32 dy);
extern "c" I32 XQueryTree(U8 *dpy, U64 win, U64 *root_ret, U64 *parent_ret,
                          U8 **children_ret, U32 *n_ret);
extern "c" U64 XInternAtom(U8 *dpy, U8 *name, I32 only_if_exists);
extern "c" I32 XChangeProperty(U8 *dpy, U64 win, U64 prop, U64 type, I32 format,
                               I32 pmode, U8 *data, I32 nelements);
extern "c" I32 XDeleteProperty(U8 *dpy, U64 win, U64 prop);
extern "c" I32 XGetWindowProperty(U8 *dpy, U64 win, U64 prop, I64 off, I64 len,
                                  I32 delete, U64 req_type, U64 *actual_type,
                                  I32 *actual_format, U64 *nitems, U64 *bytes_after,
                                  U8 **data);
extern "c" I32 XGetTextProperty(U8 *dpy, U64 win, XTextProperty *prop, U64 atom);
extern "c" I32 XGetWMName(U8 *dpy, U64 win, XTextProperty *prop);
extern "c" I32 XmbTextPropertyToTextList(U8 *dpy, XTextProperty *prop,
                                         U8 **list_ret, I32 *count_ret);
extern "c" U0 XFreeStringList(U8 **list);
extern "c" I32 XGetClassHint(U8 *dpy, U64 win, XClassHint *hint);
extern "c" I32 XSetClassHint(U8 *dpy, U64 win, XClassHint *hint);
extern "c" I32 XStoreName(U8 *dpy, U64 win, U8 *name);
extern "c" I32 XGetTransientForHint(U8 *dpy, U64 win, U64 *prop_win);
extern "c" I32 XGetWMProtocols(U8 *dpy, U64 win, U8 **protocols, I32 *count);
extern "c" I32 XFree(U8 *data);
extern "c" U64 XGetSelectionOwner(U8 *dpy, U64 selection);
extern "c" I32 XSetSelectionOwner(U8 *dpy, U64 selection, U64 owner, U64 time);
extern "c" U64 XCreatePixmap(U8 *dpy, U64 d, U32 w, U32 h, U32 depth);
extern "c" I32 XFreePixmap(U8 *dpy, U64 pixmap);
extern "c" I32 XCopyArea(U8 *dpy, U64 src, U64 dst, U8 *gc, I32 sx, I32 sy,
                         U32 w, U32 h, I32 dx, I32 dy);
extern "c" U8 *XCreateGC(U8 *dpy, U64 d, U64 valuemask, XGCValues *values);
extern "c" I32 XFreeGC(U8 *dpy, U8 *gc);
extern "c" I32 XSetForeground(U8 *dpy, U8 *gc, U64 pixel);
extern "c" I32 XSetFont(U8 *dpy, U8 *gc, U64 font);
extern "c" I32 XFillRectangle(U8 *dpy, U64 d, U8 *gc, I32 x, I32 y, U32 w, U32 h);
extern "c" I32 XDrawRectangle(U8 *dpy, U64 d, U8 *gc, I32 x, I32 y, U32 w, U32 h);
extern "c" I32 XDrawString(U8 *dpy, U64 d, U8 *gc, I32 x, I32 y, U8 *s, I32 len);
extern "c" XFontStruct *XLoadQueryFont(U8 *dpy, U8 *name);
extern "c" I32 XFreeFont(U8 *dpy, XFontStruct *font);
extern "c" I32 XTextWidth(XFontStruct *font, U8 *s, I32 count);
extern "c" U64 XCreateFontCursor(U8 *dpy, U32 shape);
extern "c" I32 XFreeCursor(U8 *dpy, U64 cursor);
extern "c" I32 XDefineCursor(U8 *dpy, U64 win, U64 cursor);
extern "c" I32 XGrabKey(U8 *dpy, I32 keycode, U32 mods, U64 grab_win,
                        I32 owner_events, I32 pmode, I32 kmode);
extern "c" I32 XUngrabKey(U8 *dpy, I32 keycode, U32 mods, U64 grab_win);
extern "c" I32 XGrabKeyboard(U8 *dpy, U64 grab_win, I32 owner_events,
                             I32 pmode, I32 kmode, U64 time);
extern "c" I32 XUngrabKeyboard(U8 *dpy, U64 time);
extern "c" I32 XGrabButton(U8 *dpy, U32 button, U32 mods, U64 grab_win,
                           I32 owner_events, U32 event_mask, I32 pmode, I32 kmode,
                           U64 confine_to, U64 cursor);
extern "c" I32 XGrabPointer(U8 *dpy, U64 grab_win, I32 owner_events, U32 event_mask,
                            I32 pmode, I32 kmode, U64 confine_to, U64 cursor, U64 time);
extern "c" I32 XUngrabPointer(U8 *dpy, U64 time);
extern "c" U64 XKeysymToKeycode(U8 *dpy, U64 keysym);
extern "c" U64 XStringToKeysym(U8 *name);
extern "c" U64 XLookupKeysym(XKeyEvent *kev, I32 index);
extern "c" I32 XLookupString(XKeyEvent *kev, U8 *buf, I32 bufsz, U64 *keysym, U8 *status);
extern "c" XModifierKeymap *XGetModifierMapping(U8 *dpy);
extern "c" I32 XFreeModifiermap(XModifierKeymap *modmap);
extern "c" U64 XkbKeycodeToKeysym(U8 *dpy, U8 kc, I32 group, I32 level);

// ---- Xinerama ----
extern "c" I32 XineramaIsActive(U8 *dpy);
extern "c" XineramaScreenInfo *XineramaQueryScreens(U8 *dpy, I32 *number);

// ---- Xrandr ----
extern "c" I32 XRRQueryExtension(U8 *dpy, I32 *event_base, I32 *error_base);
extern "c" I32 XRRSelectInput(U8 *dpy, U64 win, I32 mask);
extern "c" I32 XRRUpdateConfiguration(XEvent *ev);
extern "c" XRRScreenResources *XRRGetScreenResources(U8 *dpy, U64 win);
extern "c" U0 XRRFreeScreenResources(XRRScreenResources *res);
extern "c" XRRCrtcInfo *XRRGetCrtcInfo(U8 *dpy, XRRScreenResources *res, U64 crtc);
extern "c" U0 XRRFreeCrtcInfo(XRRCrtcInfo *ci);
extern "c" XRROutputInfo *XRRGetOutputInfo(U8 *dpy, XRRScreenResources *res, U64 output);
extern "c" U0 XRRFreeOutputInfo(XRROutputInfo *oi);
extern "c" I32 XRRSetCrtcConfig(U8 *dpy, XRRScreenResources *res, U64 crtc, U64 time,
                                I32 x, I32 y, U64 rmode, U16 rotation,
                                U64 *outputs, I32 noutputs);
extern "c" U0 XRRSetScreenSize(U8 *dpy, U64 win, I32 w, I32 h, I32 mmw, I32 mmh);

// ---- Xcomposite ----
extern "c" I32 XCompositeQueryExtension(U8 *dpy, I32 *event_base, I32 *error_base);
extern "c" I32 XCompositeQueryVersion(U8 *dpy, I32 *major, I32 *minor);
extern "c" U0 XCompositeRedirectSubwindows(U8 *dpy, U64 win, I32 update);
extern "c" U64 XCompositeNameWindowPixmap(U8 *dpy, U64 win);

// ---- Xrender ----
extern "c" I32 XRenderQueryExtension(U8 *dpy, I32 *event_base, I32 *error_base);
extern "c" U8 *XRenderFindVisualFormat(U8 *dpy, U8 *visual);
extern "c" U64 XRenderCreatePicture(U8 *dpy, U64 drawable, U8 *format,
                                    U64 valuemask, U8 *attrs);
extern "c" U0 XRenderFreePicture(U8 *dpy, U64 picture);
extern "c" U0 XRenderSetPictureTransform(U8 *dpy, U64 picture, XTransform *xf);
extern "c" I32 XRenderSetPictureFilter(U8 *dpy, U64 picture, U8 *filter,
                                       I32 *params, I32 nparams);
extern "c" U0 XRenderComposite(U8 *dpy, I32 op, U64 src, U64 mask, U64 dst,
                               I32 sx, I32 sy, I32 mx, I32 my,
                               I32 dx, I32 dy, U32 w, U32 h);

// ---- libc ----
extern "c" I32 strcasecmp(U8 *a, U8 *b);
extern "c" I32 strncasecmp(U8 *a, U8 *b, U64 n);
extern "c" U8 *strstr(U8 *hay, U8 *needle);
extern "c" U8 *strchr(U8 *s, I32 c);
extern "c" U8 *strrchr(U8 *s, I32 c);
extern "c" F64 strtod(U8 *s, U8 **end);
extern "c" U8 *memmove(U8 *dst, U8 *src, U64 n);
extern "c" U8 *fopen(U8 *path, U8 *fmode);
extern "c" U8 *fgets(U8 *buf, I32 size, U8 *f);
extern "c" I32 fclose(U8 *f);
extern "c" U8 *getenv(U8 *name);
extern "c" I64 fork();
extern "c" I64 setsid();
extern "c" I32 execvp(U8 *file, U8 **argv);
extern "c" U0 _exit(I32 status);
extern "c" I32 close(I32 fd);
extern "c" I32 kill(I64 pid, I32 sig);
extern "c" I64 getpid();
extern "c" I32 nanosleep(TimeSpec *req, TimeSpec *rem);
extern "c" I32 select(I32 nfds, FdSet *readfds, FdSet *writefds, FdSet *exceptfds,
                      TimeVal *timeout);
extern "c" I32 clock_gettime(I32 clk, TimeSpec *tp);
extern "c" I64 time(I64 *t);
extern "c" Tm *localtime_r(I64 *t, Tm *result);
extern "c" U8 *signal(I32 sig, U8 *handler);
