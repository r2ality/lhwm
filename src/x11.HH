// LHWM: deliberately small Xlib ABI surface for holyc-lang.
// The event and attribute layouts follow the Xlib public ABI (64-bit targets).
#link <X11>

#define NULL 0
#define True 1
#define False 0
#define None 0
#define CurrentTime 0
#define AnyKey 0
#define AnyModifier 32768
#define GrabModeAsync 1
#define RevertToPointerRoot 1
#define PropModeReplace 0

#define ShiftMask 1
#define LockMask 2
#define ControlMask 4
#define Mod1Mask 8
#define Mod2Mask 16
#define Mod4Mask 64

#define KeyPress 2
#define ButtonPress 4
#define Expose 12
#define ButtonRelease 5
#define MotionNotify 6
#define DestroyNotify 17
#define UnmapNotify 18
#define MapRequest 20
#define ConfigureNotify 22
#define ConfigureRequest 23

#define ButtonPressMask 4
#define ButtonReleaseMask 8
#define PointerMotionMask 64
#define StructureNotifyMask 131072
#define SubstructureNotifyMask 524288
#define SubstructureRedirectMask 1048576
#define ExposureMask 32768
#define LineSolid 0
#define CapButt 1
#define JoinMiter 0
#define CWOverrideRedirect 512

#define Button1 1
#define Button3 3
#define IsViewable 2
#define BadAccess 10
#define SIGCHLD 17
#define SIG_IGN 1
#define XA_ATOM 4
#define XA_WINDOW 33
#define POLLIN 1

class PollFD
{
  I32 fd;
  I16 events;
  I16 revents;
};
class XKeyEvent
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
  I32 x_root;
  I32 y_root;
  U32 state;
  U32 keycode;
  I32 same_screen;
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
  U64 window;
  U64 root;
  U64 subwindow;
  U64 time;
  I32 x;
  I32 y;
  I32 x_root;
  I32 y_root;
  U32 state;
  U32 button;
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
  I32 x_root;
  I32 y_root;
  U32 state;
  U8 is_hint;
  U8 pad2a;
  U16 pad2b;
  I32 same_screen;
};
class XMapRequestEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 parent;
  U64 window;
};
class XUnmapEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 event;
  U64 window;
  I32 from_configure;
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
  U64 event;
  U64 window;
};
class XConfigureEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 event;
  U64 window;
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
  U64 parent;
  U64 window;
  I32 x;
  I32 y;
  I32 width;
  I32 height;
  I32 border_width;
  I32 pad2;
  U64 above;
  I32 detail;
  I32 pad3;
  U64 value_mask;
};
class XClientMessageEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;
  U64 message_type;
  I32 format;
  I32 pad2;
  I64 l[5];
};
class XPoint
{
  I16 x;
  I16 y;
};
class XExposeEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;
  I32 x;
  I32 y;
  I32 width;
  I32 height;
  I32 count;
  I32 pad2;
};

class XSetWindowAttributes
{
  U64 background_pixmap;
  U64 background_pixel;
  U64 border_pixmap;
  U64 border_pixel;
  I32 bit_gravity;
  I32 win_gravity;
  I32 backing_store;
  I32 pad0;
  U64 backing_planes;
  U64 backing_pixel;
  I32 save_under;
  I32 pad1;
  I64 event_mask;
  I64 do_not_propagate_mask;
  I32 override_redirect;
  I32 pad2;
  U64 colormap;
  U64 cursor;
};
class XPropertyEvent
{
  I32 type;
  U32 pad0;
  U64 serial;
  I32 send_event;
  I32 pad1;
  U8 *display;
  U64 window;
  U64 atom;
  U64 time;
  I32 state;
  I32 pad2;
};
union XEvent
{
  I32 type;
  XKeyEvent xkey;
  XButtonEvent xbutton;
  XMotionEvent xmotion;
  XMapRequestEvent xmaprequest;
  XUnmapEvent xunmap;
  XDestroyWindowEvent xdestroywindow;
  XConfigureEvent xconfigure;
  XConfigureRequestEvent xconfigurerequest;
  XClientMessageEvent xclient;
  XExposeEvent xexpose;
  XPropertyEvent xproperty;
  I64 pad[24];
};
class XErrorEvent
{
  I32 type;
  U32 pad0;
  U8 *display;
  U64 resourceid;
  U64 serial;
  U8 error_code;
  U8 request_code;
  U8 minor_code;
  U8 pad1;
  U32 pad2;
};
class XWindowAttributes
{
  I32 x;
  I32 y;
  I32 width;
  I32 height;
  I32 border_width;
  I32 depth;
  U8 *visual;
  U64 root;
  I32 wclass;
  I32 bit_gravity;
  I32 win_gravity;
  I32 backing_store;
  U64 backing_planes;
  U64 backing_pixel;
  I32 save_under;
  I32 pad0;
  U64 colormap;
  I32 map_installed;
  I32 map_state;
  I64 all_event_masks;
  I64 your_event_mask;
  I64 do_not_propagate_mask;
  I32 override_redirect;
  I32 pad1;
  U8 *screen;
};
class XWindowChanges
{
  I32 x;
  I32 y;
  I32 width;
  I32 height;
  I32 border_width;
  I32 pad0;
  U64 sibling;
  I32 stack_mode;
  I32 pad1;
};
class XColor
{
  U64 pixel;
  U16 red;
  U16 green;
  U16 blue;
  U8 flags;
  U8 pad;
};

extern "c" U8 *XOpenDisplay(U8 *name);
extern "c" I32 XCloseDisplay(U8 *dpy);
extern "c" U8 *XSetErrorHandler(U8 *handler);
extern "c" I32 XDefaultScreen(U8 *dpy);
extern "c" U64 XRootWindow(U8 *dpy, I32 screen);
extern "c" I32 XDisplayWidth(U8 *dpy, I32 screen);
extern "c" I32 XDisplayHeight(U8 *dpy, I32 screen);
extern "c" U64 XDefaultColormap(U8 *dpy, I32 screen);
extern "c" I32 XAllocNamedColor(U8 *dpy, U64 cmap, U8 *name, XColor *screen_def, XColor *exact_def);
extern "c" I32 XFreeColors(U8 *dpy, U64 cmap, U64 *pixels, I32 count, U32 planes);
extern "c" I32 XSync(U8 *dpy, I32 discard);
extern "c" I32 XFlush(U8 *dpy);
extern "c" I32 XNextEvent(U8 *dpy, XEvent *event);
extern "c" I32 XPending(U8 *dpy);
extern "c" I32 XConnectionNumber(U8 *dpy);
extern "c" I32 poll(PollFD *fds, U64 count, I32 timeout);
extern "c" I64 time(I64 *timer);
extern "c" U8 *localtime(I64 *timer);
extern "c" U64 strftime(U8 *dest, U64 maxsize, U8 *format, U8 *timeptr);
extern "c" I32 XSelectInput(U8 *dpy, U64 win, I64 mask);
extern "c" I32 XMapWindow(U8 *dpy, U64 win);
extern "c" I32 XMapRaised(U8 *dpy, U64 win);
extern "c" I32 XUnmapWindow(U8 *dpy, U64 win);
extern "c" I32 XDestroyWindow(U8 *dpy, U64 win);
extern "c" I32 XChangeWindowAttributes(U8 *dpy, U64 win, U64 mask, XSetWindowAttributes *attrs);
extern "c" I32 XSetWindowBackground(U8 *dpy, U64 win, U64 pixel);
extern "c" I32 XClearWindow(U8 *dpy, U64 win);
extern "c" U64 XCreateGC(U8 *dpy, U64 drawable, U64 mask, U8 *values);
extern "c" I32 XFreeGC(U8 *dpy, U64 gc);
extern "c" U64 XLoadFont(U8 *dpy, U8 *name);
extern "c" I32 XSetFont(U8 *dpy, U64 gc, U64 font);
extern "c" I32 XUnloadFont(U8 *dpy, U64 font);
extern "c" U8 **XListFonts(U8 *dpy, U8 *pattern, I32 maxnames, I32 *actual_count);
extern "c" I32 XFreeFontNames(U8 **names);
extern "c" I32 XSetForeground(U8 *dpy, U64 gc, U64 pixel);
extern "c" I32 XFillRectangle(U8 *dpy, U64 drawable, U64 gc, I32 x, I32 y, U32 width, U32 height);
extern "c" I32 XFillPolygon(U8 *dpy, U64 drawable, U64 gc, XPoint *points, I32 count, I32 shape, I32 mode);
extern "c" I32 XDrawString(U8 *dpy, U64 drawable, U64 gc, I32 x, I32 y, U8 *string, I32 length);
extern "c" I32 XDrawRectangle(U8 *dpy, U64 drawable, U64 gc, I32 x, I32 y, U32 width, U32 height);
extern "c" I32 XSetLineAttributes(U8 *dpy, U64 gc, U32 line_width, I32 line_style, I32 cap_style, I32 join_style);
extern "c" U64 XCreateSimpleWindow(U8 *dpy, U64 parent, I32 x, I32 y, U32 w, U32 h, U32 border_width, U64 border, U64 background);
extern "c" I32 XDeleteProperty(U8 *dpy, U64 win, U64 property);
extern "c" I32 XKillClient(U8 *dpy, U64 resource);
extern "c" I32 XMoveResizeWindow(U8 *dpy, U64 win, I32 x, I32 y, U32 w, U32 h);
extern "c" I32 XRaiseWindow(U8 *dpy, U64 win);
extern "c" I32 XSetWindowBorderWidth(U8 *dpy, U64 win, U32 width);
extern "c" I32 XSetWindowBorder(U8 *dpy, U64 win, U64 pixel);
extern "c" I32 XSetInputFocus(U8 *dpy, U64 win, I32 revert_to, U64 time);
extern "c" I32 XGetWindowAttributes(U8 *dpy, U64 win, XWindowAttributes *attrs);
extern "c" I32 XQueryTree(U8 *dpy, U64 win, U64 *root_ret, U64 *parent_ret, U8 **children_ret, U32 *n_ret);
extern "c" U64 XInternAtom(U8 *dpy, U8 *name, I32 only_if_exists);
extern "c" I32 XChangeProperty(U8 *dpy, U64 win, U64 property, U64 type, I32 format, I32 mode, U8 *data, I32 nelements);
extern "c" I32 XSendEvent(U8 *dpy, U64 win, I32 propagate, I64 mask, XEvent *event);
extern "c" I32 XGetWMProtocols(U8 *dpy, U64 win, U8 **protocols, I32 *count);
extern "c" I32 XFree(U8 *data);
extern "c" I32 XConfigureWindow(U8 *dpy, U64 win, U32 mask, XWindowChanges *changes);
extern "c" I32 XGrabKey(U8 *dpy, I32 keycode, U32 modifiers, U64 win, I32 owner_events, I32 pointer_mode, I32 keyboard_mode);
extern "c" I32 XUngrabKey(U8 *dpy, I32 keycode, U32 modifiers, U64 win);
extern "c" I32 XGrabButton(U8 *dpy, U32 button, U32 modifiers, U64 win, I32 owner_events, U32 event_mask, I32 pointer_mode, I32 keyboard_mode, U64 confine_to, U64 cursor);
extern "c" I32 XGrabPointer(U8 *dpy, U64 win, I32 owner_events, U32 event_mask, I32 pointer_mode, I32 keyboard_mode, U64 confine_to, U64 cursor, U64 time);
extern "c" I32 XUngrabPointer(U8 *dpy, U64 time);
extern "c" U64 XKeysymToKeycode(U8 *dpy, U64 keysym);
extern "c" U64 XStringToKeysym(U8 *name);
extern "c" U64 XLookupKeysym(XKeyEvent *event, I32 index);

extern "c" I32 strcasecmp(U8 *a, U8 *b);
extern "c" I32 strncasecmp(U8 *a, U8 *b, U64 n);
extern "c" U8 *strchr(U8 *s, I32 c);
extern "c" U8 *fopen(U8 *path, U8 *mode);
extern "c" U8 *fgets(U8 *buf, I32 size, U8 *file);
extern "c" I32 fclose(U8 *file);
extern "c" U8 *getenv(U8 *name);
extern "c" I64 fork();
extern "c" U8 *signal(I32 signum, U8 *handler);
extern "c" I64 setsid();
extern "c" I32 execvp(U8 *file, U8 **argv);
extern "c" U0 _exit(I32 status);
